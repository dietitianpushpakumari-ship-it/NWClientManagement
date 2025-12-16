
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/master_diet_planner/complex_input_widgets.dart';
import 'package:nutricare_client_management/master_diet_planner/generic_multi_select_dialogg.dart';
import 'package:nutricare_client_management/master_diet_planner/history_sections.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/admin/generic_clinical_master_entry_screen.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';

// --- Master Data Service and Mapper Setup ---
final masterServiceProvider = masterDataServiceProvider;
final mapper = MasterCollectionMapper.getPath;

// 🎯 FIX 1: Changed return type to Map<String, String> and used MasterCollectionMapper
final allergiesMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_allergy));
});
final diseaseMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_disease));
});
final lifeStyleHabitMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_LifestyleHabit));
});
final giMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_giSymptom));
});
final supplimentMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_supplement));
});
final caffeineMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_caffeineSource));
});
final waterIntakeMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_waterIntake));
});

// 🎯 NEW PROVIDERS for previously hardcoded dropdowns
final foodHabitMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_foodHabitsOptions));
});
final activityMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_ActivityLevels));
});
final sleepMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_SleepQuality));
});
final menstrualMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_MenstrualStatus));
});
// --------------------------------------------------------------------


// ❌ REMOVED: Hardcoded constants are now obsolete

class ClientHistorySheet extends ConsumerStatefulWidget {
  final ClientModel client;
  final VitalsModel? latestVitals;
  final Function(bool isSaved) onSave;

  const ClientHistorySheet({
    super.key,
    required this.client,
    this.latestVitals,
    required this.onSave,
  });

  @override
  ConsumerState<ClientHistorySheet> createState() => _ClientHistorySheetState();
}

class _ClientHistorySheetState extends ConsumerState<ClientHistorySheet> {
  final _formKey = GlobalKey<FormState>();

  String? _foodHabit;
  String? _activityType;
  int _stressLevel = 5;
  String? _sleepQuality;
  String? _menstrualStatus;

  List<String> _selectedFoodAllergies = [];
  Map<String, String> _selectedWaterIntake = {};

  // List of keys to track selected master items (used for rendering sub-widgets)
  List<String> _medicationKeys = [];
  List<String> _caffeineKeys = [];
  List<String> _medicalConditionKeys = [];
  List<String> _giDetailKeys = [];
  List<String> _lifestyleHabitKeys = [];

  // Maps to store the final combined data from the sub-widgets' controllers (the source of truth for submission)
  Map<String, String> _finalMedications = {};
  Map<String, String> _finalCaffeine = {};
  Map<String, String> _finalMedicalHistory = {};
  Map<String, String> _finalGIDetails = {};
  Map<String, String> _finalHabits = {};


  bool _isLoading = false;

  // --- Helper Methods (Copied from previous state logic) ---
  Map<String, String> _safeToMapOfStrings(dynamic data) {
    if (data == null) return {};
    if (data is Map) return Map<String, String>.from(data.cast<String, String>());
    return {};
  }

  List<String> _safeToListOfStrings(dynamic data) {
    if (data == null) return [];
    if (data is Iterable) return List<String>.from(data.cast<String>());
    if (data is String && data.isNotEmpty) return [data];
    return [];
  }

