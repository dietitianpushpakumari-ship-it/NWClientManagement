import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:nutricare_client_management/admin/lab_test_config_model.dart';
import 'package:nutricare_client_management/admin/lab_test_config_service.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
// Reused Dialog Import
import 'package:nutricare_client_management/master_diet_planner/generic_multi_select_dialogg.dart';
// Service Import
import 'package:nutricare_client_management/admin/services/master_data_service.dart';


// NEW/UPDATED CONSTANTS
const String entityLabTestCategory = MasterEntity.entity_labTestCategory;
const String labCategoryMasterEntity = entityLabTestCategory;


// 🎯 FIXED PROVIDER: Using masterDataServiceProvider.fetchMasterList
final labTestCategoriesProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final service = ref.watch(masterDataServiceProvider);
  final collectionPath = MasterCollectionMapper.getPath(entityLabTestCategory);
  return await service.fetchMasterList(collectionPath);
});


class LabTestConfigEntryPage extends ConsumerStatefulWidget {
  final LabTestConfigModel? initialTest;
  final String initialCategory;

  const LabTestConfigEntryPage({super.key, this.initialTest, this.initialCategory = ''});

  @override
  ConsumerState<LabTestConfigEntryPage> createState() => _LabTestConfigEntryPageState();
}

class _LabTestConfigEntryPageState extends ConsumerState<LabTestConfigEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _minRangeCtrl = TextEditingController();
  final _maxRangeCtrl = TextEditingController();

  String? _selectedCategory;
  bool _isReverseLogic = false;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialTest != null;

    if (_isEditing) {
      final test = widget.initialTest!;
      _idCtrl.text = test.id;
      _displayNameCtrl.text = test.displayName;
      _unitCtrl.text = test.unit;
      _minRangeCtrl.text = test.minRange?.toString() ?? '';
      _maxRangeCtrl.text = test.maxRange?.toString() ?? '';
      _selectedCategory = test.category;
      _isReverseLogic = test.isReverseLogic;
    } else {
      _selectedCategory = widget.initialCategory.isNotEmpty ? widget.initialCategory : null;
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _displayNameCtrl.dispose();
    _unitCtrl.dispose();
    _minRangeCtrl.dispose();
    _maxRangeCtrl.dispose();
    super.dispose();
  }

  // --- Category Selection Logic (REFACTORED) ---

  void _openCategorySelectorDialog(Map<String, String> categoriesData) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Fix corners
      builder: (ctx) => GenericMultiSelectDialog(
        title: "Select Lab Category",
        items: categoriesData.keys.toList(),
        itemNameIdMap: categoriesData,
        initialSelectedItems: _selectedCategory != null ? [_selectedCategory!] : [],
        singleSelect: true,

        // 🎯 SMART ADD CONFIG
        collectionPath: MasterCollectionMapper.getPath(labCategoryMasterEntity),
        providerToRefresh: labTestCategoriesProvider,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCategory = result.isNotEmpty ? result.first : null;
      });
    }
  }

  // --- Save Logic (Retained) ---

  Future<void> _saveTest() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields and select a category.")));
      return;
    }
    setState(() => _isLoading = true);

    final isNewTest = widget.initialTest == null;

    final newTest = LabTestConfigModel(
      id: isNewTest ? _idCtrl.text.trim() : widget.initialTest!.id,
      displayName: _displayNameCtrl.text.trim(),
      unit: _unitCtrl.text.trim(),
      category: _selectedCategory!,
      minRange: double.tryParse(_minRangeCtrl.text.trim()),
      maxRange: double.tryParse(_maxRangeCtrl.text.trim()),
      isReverseLogic: _isReverseLogic,
    );

    try {
      final service = ref.read(labTestConfigServiceProvider);
      if (isNewTest) {
        await service.addLabTest(newTest);
      } else {
        await service.updateLabTest(newTest);
      }
      ref.invalidate(allLabTestsStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lab Test '${newTest.displayName}' saved!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI Helpers ---

  Widget _buildCustomHeader(BuildContext context) {
    final title = _isEditing ? "Edit Lab Test" : "New Lab Test";

    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.blue), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)))),
          IconButton(
              onPressed: _isLoading ? null : _saveTest,
              icon: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.blue)) : const Icon(Icons.save, color: Colors.blue, size: 28)
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false, bool isRequired = true, bool enabled = true, String? hint}) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (v) {
        if (isRequired && (v == null || v.isEmpty)) return "$label is required.";
        if (isNumber && v!.isNotEmpty && double.tryParse(v) == null) return "Must be a number.";
        return null;
      },
    );
  }

  // MODIFIED: Widget for the category selector button (takes Map data)
  Widget _buildCategorySelector(Map<String, String> categories) {
    return GestureDetector(
      onTap: () => _openCategorySelectorDialog(categories),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: _selectedCategory == null ? Colors.red : Colors.grey.shade300,
              width: 1.5
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedCategory ?? 'Select Category (Required)',
              style: TextStyle(
                fontSize: 16,
                color: _selectedCategory == null ? Colors.red : Colors.black,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(labTestCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildCustomHeader(context),
            Expanded(
              child: categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text("Error loading categories: $err")),
                data: (categories) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Test Identification ---
                          Card(
                            elevation: 2, margin: const EdgeInsets.only(bottom: 20),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildField(_displayNameCtrl, "Test Display Name", Icons.label, enabled: !_isEditing),
                                  const SizedBox(height: 12),
                                  _buildField(_idCtrl, "Test Key (Unique ID)", Icons.vpn_key, isRequired: true, enabled: !_isEditing, hint: 'e.g., hemoglobin'),
                                ],
                              ),
                            ),
                          ),

                          // --- Configuration ---
                          Card(
                            elevation: 2, margin: const EdgeInsets.only(bottom: 20),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // Category Selector Button
                                  _buildCategorySelector(categories),

                                  const SizedBox(height: 12),
                                  _buildField(_unitCtrl, "Unit (e.g., mg/dL)", Icons.straighten, isRequired: true),
                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      Expanded(child: _buildField(_minRangeCtrl, "Min Range (Optional)", Icons.arrow_downward, isNumber: true, isRequired: false)),
                                      const SizedBox(width: 10),
                                      Expanded(child: _buildField(_maxRangeCtrl, "Max Range (Optional)", Icons.arrow_upward, isNumber: true, isRequired: false)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  SwitchListTile(
                                    title: const Text("Reverse Logic (Higher is better)"),
                                    subtitle: const Text("E.g., HDL Cholesterol. Result is flagged low if it falls below Min Range."),
                                    value: _isReverseLogic,
                                    onChanged: (v) => setState(() => _isReverseLogic = v),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}