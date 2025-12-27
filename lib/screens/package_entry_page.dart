import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// MODELS & SERVICES
import 'package:nutricare_client_management/modules/package/model/package_model.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart' hide masterDataServiceProvider;
import 'package:nutricare_client_management/admin/services/master_data_service.dart';
import 'package:nutricare_client_management/modules/package/service/package_Service.dart';

// WIDGETS
import 'package:nutricare_client_management/master_diet_planner/generic_multi_select_dialogg.dart';
import 'package:nutricare_client_management/admin/generic_clinical_master_entry_screen.dart';

class PackageDurationOption {
  String? id;
  String durationLabel;
  int durationDays;
  double price;
  int followUpIntervalDays;
  double? originalPrice;
  int consultationCount;
  int freeSessions;
  List<String> inclusionNames;
  List<String> featureNames;

  PackageDurationOption({
    this.id,
    required this.durationLabel,
    required this.durationDays,
    required this.price,
    this.originalPrice,
    this.consultationCount = 0,
    this.followUpIntervalDays = 7,
    this.freeSessions = 0,
    this.inclusionNames = const [],
    this.featureNames = const [],
  });

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
      followUpIntervalDays: package.followUpIntervalDays,
    );
  }
}

// --- Providers ---
final masterServiceProvider = masterDataServiceProvider;
final mapper = MasterCollectionMapper.getPath;

final packageTypeMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_packageType));
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

class PackageEntryPage extends ConsumerStatefulWidget {
  final PackageModel? packageToEdit;
  const PackageEntryPage({super.key, this.packageToEdit});

  @override
  ConsumerState<PackageEntryPage> createState() => _PackageEntryPageState();
}