  @override
  void initState() {
    super.initState();
    _foodHabit = widget.latestVitals?.foodHabit;
    _activityType = widget.latestVitals?.activityType;
    _stressLevel = widget.latestVitals?.stressLevel ?? 5;
    _sleepQuality = widget.latestVitals?.sleepQuality;
    _menstrualStatus = widget.latestVitals?.menstrualStatus;

    _selectedFoodAllergies = _safeToListOfStrings(widget.latestVitals?.foodAllergies);
    _selectedWaterIntake = _safeToMapOfStrings(widget.latestVitals?.waterIntake);

    // Initialize Keys from Vitals Model Maps
    _finalMedications = _safeToMapOfStrings(widget.latestVitals?.prescribedMedications);
    _medicationKeys = _finalMedications.keys.toList();

    _finalCaffeine = _safeToMapOfStrings(widget.latestVitals?.caffeineIntake);
    _caffeineKeys = _finalCaffeine.keys.toList();

    _finalMedicalHistory = _safeToMapOfStrings(widget.latestVitals?.medicalHistory);
    _medicalConditionKeys = _finalMedicalHistory.keys.toList();

    _finalGIDetails = _safeToMapOfStrings(widget.latestVitals?.giDetails);
    _giDetailKeys = _finalGIDetails.keys.toList();

    _finalHabits = _safeToMapOfStrings(widget.latestVitals?.otherLifestyleHabits);
    _lifestyleHabitKeys = _finalHabits.keys.toList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 🎯 UNIFIED CALLBACK: Updates the state when a sub-widget reports a change
  void _updateComplexMap(String keyType, Map<String, String> data) {
    setState(() {
      if (keyType == 'medication') _finalMedications = data;
      else if (keyType == 'caffeine') _finalCaffeine = data;
      else if (keyType == 'medical') _finalMedicalHistory = data;
      else if (keyType == 'gi') _finalGIDetails = data;
      else if (keyType == 'habit') _finalHabits = data;
    });
  }


  Future<void> _saveHistory() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final updateData = {
        // Simple/Dropdowns
        'foodHabit': _foodHabit, 'activityType': _activityType, 'stressLevel': _stressLevel, 'sleepQuality': _sleepQuality, 'menstrualStatus': _menstrualStatus,
        'foodAllergies': _selectedFoodAllergies, 'waterIntake': _selectedWaterIntake,

        // Complex Map Fields (Directly from updated state)
        'medicalHistory': _finalMedicalHistory,
        'otherLifestyleHabits': _finalHabits,
        'giDetails': _finalGIDetails,
        'prescribedMedications': _finalMedications,
        'caffeineIntake': _finalCaffeine,
      };

      // 2. Perform database update (Placeholder for service call)
      // await ref.read(vitalsServiceProvider).updateHistoryData(widget.client.id, updateData);

      widget.onSave(true);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save failed: $e")));
      widget.onSave(false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Master Navigation/Dialog Handlers (FIXED) ---
  // 🎯 FIX 2: Used MasterCollectionMapper and added collectionPath to GenericClinicalMasterEntryScreen
  void _addMasterDisease() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GenericClinicalMasterEntryScreen(
      entityName: MasterEntity.entity_disease,
    ))).then((_) => ref.invalidate(diseaseMasterProvider));
  }

  void _addMasterHabit() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GenericClinicalMasterEntryScreen(
      entityName: MasterEntity.entity_LifestyleHabit,
    ))).then((_) => ref.invalidate(lifeStyleHabitMasterProvider));
  }

  void _addMasterAllergy() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GenericClinicalMasterEntryScreen(
        entityName: MasterEntity.entity_allergy
    ))).then((_) => ref.invalidate(allergiesMasterProvider));
  }

  void _addMasterGIMaster() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GenericClinicalMasterEntryScreen(
// Uses mapper
        entityName: MasterEntity.entity_giSymptom
    ))).then((_) => ref.invalidate(giMasterProvider));
  }

  void _addMasterWaterIntake() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GenericClinicalMasterEntryScreen(
      // Uses mapper
        entityName: MasterEntity.entity_waterIntake
    ))).then((_) => ref.invalidate(waterIntakeMasterProvider));
  }

  void _addMasterCaffeineIntake() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GenericClinicalMasterEntryScreen(
   // Uses mapper
        entityName: MasterEntity.entity_caffeineSource
    ))).then((_) => ref.invalidate(caffeineMasterProvider));
  }

  void _addMasterSupplement() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GenericClinicalMasterEntryScreen(
      // Uses mapper
        entityName: MasterEntity.entity_supplement
    ))).then((_) => ref.invalidate(supplimentMasterProvider));
  }

  // 🎯 FIX 3: Updated _openDialog signature to handle Map<String, String>
  void _openDialog(Map<String, String> masterDataMap, List<String> currentKeys, String title, Function(List<String>) onResult, VoidCallback onAddMaster, {bool singleSelect = false}) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => GenericMultiSelectDialog(
        title: title,
        items: masterDataMap.keys.toList(), // 🎯 Pass List of Names (Keys)
        itemNameIdMap: masterDataMap, // 🎯 Pass the map for full functionality
        initialSelectedItems: currentKeys,
        onAddMaster: onAddMaster,
        singleSelect: singleSelect,
      ),
    );
    if (result != null) onResult(result);
  }


  // 🎯 FIX 4: Update dialog functions to pass Map<String, String>
  void _openMedicalHistoryDialog(Map<String, String> allDiseases) {
    _openDialog(allDiseases, _medicalConditionKeys, "Select Medical Conditions", (r) => setState(() => _medicalConditionKeys = r), _addMasterDisease);
  }
  void _openGIDetailsDialog(Map<String, String> allGI) {
    _openDialog(allGI, _giDetailKeys, "Select GI Details", (r) => setState(() => _giDetailKeys = r), _addMasterGIMaster);
  }
  void _openMedicationSelectDialog(Map<String, String> allSupplements) {
    _openDialog(allSupplements, _medicationKeys, "Select Medications/Supplements", (r) => setState(() => _medicationKeys = r), _addMasterSupplement);
  }
  void _openCaffeineIntakeDialog(Map<String, String> allCaffeine) {
    _openDialog(allCaffeine, _caffeineKeys, "Select Caffeine Source", (r) => setState(() => _caffeineKeys = r), _addMasterCaffeineIntake);
  }
  void _openHabitDialog(Map<String, String> allHabits) {
    _openDialog(allHabits, _lifestyleHabitKeys, "Manage Lifestyle Habits", (r) => setState(() => _lifestyleHabitKeys = r), _addMasterHabit);
  }
  void _openAllergiesDialog(Map<String, String> allAllergies) {
    _openDialog(allAllergies, _selectedFoodAllergies, "Select Food Allergies", (r) => setState(() => _selectedFoodAllergies = r), _addMasterAllergy);
  }
  void _openWaterIntakeDialog(Map<String, String> allWater) {
    _openDialog(allWater, _selectedWaterIntake.keys.toList(), "Select Water Intake",
            (r) {
          final Map<String, String> newMap = {};
          if (r.isNotEmpty) newMap[r.first] = 'Selected';
          setState(() => _selectedWaterIntake = newMap);
        }, _addMasterWaterIntake, singleSelect: true
    );
  }


  @override
  Widget build(BuildContext context) {
    // 🎯 Watch all master providers
    final allergiesAsync = ref.watch(allergiesMasterProvider);
    final diseasesAsync = ref.watch(diseaseMasterProvider);
    final lifeStylehabitsAsync = ref.watch(lifeStyleHabitMasterProvider);
    final giAsync = ref.watch(giMasterProvider);
    final waterAsync = ref.watch(waterIntakeMasterProvider);
    final caffeineAsync = ref.watch(caffeineMasterProvider);
    final supplementAsync = ref.watch(supplimentMasterProvider);

    // Watch new dropdown providers
    final foodHabitAsync = ref.watch(foodHabitMasterProvider);
    final activityAsync = ref.watch(activityMasterProvider);
    final sleepAsync = ref.watch(sleepMasterProvider);
    final menstrualAsync = ref.watch(menstrualMasterProvider);


    if (allergiesAsync.isLoading || diseasesAsync.isLoading || lifeStylehabitsAsync.isLoading || giAsync.isLoading || waterAsync.isLoading || caffeineAsync.isLoading || supplementAsync.isLoading ||
        foodHabitAsync.isLoading || activityAsync.isLoading || sleepAsync.isLoading || menstrualAsync.isLoading) {
      return const Scaffold(appBar: null, body: Center(child: CircularProgressIndicator()));
    }
    if (allergiesAsync.hasError || diseasesAsync.hasError || lifeStylehabitsAsync.hasError || giAsync.hasError || waterAsync.hasError || caffeineAsync.hasError || supplementAsync.hasError ||
        foodHabitAsync.hasError || activityAsync.hasError || sleepAsync.hasError || menstrualAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error loading master data: ${allergiesAsync.error ?? diseasesAsync.error ?? lifeStylehabitsAsync.error ?? giAsync.error ?? waterAsync.error ?? caffeineAsync.error ?? supplementAsync.error ?? foodHabitAsync.error ?? activityAsync.error ?? sleepAsync.error ?? menstrualAsync.error}')),
      );
    }

    // 🎯 Extract Map values (for Complex Inputs)
    final allDiseasesMap = diseasesAsync.value!;
    final allSupplementsMap = supplementAsync.value!;
    final allGIMap = giAsync.value!;
    final allWaterMap = waterAsync.value!;
    final allCaffeineMap = caffeineAsync.value!;
    final allLifestyleHabitsMap = lifeStylehabitsAsync.value!;
    final allAllergiesMap = allergiesAsync.value!;

    // 🎯 Extract Dropdown Options (Lists of Names)
    final allFoodHabits = foodHabitAsync.value!.keys.toList();
    final allActivityTypes = activityAsync.value!.keys.toList();
    final allSleepQualities = sleepAsync.value!.keys.toList();
    final allMenstrualStatuses = menstrualAsync.value!.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Column(
        children: [
          buildCustomHeader(context),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // --- Section 1: Medical History ---
                  buildCard(
                    title: "Medical & Clinical Details",
                    icon: Icons.local_hospital,
                    color: Colors.blue,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Medical Conditions with Duration
                        const Text("Selected Conditions:", style: TextStyle(fontWeight: FontWeight.w600)),
                        ..._medicalConditionKeys.map((key) => MedicalDurationInput(
                          key: ValueKey(key), condition: key, initialDetail: _finalMedicalHistory[key] ?? '',
                          onChanged: (map) => _updateComplexMap('medical', map),
                          onDelete: () => setState(() { _medicalConditionKeys.remove(key); _finalMedicalHistory.remove(key); }),
                        )).toList(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(onPressed: () => _openMedicalHistoryDialog(allDiseasesMap), icon: const Icon(Icons.list), label: const Text("Select Conditions")),
                            IconButton(onPressed: _addMasterDisease, icon: const Icon(Icons.add_circle, color: Colors.green), tooltip: "Add Disease Master"),
                          ],
                        ),
                        const Divider(height: 25),

                        // Medications/Supplements
                        const Text("Selected Medications/Supplements:", style: TextStyle(fontWeight: FontWeight.w600)),
                        ..._medicationKeys.map((key) => MedicationDosageInput(
                          key: ValueKey(key), medication: key, initialDetail: _finalMedications[key] ?? '',
                          onChanged: (map) => _updateComplexMap('medication', map),
                          onDelete: () => setState(() { _medicationKeys.remove(key); _finalMedications.remove(key); }),
                        )).toList(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(onPressed: () => _openMedicationSelectDialog(allSupplementsMap), icon: const Icon(Icons.medication), label: const Text("Add/Remove Items")),
                            IconButton(onPressed: _addMasterSupplement, icon: const Icon(Icons.add_circle, color: Colors.green), tooltip: "Add Supplement Master"),
                          ],
                        ),
                        const Divider(height: 25),

                        // GI Health
                        const Text("Selected GI Details:", style: TextStyle(fontWeight: FontWeight.w600)),
                        ..._giDetailKeys.map((key) => GIDetailInput(
                          key: ValueKey(key), detail: key, initialDetail: _finalGIDetails[key] ?? '',
                          onChanged: (map) => _updateComplexMap('gi', map),
                          onDelete: () => setState(() { _giDetailKeys.remove(key); _finalGIDetails.remove(key); }),
                        )).toList(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(onPressed: () => _openGIDetailsDialog(allGIMap), icon: const Icon(Icons.sick), label: const Text("Select GI Symptoms")),
                            IconButton(onPressed: _addMasterGIMaster, icon: const Icon(Icons.add_circle, color: Colors.green), tooltip: "Add GI Master"),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- Section 2: Diet, Hydration, Allergies ---
                  buildCard(
                    title: "Diet & Intake",
                    icon: Icons.restaurant,
                    color: Colors.orange,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🎯 Dynamic Food Habit Dropdown
                        DropdownButtonFormField<String>(
                          value: _foodHabit, items: allFoodHabits.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(), onChanged: (v) => setState(() => _foodHabit = v), decoration: const InputDecoration(labelText: 'Food Habit', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),

                        // Water Intake (Single Select)
                        Text("Current Water Intake (${_selectedWaterIntake.length}):", style: const TextStyle(fontWeight: FontWeight.w600)),
                        Wrap(spacing: 8.0, children: _selectedWaterIntake.entries.map((e) => Chip(label: Text(e.key), onDeleted: () => setState(() => _selectedWaterIntake.remove(e.key)), deleteIcon: const Icon(Icons.close, size: 18))).toList()),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(onPressed: () => _openWaterIntakeDialog(allWaterMap), icon: const Icon(Icons.local_drink), label: const Text("Select Water Intake")),
                            IconButton(onPressed: _addMasterWaterIntake, icon: const Icon(Icons.add_circle, color: Colors.green), tooltip: "Add Water Master"),
                          ],
                        ),
                        const Divider(height: 25),

                        // Caffeine Intake (COMPLEX INPUT)
                        const Text("Caffeine Intake Details:", style: TextStyle(fontWeight: FontWeight.w600)),
                        ..._caffeineKeys.map((key) => CaffeineInput(
                          key: ValueKey(key), source: key, initialDetail: _finalCaffeine[key] ?? '',
                          onChanged: (map) => _updateComplexMap('caffeine', map),
                          onDelete: () => setState(() { _caffeineKeys.remove(key); _finalCaffeine.remove(key); }),
                        )).toList(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(onPressed: () => _openCaffeineIntakeDialog(allCaffeineMap), icon: const Icon(Icons.coffee), label: const Text("Add/Remove Sources")),
                            IconButton(onPressed: _addMasterCaffeineIntake, icon: const Icon(Icons.add_circle, color: Colors.green), tooltip: "Add Caffeine Master"),
                          ],
                        ),
                        const Divider(height: 25),

                        // Allergies Multi-select
                        Text("Selected Allergies: ${_selectedFoodAllergies.length}", style: const TextStyle(fontWeight: FontWeight.w600)),
                        Wrap(spacing: 8.0, children: _selectedFoodAllergies.map((id) => Chip(label: Text(id), onDeleted: () => setState(() => _selectedFoodAllergies.remove(id)), deleteIcon: const Icon(Icons.close, size: 18))).toList()),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(onPressed: () => _openAllergiesDialog(allAllergiesMap), icon: const Icon(Icons.warning_amber), label: const Text("Select Allergies")),
                            IconButton(onPressed: _addMasterAllergy, icon: const Icon(Icons.add_circle, color: Colors.green), tooltip: "Add Allergy Master"),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- Section 3: Lifestyle & Behavioral ---
                  buildCard(
                    title: "Lifestyle & Behavioral",
                    icon: Icons.self_improvement,
                    color: Colors.green,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🎯 Dynamic Activity Type Dropdown
                        DropdownButtonFormField<String>(
                          value: _activityType, items: allActivityTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _activityType = v), decoration: const InputDecoration(labelText: 'Activity Level', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),

                        // Stress Level (Slider)
                        const Text("Stress Level (1=Low, 10=High):", style: TextStyle(fontWeight: FontWeight.w600)),
                        Slider(value: _stressLevel.toDouble(), min: 1, max: 10, divisions: 9, label: _stressLevel.toString(), onChanged: (double value) { setState(() { _stressLevel = value.round(); }); }),
                        const SizedBox(height: 16),

                        // 🎯 Dynamic Sleep Quality Dropdown
                        DropdownButtonFormField<String>(
                          value: _sleepQuality, items: allSleepQualities.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(), onChanged: (v) => setState(() => _sleepQuality = v), decoration: const InputDecoration(labelText: 'Sleep Quality/Duration', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),

                        // Habits Multi-select (COMPLEX INPUT)
                        const Text("Selected Habits:", style: TextStyle(fontWeight: FontWeight.w600)),
                        // The updated HabitFrequencyInput is used here
                        ..._lifestyleHabitKeys.map((key) => HabitFrequencyInput(
                          key: ValueKey(key), habit: key, initialDetail: _finalHabits[key] ?? '',
                          onChanged: (map) => _updateComplexMap('habit', map),
                          onDelete: () => setState(() { _lifestyleHabitKeys.remove(key); _finalHabits.remove(key); }),
                        )).toList(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(onPressed: () => _openHabitDialog(allLifestyleHabitsMap), icon: const Icon(Icons.add_circle_outline), label: const Text("Manage Habits")),
                            IconButton(onPressed: _addMasterHabit, icon: const Icon(Icons.add_circle, color: Colors.green), tooltip: "Add Habit Master"),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- Section 4: Women's Health (Conditional) ---
                  if (widget.client.gender != 'Male')
                    buildCard(
                      title: "Women's Health",
                      icon: Icons.female,
                      color: Colors.pink,
                      child: DropdownButtonFormField<String>(
                        // 🎯 Dynamic Menstrual Status Dropdown
                        value: _menstrualStatus, items: allMenstrualStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _menstrualStatus = v), decoration: const InputDecoration(labelText: 'Menstrual/Hormonal Status', border: OutlineInputBorder()),
                      ),
                    ),

                  // --- Save Button ---
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveHistory,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE HISTORY & LIFESTYLE"),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}