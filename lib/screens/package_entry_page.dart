import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🎯 MODELS
import 'package:nutricare_client_management/modules/package/model/package_model.dart'; // Assume PackageModel is imported
import 'package:nutricare_client_management/master/model/master_constants.dart';

// 🎯 SERVICES
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart' hide masterDataServiceProvider;
import 'package:nutricare_client_management/admin/services/master_data_service.dart';
import 'package:nutricare_client_management/modules/package/service/package_Service.dart';

// 🎯 WIDGETS
import 'package:nutricare_client_management/master_diet_planner/generic_multi_select_dialogg.dart';
import 'package:nutricare_client_management/admin/generic_clinical_master_entry_screen.dart';


// --- Nested Model for Duration Variants ---
class PackageDurationOption {
  String? id;
  String durationLabel; // e.g., "3 Months"
  int durationDays;
  double price;
  double? originalPrice;
  int consultationCount;
  int freeSessions;
  List<String> inclusionNames; // Varies by duration
  List<String> featureNames; // Varies by duration

  PackageDurationOption({
    this.id,
    required this.durationLabel,
    required this.durationDays,
    required this.price,
    this.originalPrice,
    this.consultationCount = 0,
    this.freeSessions = 0,
    this.inclusionNames = const [],
    this.featureNames = const [],
  });

  // Helper to convert data coming from the old single-field package model
  factory PackageDurationOption.fromOldPackage(PackageModel package) {
    return PackageDurationOption(
      durationLabel: "${package.durationDays} Days",
      durationDays: package.durationDays,
      price: package.price,
      originalPrice: package.originalPrice,
      consultationCount: package.consultationCount,
      freeSessions: package.freeSessions,
      inclusionNames: package.inclusions,
      featureNames: package.programFeatureIds,
    );
  }
}
// -------------------------------------------

// --- Master Data Service and Providers ---
final masterServiceProvider = masterDataServiceProvider;
final mapper = MasterCollectionMapper.getPath;

final packageCategoryMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_packageCategory));
});

final packageInclusionMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_packageInclusion));
});

final programFeatureMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_packagefeature));
});

final targetConditionMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_packageTargetCondition));
});
// --------------------------------------------------------------------


class PackageEntryPage extends ConsumerStatefulWidget {
  final PackageModel? packageToEdit;
  const PackageEntryPage({super.key, this.packageToEdit});

  @override
  ConsumerState<PackageEntryPage> createState() => _PackageEntryPageState();
}