class _PackageEntryPageState extends ConsumerState<PackageEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  List<PackageDurationOption> _durationOptions = [];
  List<String> _selectedTargetConditions = [];
  bool _isActive = true;
  bool _isTaxInclusive = true;

  PackageCategory _selectedCategory = PackageCategory.basic;
  String? _selectedPackageType;

  bool _isLoading = false;
  bool _isReadOnly = false;

  final List<DurationPreset> _durationPresets = [
    DurationPreset(label: "3 Days", days: 3),
    DurationPreset(label: "5 Days", days: 5),
    DurationPreset(label: "7 Days", days: 7),
    DurationPreset(label: "1 Month", days: 30),
    DurationPreset(label: "3 Months", days: 90),
    DurationPreset(label: "6 Months", days: 180),
    DurationPreset(label: "9 Months", days: 270),
    DurationPreset(label: "1 Year", days: 365),
  ];

  @override
  void initState() {
    super.initState();

    if (widget.packageToEdit != null) {
      _initializeForEdit(widget.packageToEdit!);
    } else {
      _durationOptions.add(PackageDurationOption(
        durationLabel: "",
        durationDays: 0,
        price: 0.0,
      ));
    }
  }

  void _initializeForEdit(PackageModel package) {
    _nameController.text = package.name;
    _descController.text = package.description;
    _selectedCategory = package.category;
    _selectedPackageType = package.packageType.isNotEmpty ? package.packageType : null;
    _selectedTargetConditions = List.from(package.targetConditions);
    _isActive = package.isActive;
    _isTaxInclusive = package.isTaxInclusive;
    if (package.isFinalized) {
      _isReadOnly = true;
    }

    if (package.durationDays > 0) {
      _durationOptions = [PackageDurationOption.fromOldPackage(package)];
    } else {
      _durationOptions = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  void _addDurationOption(DurationPreset preset) {
    setState(() {
      _durationOptions.add(PackageDurationOption(
        durationLabel: preset.label,
        durationDays: preset.days,
        price: 0.0,
      ));
    });
  }

  void _addEmptyOption() {
    setState(() {
      _durationOptions.add(PackageDurationOption(
        durationLabel: "",
        durationDays: 0,
        price: 0.0,
      ));
    });
  }

  void _removeDurationOption(int index) {
    setState(() {
      _durationOptions.removeAt(index);
    });
  }

  // --- UI DIALOGS ---
  void _openMultiSelectDialog({required AutoDisposeFutureProvider<Map<String, String>> provider, required List<String> currentKeys, required String title, required Function(List<String>) onResult, required String entityName, bool singleSelect = false}) async {
    final masterDataAsync = ref.read(provider);
    if (masterDataAsync.hasValue) {
      final masterDataMap = masterDataAsync.value!;
      final result = await showModalBottomSheet<List<String>>(
        context: context, isScrollControlled: true,
        builder: (ctx) => GenericMultiSelectDialog(title: title, items: masterDataMap.keys.toList(), itemNameIdMap: masterDataMap, initialSelectedItems: currentKeys, singleSelect: singleSelect, onAddMaster: () {
          Navigator.pop(context);
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => GenericClinicalMasterEntryScreen(entityName: entityName))).then((_) { ref.invalidate(provider); });
        }),
      );
      if (result != null) onResult(result);
    }
  }

  void _openPackageTypeSelector() {
    _openMultiSelectDialog(
        provider: packageTypeMasterProvider,
        currentKeys: _selectedPackageType != null ? [_selectedPackageType!] : [],
        title: "Select Package Type",
        entityName: MasterEntity.entity_packageType,
        singleSelect: true,
        onResult: (r) => setState(() => _selectedPackageType = r.isNotEmpty ? r.first : null)
    );
  }

  void _openTargetConditionSelector() {
    _openMultiSelectDialog(provider: targetConditionMasterProvider, currentKeys: _selectedTargetConditions, title: "Target Health Conditions", entityName: MasterEntity.entity_packageTargetCondition, onResult: (r) => setState(() => _selectedTargetConditions = r));
  }

  // 🎯 Auto-Assign Color based on Category
  String _getCategoryColorHex(PackageCategory category) {
    Color color;
    switch (category) {
      case PackageCategory.premium: color = Colors.deepPurple; break;
      case PackageCategory.standard: color = Colors.teal; break;
      case PackageCategory.basic: color = Colors.orange; break;
      case PackageCategory.singleSession: color = Colors.blue; break;
      case PackageCategory.custom: color = Colors.blueGrey; break;
    }
    return '0x${color.value.toRadixString(16).toUpperCase()}';
  }

  Future<void> _savePackage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPackageType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Package Type (from Master).")));
      return;
    }
    if (_durationOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add at least one variant.")));
      return;
    }

    setState(() => _isLoading = true);
    final packageService = ref.read(packageServiceProvider);
    final firstOption = _durationOptions.first;

    final newPackage = PackageModel(
      id: widget.packageToEdit?.id ?? '',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      packageType: _selectedPackageType!,
      price: firstOption.price,
      originalPrice: firstOption.originalPrice,
      durationDays: firstOption.durationDays,
      consultationCount: firstOption.consultationCount,
      freeSessions: firstOption.freeSessions,
      inclusionIds: firstOption.inclusionNames,
      inclusions: firstOption.inclusionNames,
      programFeatureIds: firstOption.featureNames,
      targetConditions: _selectedTargetConditions,
      isActive: _isActive,

      // 🎯 Auto-calculated color
      colorCode: _getCategoryColorHex(_selectedCategory),

      followUpIntervalDays: firstOption.followUpIntervalDays,
      isTaxInclusive: _isTaxInclusive,
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.packageToEdit != null;
    final typeAsync = ref.watch(packageTypeMasterProvider);
    final inclusionAsync = ref.watch(packageInclusionMasterProvider);
    final featureAsync = ref.watch(programFeatureMasterProvider);
    final targetConditionAsync = ref.watch(targetConditionMasterProvider);

    if (typeAsync.isLoading || inclusionAsync.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(
                    isEdit ? (_isReadOnly ? 'View Package' : 'Edit Package') : 'New Package',
                    onSave: _savePackage,
                    isLoading: _isLoading,
                    isReadOnly: _isReadOnly
                ),
                Expanded(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: AbsorbPointer(
                        absorbing: _isReadOnly,
                        child: Opacity(
                          opacity: _isReadOnly ? 0.7 : 1.0,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                // BASIC INFO
                                _buildSectionTitle("Presentation"),
                                Container(
                                    padding: const EdgeInsets.all(20), decoration: _cardDeco(),
                                    child: Column(
                                      children: [
                                        _buildField("Package Name",_nameController,  Icons.label),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                                flex: 2,
                                                child: DropdownButtonFormField<PackageCategory>(
                                                  value: _selectedCategory,
                                                  decoration: _inputDec("Category", Icons.category),
                                                  items: PackageCategory.values.map((e) => DropdownMenuItem(value: e, child: Text(e.displayName))).toList(),
                                                  onChanged: (val) => setState(() => _selectedCategory = val!),
                                                )
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(flex: 2, child: _buildTypeSelector()),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        _buildField("Description (Marketing)",_descController,  Icons.description, maxLines: 3),
                                        const SizedBox(height: 12),
                                        _buildTargetConditionsSection(),
                                      ],
                                    )
                                ),

                                // DURATION & PRICING
                                _buildSectionTitle("Duration, Pricing & Components"),
                                _buildDurationOptionsEditor(inclusionAsync.value ?? {}, featureAsync.value ?? {}),

                                // STATUS
                                _buildSectionTitle("Status"),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: _cardDeco(),
                                  child: SwitchListTile(title: const Text("Package Active", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(_isActive ? "Visible in sales lists" : "Archived / Hidden"), value: _isActive, onChanged: (v) => setState(() => _isActive = v), activeColor: Colors.green, contentPadding: EdgeInsets.zero),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),),)
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationOptionsEditor(Map<String, String> allInclusions, Map<String, String> allFeatures) {
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Package Variants", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          SwitchListTile(title: const Text("Price includes Taxes (GST)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), value: _isTaxInclusive, onChanged: (v) => setState(() => _isTaxInclusive = v), activeColor: Colors.green, contentPadding: EdgeInsets.zero),
          const Divider(),

          ..._durationOptions.asMap().entries.map((entry) => _buildSingleDurationOption(entry.key, entry.value, allInclusions, allFeatures)).toList(),
          const SizedBox(height: 16),

          Text("Quick Add:", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _durationPresets.map((preset) {
              return ActionChip(
                label: Text(preset.label),
                backgroundColor: Colors.deepPurple.shade50,
                labelStyle: TextStyle(color: Colors.deepPurple.shade700, fontSize: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.deepPurple.shade100)),
                onPressed: () => _addDurationOption(preset),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addEmptyOption,
              icon: const Icon(Icons.add),
              label: const Text("Add Custom Variant"),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHeader(String title, {required VoidCallback onSave, required bool isLoading, bool isReadOnly = false}) {
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

            if (!isReadOnly)
              IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.check_circle, color: Colors.deepPurple, size: 28))
          ]),
        ),
      ),
    );
  }

  Widget _buildSingleDurationOption(int index, PackageDurationOption option, Map<String, String> allInclusions, Map<String, String> allFeatures) {
    final DurationControllers controllers = DurationControllers(option);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.deepPurple.shade100), boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.05), blurRadius: 5)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controllers.label,
                  decoration: const InputDecoration(labelText: "Variant Name (e.g. One Time, 3 Months)", isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0), border: InputBorder.none, labelStyle: TextStyle(color: Colors.deepPurple)),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 16),
                  onChanged: (val) => option.durationLabel = val,
                ),
              ),
              if (_durationOptions.length > 1) IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 20), onPressed: () => _removeDurationOption(index)),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(child: _buildField("Validity (Days)", controllers.durationDays, Icons.calendar_today, isNumber: true, validator: (v) { option.durationDays = int.tryParse(v ?? '0') ?? 0; return v!.isEmpty ? "Required" : null; })),
              const SizedBox(width: 8),
              Expanded(child: _buildField("Follow-up (Days)", controllers.followUpInterval, Icons.update, isNumber: true, validator: (v) {
                option.followUpIntervalDays = int.tryParse(v ?? '7') ?? 7;
                return null;
              })),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildField("Selling Price", controllers.price, Icons.currency_rupee, isNumber: true, validator: (v) { option.price = double.tryParse(v ?? '0.0') ?? 0.0; return v!.isEmpty ? "Required" : null; })),
              const SizedBox(width: 8),
              Expanded(child: _buildField("MRP (Optional)", controllers.originalPrice, Icons.price_change, isNumber: true, validator: (v) { option.originalPrice = double.tryParse(v ?? ''); return null; })),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildField("Consultations", controllers.consultationCount, Icons.video_call, isNumber: true, validator: (v) { option.consultationCount = int.tryParse(v ?? '0') ?? 0; return null; })),
              const SizedBox(width: 8),
              Expanded(child: _buildField("Free Sessions", controllers.freeSessions, Icons.card_giftcard, isNumber: true, validator: (v) { option.freeSessions = int.tryParse(v ?? '0') ?? 0; return null; })),
            ],
          ),
          const SizedBox(height: 16),
          _buildVariantComponentSelector(title: "Inclusions", currentNames: option.inclusionNames, allMasterMap: allInclusions, entityName: MasterEntity.entity_packageInclusion, onUpdate: (newNames) => setState(() => option.inclusionNames = newNames)),
          const SizedBox(height: 10),
          _buildVariantComponentSelector(title: "Features", currentNames: option.featureNames, allMasterMap: allFeatures, entityName: MasterEntity.entity_packagefeature, onUpdate: (newNames) => setState(() => option.featureNames = newNames)),
        ],
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildVariantComponentSelector({required String title, required List<String> currentNames, required Map<String, String> allMasterMap, required String entityName, required ValueChanged<List<String>> onUpdate}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), TextButton(onPressed: () => _openMultiSelectDialog(provider: entityName == MasterEntity.entity_packageInclusion ? packageInclusionMasterProvider : programFeatureMasterProvider, currentKeys: currentNames, title: "Manage Package $title", entityName: entityName, onResult: onUpdate), child: Text(currentNames.isEmpty ? "Select" : "Edit (${currentNames.length})"))]),
        if (currentNames.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: currentNames.map((name) => Chip(label: Text(name, style: const TextStyle(fontSize: 11)), backgroundColor: title == "Inclusions" ? Colors.orange.shade50 : Colors.blue.shade50, onDeleted: () => onUpdate(currentNames.where((n) => n != name).toList()), deleteIcon: const Icon(Icons.close, size: 18))).toList()),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(controller: ctrl, keyboardType: isNumber ? TextInputType.number : TextInputType.text, maxLines: maxLines, decoration: _inputDec(label, icon), validator: validator);
  }

  InputDecoration _inputDec(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18, color: Colors.grey), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14));

  Widget _buildTypeSelector() {
    return GestureDetector(
        onTap: _openPackageTypeSelector,
        child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: _selectedPackageType == null ? Colors.red : Colors.transparent)),
            alignment: Alignment.centerLeft,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_selectedPackageType ?? "Select Type", style: TextStyle(color: _selectedPackageType == null ? Colors.red : Colors.black, fontWeight: _selectedPackageType == null ? FontWeight.w500 : FontWeight.normal)),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey)
                ]
            )
        )
    );
  }

  Widget _buildTargetConditionsSection() { return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Target Conditions", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)), TextButton(onPressed: _openTargetConditionSelector, child: Text(_selectedTargetConditions.isEmpty ? "Select Conditions" : "Edit (${_selectedTargetConditions.length})"))]), if (_selectedTargetConditions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: _selectedTargetConditions.map((conditionName) => Chip(label: Text(conditionName), backgroundColor: Colors.blue.shade50, onDeleted: () => setState(() => _selectedTargetConditions.remove(conditionName)))).toList())]); }
  BoxDecoration _cardDeco() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]);
  Widget _buildSectionTitle(String title) { return Padding(padding: const EdgeInsets.fromLTRB(4, 24, 0, 8), child: Text(title.toUpperCase(), style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1))); }
}

class DurationControllers {
  late TextEditingController label;
  late TextEditingController durationDays;
  late TextEditingController price;
  late TextEditingController originalPrice;
  late TextEditingController consultationCount;
  late TextEditingController freeSessions;
  late TextEditingController followUpInterval;

  DurationControllers(PackageDurationOption option) {
    label = TextEditingController(text: option.durationLabel);
    durationDays = TextEditingController(text: option.durationDays == 0 ? '' : option.durationDays.toString());
    price = TextEditingController(text: option.price.toString());
    originalPrice = TextEditingController(text: option.originalPrice?.toString() ?? '');
    consultationCount = TextEditingController(text: option.consultationCount.toString());
    freeSessions = TextEditingController(text: option.freeSessions.toString());
    followUpInterval = TextEditingController(text: option.followUpIntervalDays.toString());
  }

  void dispose() {
    label.dispose();
    durationDays.dispose();
    price.dispose();
    originalPrice.dispose();
    consultationCount.dispose();
    freeSessions.dispose();
    followUpInterval.dispose();
  }
}

class DurationPreset {
  final String label;
  final int days;
  DurationPreset({required this.label, required this.days});
}