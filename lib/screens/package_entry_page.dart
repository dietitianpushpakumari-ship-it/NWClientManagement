import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🎯 MODELS
import 'package:nutricare_client_management/models/programme_feature_model.dart';
import 'package:nutricare_client_management/modules/package/model/package_model.dart';
import 'package:nutricare_client_management/admin/inclusion_master_model.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_model.dart'; // 🎯 NEW

// 🎯 SERVICES
import 'package:nutricare_client_management/modules/package/service/program_feature_service.dart';
import 'package:nutricare_client_management/modules/package/service/package_Service.dart';
import 'package:nutricare_client_management/admin/inclusion_master_service.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_service.dart'; // 🎯 NEW

// 🎯 WIDGETS
import 'package:nutricare_client_management/admin/labvital/premium_master_select_sheet.dart';

class PackageEntryPage extends StatefulWidget {
  final PackageModel? packageToEdit;
  const PackageEntryPage({super.key, this.packageToEdit});

  @override
  State<PackageEntryPage> createState() => _PackageEntryPageState();
}

class _PackageEntryPageState extends State<PackageEntryPage> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _durationController = TextEditingController();
  final _sessionsController = TextEditingController(text: '0');
  final _consultationController = TextEditingController(text: '4');

  // 🎯 Removed _conditionsController in favor of List state

  // State Lists
  List<String> _selectedInclusionIds = [];
  List<String> _displayInclusionNames = [];
  List<String> _selectedTargetConditions = []; // 🎯 Stores Disease Names

  // Config Flags
  bool _isActive = true;
  bool _isTaxInclusive = true;

  // Dropdowns & Selectors
  late PackageCategory _selectedCategory;
  late List<String> _selectedFeatureIds;
  String? _selectedColorCode;

  // Services
  bool _isLoading = false;
  late Future<List<ProgramFeatureModel>> _programFeaturesFuture;
  final InclusionMasterService _inclusionService = InclusionMasterService();
  final DiseaseMasterService _diseaseService = DiseaseMasterService(); // 🎯 NEW

  // Color Options
  final Map<String, Color> _colorOptions = {
    'Teal': Colors.teal,
    'Blue': Colors.blue,
    'Indigo': Colors.indigo,
    'Purple': Colors.purple,
    'Pink': Colors.pink,
    'Orange': Colors.orange,
    'Green': Colors.green,
  };

  @override
  void initState() {
    super.initState();
    _programFeaturesFuture = ProgramFeatureService().streamAllFeatures().first;
    _selectedCategory = PackageCategory.basic;
    _selectedFeatureIds = [];
    _selectedColorCode = '0xFF009688';

    if (widget.packageToEdit != null) {
      _initializeForEdit(widget.packageToEdit!);
    }
  }

  void _initializeForEdit(PackageModel package) {
    _nameController.text = package.name;
    _descController.text = package.description;
    _priceController.text = package.price.toString();
    _originalPriceController.text = package.originalPrice?.toString() ?? "";
    _durationController.text = package.durationDays.toString();
    _sessionsController.text = package.freeSessions.toString();
    _consultationController.text = package.consultationCount.toString();

    // 🎯 Load Conditions
    _selectedTargetConditions = List.from(package.targetConditions);

    _isActive = package.isActive;
    _isTaxInclusive = package.isTaxInclusive;
    _selectedCategory = package.category;
    _selectedFeatureIds = List.from(package.programFeatureIds);
    _selectedColorCode = package.colorCode;

    _selectedInclusionIds = List.from(package.inclusionIds);
    _displayInclusionNames = List.from(package.inclusions);
  }

  // 🎯 DISEASE SELECTOR (Search + Add)
  void _openDiseaseSelector() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PremiumMasterSelectSheet<DiseaseMasterModel>(
        title: "Target Conditions",
        itemLabel: "Disease",
        stream: _diseaseService.getActiveDiseases(), // Stream from your service

        // 🎯 LOGIC: Use 'enName' as ID to store readable names in PackageModel
        getName: (item) => item.enName,
        getId: (item) => item.enName,

        selectedIds: _selectedTargetConditions,

        // Actions
        onAdd: (name) async => await _diseaseService.addDisease(
            DiseaseMasterModel(id: '', enName: name)
        ),
        onEdit: (item, name) async => await _diseaseService.updateDisease(
            item.copyWith(enName: name)
        ),
        onDelete: (item) async => await _diseaseService.softDeleteDisease(item.id),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTargetConditions = result;
      });
    }
  }

  void _openInclusionSelector() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PremiumMasterSelectSheet<InclusionMasterModel>(
        title: "Manage Inclusions",
        itemLabel: "Inclusion",
        stream: _inclusionService.streamAllInclusions(),
        getName: (item) => item.name,
        getId: (item) => item.id,
        selectedIds: _selectedInclusionIds,
        onAdd: (name) async => await _inclusionService.addInclusion(name),
        onEdit: (item, name) async => await _inclusionService.updateInclusion(item.id, name),
        onDelete: (item) async => await _inclusionService.deleteInclusion(item.id),
      ),
    );

    if (result != null) {
      final names = await _inclusionService.resolveNames(result);
      setState(() {
        _selectedInclusionIds = result;
        _displayInclusionNames = names;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _durationController.dispose();
    _sessionsController.dispose();
    _consultationController.dispose();
    super.dispose();
  }

  Future<void> _savePackage() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final packageService = Provider.of<PackageService>(context, listen: false);

    // Resolve inclusion names if needed
    if (_displayInclusionNames.length != _selectedInclusionIds.length) {
      _displayInclusionNames = await _inclusionService.resolveNames(_selectedInclusionIds);
    }

    final newPackage = PackageModel(
      id: widget.packageToEdit?.id ?? '',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      price: double.parse(_priceController.text),
      originalPrice: double.tryParse(_originalPriceController.text),
      isTaxInclusive: _isTaxInclusive,
      durationDays: int.tryParse(_durationController.text) ?? 30,
      consultationCount: int.tryParse(_consultationController.text) ?? 4,
      freeSessions: int.tryParse(_sessionsController.text) ?? 0,

      inclusionIds: _selectedInclusionIds,
      inclusions: _displayInclusionNames,

      // 🎯 SAVE CONDITIONS FROM MASTER LIST
      targetConditions: _selectedTargetConditions,

      isActive: _isActive,
      category: _selectedCategory,
      programFeatureIds: _selectedFeatureIds,
      colorCode: _selectedColorCode,
    );

    try {
      if (widget.packageToEdit == null) {
        await packageService.addPackage(newPackage);
      } else {
        await packageService.updatePackage(newPackage);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Package saved!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(widget.packageToEdit == null ? 'New Package' : 'Edit Package', onSave: _savePackage, isLoading: _isLoading),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // --- 1. BASIC INFO & LOOK ---
                          _buildSectionTitle("Presentation"),
                          Container(
                              padding: const EdgeInsets.all(20),
                              decoration: _cardDeco(),
                              child: Column(
                                children: [
                                  _buildTextField(_nameController, "Package Name", Icons.label),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<PackageCategory>(
                                          value: _selectedCategory,
                                          decoration: _inputDec("Category", Icons.category),
                                          items: PackageCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName))).toList(),
                                          onChanged: (val) => setState(() => _selectedCategory = val!),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _colorOptions.keys.firstWhere((k) => _colorOptions[k]!.value.toString() == _selectedColorCode, orElse: () => 'Teal'),
                                          decoration: _inputDec("Color Theme", Icons.color_lens),
                                          items: _colorOptions.keys.map((name) {
                                            return DropdownMenuItem(
                                              value: name,
                                              child: Row(
                                                children: [
                                                  CircleAvatar(backgroundColor: _colorOptions[name], radius: 6),
                                                  const SizedBox(width: 8),
                                                  Text(name),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) => setState(() => _selectedColorCode = _colorOptions[val]!.value.toString()),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(_descController, "Description (Marketing)", Icons.description, maxLines: 3),
                                  const SizedBox(height: 12),

                                  // 🎯 TARGET CONDITIONS (Selector)
                                  _buildTargetConditionsSection(),
                                ],
                              )
                          ),

                          // --- 2. PRICING & BILLING ---
                          _buildSectionTitle("Pricing & Billing"),
                          Container(
                              padding: const EdgeInsets.all(20),
                              decoration: _cardDeco(),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _buildTextField(_priceController, "Selling Price", Icons.currency_rupee, isNumber: true)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildTextField(_originalPriceController, "MRP (Optional)", Icons.price_change, isNumber: true)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SwitchListTile(
                                    title: const Text("Price includes Taxes (GST)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    value: _isTaxInclusive,
                                    onChanged: (v) => setState(() => _isTaxInclusive = v),
                                    activeColor: Colors.green,
                                    contentPadding: EdgeInsets.zero,
                                  )
                                ],
                              )
                          ),

                          // --- 3. SCOPE & LIMITS ---
                          _buildSectionTitle("Duration & Limits"),
                          Container(
                              padding: const EdgeInsets.all(20),
                              decoration: _cardDeco(),
                              child: Row(
                                children: [
                                  Expanded(child: _buildTextField(_durationController, "Validity (Days)", Icons.calendar_today, isNumber: true)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildTextField(_consultationController, "Consultations", Icons.video_call, isNumber: true)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildTextField(_sessionsController, "Free Sessions", Icons.card_giftcard, isNumber: true)),
                                ],
                              )
                          ),

                          // --- 4. INCLUSIONS ---
                          _buildSectionTitle("Inclusions & Features"),
                          Container(
                              padding: const EdgeInsets.all(20),
                              decoration: _cardDeco(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Package Inclusions", style: TextStyle(fontWeight: FontWeight.bold)),
                                      TextButton.icon(
                                        onPressed: _openInclusionSelector,
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text("Edit List"),
                                      )
                                    ],
                                  ),
                                  if (_selectedInclusionIds.isEmpty)
                                    const Text("No inclusions selected.", style: TextStyle(color: Colors.grey, fontSize: 12))
                                  else
                                    Wrap(
                                      spacing: 8, runSpacing: 8,
                                      children: _displayInclusionNames.map((name) => Chip(
                                        label: Text(name, style: const TextStyle(fontSize: 11)),
                                        backgroundColor: Colors.orange.shade50,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      )).toList(),
                                    ),

                                  const Divider(height: 24),
                                  const Text("Program Features (App Access)", style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  FutureBuilder<List<ProgramFeatureModel>>(
                                    future: _programFeaturesFuture,
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) return const LinearProgressIndicator();
                                      return Wrap(
                                        spacing: 8.0, runSpacing: 8.0,
                                        children: snapshot.data!.map((feature) {
                                          final isSelected = _selectedFeatureIds.contains(feature.id);
                                          return FilterChip(
                                            label: Text(feature.name),
                                            selected: isSelected,
                                            onSelected: (v) => setState(() => v ? _selectedFeatureIds.add(feature.id) : _selectedFeatureIds.remove(feature.id)),
                                            selectedColor: Colors.blue.shade50,
                                            checkmarkColor: Colors.blue,
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              )
                          ),

                          // --- 5. STATUS ---
                          _buildSectionTitle("Status"),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: _cardDeco(),
                            child: SwitchListTile(
                              title: const Text("Package Active", style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(_isActive ? "Visible in sales lists" : "Archived / Hidden"),
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                              activeColor: Colors.green,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildTargetConditionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Target Conditions", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            TextButton(
              onPressed: _openDiseaseSelector,
              child: const Text("Select / Add"),
            )
          ],
        ),
        if (_selectedTargetConditions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: const Text("No specific conditions targeted.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          )
        else
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _selectedTargetConditions.map((condition) => Chip(
              label: Text(condition),
              backgroundColor: Colors.blue.shade50,
              onDeleted: () {
                setState(() {
                  _selectedTargetConditions.remove(condition);
                });
              },
            )).toList(),
          ),
      ],
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
  );

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 0, 8),
      child: Text(title.toUpperCase(), style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
    );
  }

  Widget _buildHeader(String title, {required VoidCallback onSave, required bool isLoading}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white.withOpacity(0.9),
      child: Row(children: [
        GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back)),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.check_circle, color: Colors.deepPurple, size: 28))
      ]),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl, keyboardType: isNumber ? TextInputType.number : TextInputType.text, maxLines: maxLines,
      decoration: _inputDec(label, icon), validator: (v) => v!.isEmpty && !label.contains("Optional") ? "Required" : null,
    );
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        filled: true, fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)
    );
  }
}