class _PackageEntryPageState extends ConsumerState<PackageEntryPage> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers (Only for base info)
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  // NEW STATE: List of Duration Options
  List<PackageDurationOption> _durationOptions = [];

  // State Lists (Now only storing base package info)
  List<String> _selectedTargetConditions = [];

  // Config Flags
  bool _isActive = true;
  bool _isTaxInclusive = true;

  // Dropdowns & Selectors
  String? _selectedCategoryName; // Stores the selected category name (string)
  String? _selectedColorCode; // Stores the hex string '0xFFRRGGBB'

  // Services
  bool _isLoading = false;

  // Color Options
  final Map<String, Color> _colorOptions = {
    'Teal': Colors.teal, 'Blue': Colors.blue, 'Indigo': Colors.indigo,
    'Purple': Colors.purple, 'Pink': Colors.pink, 'Orange': Colors.orange,
    'Green': Colors.green,
  };

  // Standard duration presets
  final List<DurationPreset> _durationPresets = [
    DurationPreset(label: "1 Month", days: 30),
    DurationPreset(label: "3 Months", days: 90),
    DurationPreset(label: "6 Months", days: 180),
    DurationPreset(label: "9 Months", days: 270),
    DurationPreset(label: "1 Year", days: 365),
  ];

  String _colorToHexString(Color color) {
    return '0x${color.value.toRadixString(16).toUpperCase()}';
  }


  @override
  void initState() {
    super.initState();

    _selectedCategoryName = null;
    _selectedColorCode = _colorToHexString(Colors.teal);

    if (widget.packageToEdit != null) {
      _initializeForEdit(widget.packageToEdit!);
    } else {
      // Initialize with a default 1-month option for new packages
      _durationOptions.add(PackageDurationOption(
        durationLabel: _durationPresets.first.label,
        durationDays: _durationPresets.first.days,
        price: 0.0,
      ));
    }
  }

  void _initializeForEdit(PackageModel package) {
    _nameController.text = package.name;
    _descController.text = package.description;

    // Use display name from the PackageCategory enum for initial state
    _selectedCategoryName = package.category.displayName;
    _selectedTargetConditions = List.from(package.targetConditions);

    _isActive = package.isActive;
    _isTaxInclusive = package.isTaxInclusive;
    _selectedColorCode = package.colorCode;

    // FIX: Always derive duration options from the single-variant fields
    if (package.durationDays > 0 && package.price >= 0) {
      _durationOptions = [PackageDurationOption.fromOldPackage(package)];
    } else {
      _durationOptions = [];
    }

    if (_durationOptions.isEmpty) {
      // Ensure at least one blank option is present for editing new data
      _durationOptions.add(PackageDurationOption(
        durationLabel: _durationPresets.first.label,
        durationDays: _durationPresets.first.days,
        price: 0.0,
      ));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- DURATION OPTION MANAGEMENT ---
  void _addDurationOption(DurationPreset preset) {
    setState(() {
      _durationOptions.add(PackageDurationOption(
        durationLabel: preset.label,
        durationDays: preset.days,
        price: 0.0,
      ));
    });
  }

  void _removeDurationOption(int index) {
    setState(() {
      _durationOptions.removeAt(index);
    });
  }

  // --- GENERIC DIALOG HANDLERS (Same as before) ---

  void _openMultiSelectDialog({
    required AutoDisposeFutureProvider<Map<String, String>> provider,
    required List<String> currentKeys,
    required String title,
    required Function(List<String>) onResult,
    required String entityName,
    bool singleSelect = false,
  }) async {
    final masterDataAsync = ref.read(provider);

    if (masterDataAsync.hasValue) {
      final masterDataMap = masterDataAsync.value!;

      final result = await showModalBottomSheet<List<String>>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => GenericMultiSelectDialog(
          title: title,
          items: masterDataMap.keys.toList(),
          itemNameIdMap: masterDataMap,
          initialSelectedItems: currentKeys,
          singleSelect: singleSelect,
          onAddMaster: () {
            Navigator.pop(context);
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GenericClinicalMasterEntryScreen(
                entityName: entityName,
              ),
            )).then((_) {
              ref.invalidate(provider);
            });
          },
        ),
      );
      if (result != null) onResult(result);
    } else if (masterDataAsync.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading master data: ${masterDataAsync.error}")));
    }
  }

  void _openCategorySelector() {
    _openMultiSelectDialog(
      provider: packageCategoryMasterProvider,
      currentKeys: _selectedCategoryName != null ? [_selectedCategoryName!] : [],
      title: "Select Package Category",
      entityName: MasterEntity.entity_packageCategory,
      singleSelect: true,
      onResult: (r) => setState(() => _selectedCategoryName = r.isNotEmpty ? r.first : null),
    );
  }

  void _openTargetConditionSelector() {
    _openMultiSelectDialog(
      provider: targetConditionMasterProvider,
      currentKeys: _selectedTargetConditions,
      title: "Target Health Conditions",
      entityName: MasterEntity.entity_packageTargetCondition,
      onResult: (r) => setState(() => _selectedTargetConditions = r),
    );
  }

  // --- SAVE LOGIC (Updated to handle List of Options) ---

  Future<void> _savePackage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryName == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Package Category.")));
      return;
    }

    // Ensure at least one duration option exists
    if (_durationOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add at least one duration/price option.")));
      return;
    }

    setState(() => _isLoading = true);

    final packageService = ref.read(packageServiceProvider);

    final categoryEnum = PackageCategory.values.firstWhere(
            (e) => e.displayName == _selectedCategoryName,
        orElse: () => PackageCategory.basic
    );

    // Use data from the first option to satisfy required fields in the old PackageModel structure
    final firstOption = _durationOptions.first;

    final newPackage = PackageModel(
      id: widget.packageToEdit?.id ?? '',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),

      // FIX: Reinstate required fields using the first option's data to satisfy the current PackageModel definition
      price: firstOption.price,
      originalPrice: firstOption.originalPrice,
      durationDays: firstOption.durationDays,
      consultationCount: firstOption.consultationCount,
      freeSessions: firstOption.freeSessions,
      inclusionIds: firstOption.inclusionNames,
      inclusions: firstOption.inclusionNames,
      programFeatureIds: firstOption.featureNames,

      // FIX: REMOVE the undeclared parameter 'durationOptions'

      targetConditions: _selectedTargetConditions,
      isActive: _isActive,
      category: categoryEnum,
      colorCode: _selectedColorCode,
    );

    try {
      if (widget.packageToEdit == null) {
        // NOTE: Saving will not include variants until PackageModel is updated.
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
    final isEdit = widget.packageToEdit != null;

    final categoryAsync = ref.watch(packageCategoryMasterProvider);
    final inclusionAsync = ref.watch(packageInclusionMasterProvider);
    final featureAsync = ref.watch(programFeatureMasterProvider);
    final targetConditionAsync = ref.watch(targetConditionMasterProvider);

    if (categoryAsync.isLoading || inclusionAsync.isLoading || featureAsync.isLoading || targetConditionAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (categoryAsync.hasError || inclusionAsync.hasError || featureAsync.hasError || targetConditionAsync.hasError) {
      return Scaffold(body: Center(child: Text("Error loading masters: ${categoryAsync.error ?? inclusionAsync.error ?? featureAsync.error ?? targetConditionAsync.error}")));
    }

    final allInclusions = inclusionAsync.value!;
    final allFeatures = featureAsync.value!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(isEdit ? 'Edit Package' : 'New Package', onSave: _savePackage, isLoading: _isLoading),
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
                                  _buildField("Package Name",_nameController,  Icons.label),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      // PACKAGE CATEGORY (Single Select Button)
                                      Expanded(child: _buildCategorySelector()),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedColorCode,
                                          decoration: _inputDec("Color Theme", Icons.color_lens),
                                          items: _colorOptions.keys.map((name) {
                                            return DropdownMenuItem<String>(
                                              value: _colorToHexString(_colorOptions[name]!),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(backgroundColor: _colorOptions[name], radius: 6),
                                                  const SizedBox(width: 8),
                                                  Text(name),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) => setState(() => _selectedColorCode = val),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildField("Description (Marketing)",_descController,  Icons.description, maxLines: 3),
                                  const SizedBox(height: 12),

                                  // TARGET CONDITIONS (Multi-Select Button)
                                  _buildTargetConditionsSection(),
                                ],
                              )
                          ),

                          // --- 2. DURATION & PRICING EDITOR (NEW COMPLEX SECTION) ---
                          _buildSectionTitle("Duration, Pricing & Components"),
                          _buildDurationOptionsEditor(allInclusions, allFeatures),

                          // --- 3. STATUS ---
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

  // --- NEW WIDGET: DURATION OPTIONS EDITOR ---
  Widget _buildDurationOptionsEditor(Map<String, String> allInclusions, Map<String, String> allFeatures) {
    // Moved pricing fields inside here. Add back isTaxInclusive switch for global pricing config.
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Package Variants", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),

          SwitchListTile(
            title: const Text("Price includes Taxes (GST)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            value: _isTaxInclusive,
            onChanged: (v) => setState(() => _isTaxInclusive = v),
            activeColor: Colors.green,
            contentPadding: EdgeInsets.zero,
          ),

          const Divider(),

          // List of Duration Option Forms
          ..._durationOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return _buildSingleDurationOption(index, option, allInclusions, allFeatures);
          }).toList(),

          const SizedBox(height: 16),

          // Add New Duration Button
          DropdownButtonFormField<String>( // 🎯 CORRECTED TYPE TO STRING
            decoration: _inputDec("Add New Duration", Icons.add_circle),
            isExpanded: true,
            value: null, // Always null so the hint is always visible
            // 🎯 CORRECTED ITEMS: Use String value for comparison
            items: _durationPresets
                .where((p) => !_durationOptions.any((o) => o.durationLabel == p.label))
                .map((p) => DropdownMenuItem<String>(
              value: p.label, // Use label string
              child: Text(p.label),
            ))
                .toList(),
            onChanged: (selectedLabel) {
              if (selectedLabel != null) {
                // Find the original preset object by label
                final preset = _durationPresets.firstWhere((p) => p.label == selectedLabel);
                _addDurationOption(preset);
              }
            },
            hint: const Text("Add Duration Variant"),
          ),
        ],
      ),
    );
  }

  // NEW WIDGET: Single Duration Option Form
  Widget _buildSingleDurationOption(int index, PackageDurationOption option, Map<String, String> allInclusions, Map<String, String> allFeatures) {
    final DurationControllers controllers = DurationControllers(option);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(option.durationLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              if (_durationOptions.length > 1)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  onPressed: () => _removeDurationOption(index),
                ),
            ],
          ),
          const Divider(),

          // Pricing & Duration Fields
          Row(
            children: [
              Expanded(child: _buildField("Validity (Days)", controllers.durationDays, Icons.calendar_today, isNumber: true, validator: (v) {
                option.durationDays = int.tryParse(v ?? '0') ?? 0;
                return v!.isEmpty ? "Required" : null;
              })),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildField("Selling Price", controllers.price, Icons.currency_rupee, isNumber: true, validator: (v) {
                option.price = double.tryParse(v ?? '0.0') ?? 0.0;
                return v!.isEmpty ? "Required" : null;
              })),
              const SizedBox(width: 8),
              Expanded(child: _buildField("MRP (Optional)", controllers.originalPrice, Icons.price_change, isNumber: true, validator: (v) {
                option.originalPrice = double.tryParse(v ?? '');
                return null;
              })),
            ],
          ),
          const SizedBox(height: 10),

          // Limits Fields
          Row(
            children: [
              Expanded(child: _buildField("Consultations", controllers.consultationCount, Icons.video_call, isNumber: true, validator: (v) {
                option.consultationCount = int.tryParse(v ?? '0') ?? 0;
                return null;
              })),
              const SizedBox(width: 8),
              Expanded(child: _buildField("Free Sessions", controllers.freeSessions, Icons.card_giftcard, isNumber: true, validator: (v) {
                option.freeSessions = int.tryParse(v ?? '0') ?? 0;
                return null;
              })),
            ],
          ),

          // Dynamic Components: Inclusions & Features
          const SizedBox(height: 16),
          _buildVariantComponentSelector(
            title: "Inclusions",
            currentNames: option.inclusionNames,
            allMasterMap: allInclusions,
            entityName: MasterEntity.entity_packageInclusion,
            onUpdate: (newNames) => setState(() => option.inclusionNames = newNames),
          ),
          const SizedBox(height: 10),
          _buildVariantComponentSelector(
            title: "Features",
            currentNames: option.featureNames,
            allMasterMap: allFeatures,
            entityName: MasterEntity.entity_packagefeature,
            onUpdate: (newNames) => setState(() => option.featureNames = newNames),
          ),
        ],
      ),
    );
  }

  // NEW WIDGET: Component Selector for each duration variant
  Widget _buildVariantComponentSelector({
    required String title,
    required List<String> currentNames,
    required Map<String, String> allMasterMap,
    required String entityName,
    required ValueChanged<List<String>> onUpdate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            TextButton(
              onPressed: () => _openMultiSelectDialog(
                provider: entityName == MasterEntity.entity_packageInclusion ? packageInclusionMasterProvider : programFeatureMasterProvider,
                currentKeys: currentNames,
                title: "Manage Package $title",
                entityName: entityName,
                onResult: onUpdate,
              ),
              child: Text(currentNames.isEmpty ? "Select" : "Edit (${currentNames.length})"),
            ),
          ],
        ),
        if (currentNames.isEmpty)
          Text("No $title selected for this variant.", style: TextStyle(color: Colors.grey.shade600, fontSize: 11))
        else
          Wrap(
            spacing: 8, runSpacing: 8,
            children: currentNames.map((name) => Chip(
              label: Text(name, style: const TextStyle(fontSize: 11)),
              backgroundColor: title == "Inclusions" ? Colors.orange.shade50 : Colors.blue.shade50,
              onDeleted: () {
                onUpdate(currentNames.where((n) => n != name).toList());
              },
              deleteIcon: const Icon(Icons.close, size: 18),
            )).toList(),
          ),
      ],
    );
  }


  // --- EXISTING WIDGETS (Modified or RETAINED) ---

  // Package Category Selector Widget (Single Select)
  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Category", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _openCategorySelector,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _selectedCategoryName == null ? Colors.red : Colors.transparent)
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategoryName ?? "Select Category",
                  style: TextStyle(
                    color: _selectedCategoryName == null ? Colors.red : Colors.black,
                    fontWeight: _selectedCategoryName == null ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Target Conditions Selector Widget (Multi-Select)
  Widget _buildTargetConditionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Target Conditions", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            TextButton(
              onPressed: _openTargetConditionSelector,
              child: Text(_selectedTargetConditions.isEmpty ? "Select Conditions" : "Edit (${_selectedTargetConditions.length})"),
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
            children: _selectedTargetConditions.map((conditionName) => Chip(
              label: Text(conditionName),
              backgroundColor: Colors.blue.shade50,
              onDeleted: () {
                setState(() {
                  _selectedTargetConditions.remove(conditionName);
                });
              },
            )).toList(),
          ),
      ],
    );
  }

  // --- HELPERS (Remaining) ---

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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.check_circle, color: Colors.deepPurple, size: 28))
          ]),
        ),
      ),
    );
  }

  // Final corrected _buildField
  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl, keyboardType: isNumber ? TextInputType.number : TextInputType.text, maxLines: maxLines,
      decoration: _inputDec(label, icon),
      validator: validator ?? ((v) => v!.isEmpty && !label.contains("Optional") ? "Required" : null),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        filled: true, fillColor: Colors.white, // Use white for fields inside colored card
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)
    );
  }
}

// --- Companion Classes ---

// Helper class to manage controllers for a single duration option (important for dynamic lists)
class DurationControllers {
  late TextEditingController durationDays;
  late TextEditingController price;
  late TextEditingController originalPrice;
  late TextEditingController consultationCount;
  late TextEditingController freeSessions;

  DurationControllers(PackageDurationOption option) {
    durationDays = TextEditingController(text: option.durationDays.toString());
    price = TextEditingController(text: option.price.toString());
    originalPrice = TextEditingController(text: option.originalPrice?.toString() ?? '');
    consultationCount = TextEditingController(text: option.consultationCount.toString());
    freeSessions = TextEditingController(text: option.freeSessions.toString());
  }

  void dispose() {
    durationDays.dispose();
    price.dispose();
    originalPrice.dispose();
    consultationCount.dispose();
    freeSessions.dispose();
  }
}

// Helper class for predefined duration options
class DurationPreset {
  final String label;
  final int days;
  DurationPreset({required this.label, required this.days});
}