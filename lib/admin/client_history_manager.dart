import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/consultation_summary_page.dart';

// 🎯 IMPORTS
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/master_diet_planner/generic_multi_select_dialogg.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';

// ==============================================================================
// 1. DATA PROVIDERS
// ==============================================================================
final medicalConditionProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
      final service = ref.watch(masterDataServiceProvider);
      return await service.fetchMasterList(
        MasterCollectionMapper.getPath(MasterEntity.entity_disease),
      );
    });

final giDetailsProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  final service = ref.watch(masterDataServiceProvider);
  return await service.fetchMasterList(
    MasterCollectionMapper.getPath(MasterEntity.entity_giSymptom),
  );
});

final caffeineProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  final service = ref.watch(masterDataServiceProvider);
  return await service.fetchMasterList(
    MasterCollectionMapper.getPath(MasterEntity.entity_caffeineSource),
  );
});

final activityProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  final service = ref.watch(masterDataServiceProvider);
  return await service.fetchMasterList(
    MasterCollectionMapper.getPath(MasterEntity.entity_LifestyleHabit),
  );
});

final allergyProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  final service = ref.watch(masterDataServiceProvider);
  return await service.fetchMasterList(
    MasterCollectionMapper.getPath(MasterEntity.entity_allergy),
  );
});

final medicineMasterProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  final service = ref.watch(masterDataServiceProvider);
  return await service.fetchMasterList(
    MasterCollectionMapper.getPath(MasterEntity.entity_supplement),
  );
});

final menstrualStatusProvider = FutureProvider.autoDispose<Map<String, String>>(
  (ref) async {
    final service = ref.watch(masterDataServiceProvider);
    return await service.fetchMasterList(
      MasterCollectionMapper.getPath(MasterEntity.entity_MenstrualStatus),
    );
  },
);

// 🎯 NEW: Food Habit Provider
final foodHabitProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  final service = ref.watch(masterDataServiceProvider);
  // Uses 'master_food_habits' collection
  return await service.fetchMasterList(
    MasterCollectionMapper.getPath(MasterEntity.entity_foodHabitsOptions),
  );
});

// ==============================================================================
// 2. SCREEN WIDGET
// ==============================================================================
class ClientHistoryManager extends ConsumerStatefulWidget {
  final ClientModel client;
  final String sessionId;
  final VitalsModel? latestVitals;
  final bool isReadOnly;
  final bool isFollowup;
  final Function(bool) onSaveComplete;

  const ClientHistoryManager({
    super.key,
    required this.client,
    required this.sessionId,
    this.latestVitals,
    required this.onSaveComplete,
    this.isReadOnly = false,
    this.isFollowup = false,
  });

  @override
  ConsumerState<ClientHistoryManager> createState() =>
      _ClientHistoryManagerState();
}

class _ClientHistoryManagerState extends ConsumerState<ClientHistoryManager> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- 1. COMPLEX MAPS ---
  late Map<String, String> _medicalHistory;
  late Map<String, String> _existingMeds;
  late Map<String, String> _giDetails;
  late Map<String, String> _caffeineIntake;
  late Map<String, String> _activityHabits;
  List<String> _foodAllergies = [];

  // --- 2. SINGLE VALUES ---
  int _stressLevel = 5;
  String _sleepQuality = 'Fair';
  String _activityType = 'Sedentary';
  String _foodHabit = 'Non-Vegetarian';
  String _waterIntake = '2-3 Liters';
  String _menstrualStatus = 'Regular';
  String _restrictedDiet = '';

  final TextEditingController _manualMedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final v = widget.latestVitals;

    _medicalHistory = Map<String, String>.from(v?.medicalHistory ?? {});
    _existingMeds = Map<String, String>.from(v?.prescribedMedications ?? {});
    _giDetails = Map<String, String>.from(v?.giDetails ?? {});
    _caffeineIntake = Map<String, String>.from(v?.caffeineIntake ?? {});
    _activityHabits = Map<String, String>.from(v?.otherLifestyleHabits ?? {});
    _foodAllergies = List<String>.from(v?.foodAllergies ?? []);

    _stressLevel = v?.stressLevel ?? 5;
    _sleepQuality = v?.sleepQuality ?? 'Fair';
    _activityType = v?.activityType ?? 'Sedentary';
    _foodHabit = v?.foodHabit ?? 'Non-Vegetarian';

    _menstrualStatus = v?.menstrualStatus ?? 'Regular';
    _restrictedDiet = v?.restrictedDiet ?? '';

    if (v?.waterIntake != null && v!.waterIntake!.isNotEmpty) {
      _waterIntake = v.waterIntake!.values.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch Providers
    final medicalAsync = ref.watch(medicalConditionProvider);
    final giAsync = ref.watch(giDetailsProvider);
    final caffeineAsync = ref.watch(caffeineProvider);
    final activityAsync = ref.watch(activityProvider);
    final allergyAsync = ref.watch(allergyProvider);
    final medMasterAsync = ref.watch(medicineMasterProvider);
    final menstrualAsync = ref.watch(menstrualStatusProvider);
    final foodHabitAsync = ref.watch(foodHabitProvider); // 🎯 Watch Food Habit

    if (medicalAsync.isLoading ||
        giAsync.isLoading ||
        caffeineAsync.isLoading ||
        activityAsync.isLoading ||
        allergyAsync.isLoading ||
        medMasterAsync.isLoading ||
        menstrualAsync.isLoading ||
        foodHabitAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final medicalMaster = medicalAsync.value ?? {};
    final giMaster = giAsync.value ?? {};
    final caffeineMaster = caffeineAsync.value ?? {};
    final activityMaster = activityAsync.value ?? {};
    final allergyMaster = allergyAsync.value ?? {};
    final medMaster = medMasterAsync.value ?? {};

    final menstrualMaster = menstrualAsync.value ?? {};
    final List<String> menstrualOptions = menstrualMaster.isNotEmpty
        ? menstrualMaster.keys.toList()
        : [
            "Regular",
            "Irregular",
            "Menopause",
            "PCOS/PCOD",
            "Pregnant",
            "None/Male",
          ];

    // 🎯 Prepare Food Habit Options (Master + Fallback)
    final foodHabitMaster = foodHabitAsync.value ?? {};
    final List<String> foodHabitOptions = foodHabitMaster.isNotEmpty
        ? foodHabitMaster.keys.toList()
        : ["Vegetarian", "Non-Vegetarian", "Eggetarian", "Vegan", "Jain"];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 50, bottom: 16),
              title: Text(
                widget.isFollowup ? "Update History" : "History & Lifestyle",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConsultationSummaryPage(
                        clientId: widget.client.id,
                        clientName: widget.client.name,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.history, color: Colors.indigo),
                tooltip: "View History Timeline",
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 1. BEHAVIORAL
                    _buildSectionContainer(
                      title: "Behavioral & Lifestyle",
                      icon: Icons.psychology,
                      color: Colors.purple,
                      children: [
                        _buildDropdownRow(
                          "Activity Level",
                          _activityType,
                          [
                            "Sedentary",
                            "Lightly Active",
                            "Moderately Active",
                            "Very Active",
                            "Super Active",
                          ],
                          (v) => setState(() => _activityType = v!),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownRow(
                          "Sleep Quality",
                          _sleepQuality,
                          [
                            "Poor (<5h)",
                            "Fair (6-7h)",
                            "Good (7-8h)",
                            "Excellent (>8h)",
                          ],
                          (v) => setState(() => _sleepQuality = v!),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownRow(
                          "Women's Health (Menstrual)",
                          _menstrualStatus,
                          menstrualOptions,
                          (v) => setState(() => _menstrualStatus = v!),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Stress Level",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "$_stressLevel/10",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _stressLevel.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              activeColor: Colors.purple,
                              label: _stressLevel.toString(),
                              onChanged: (v) =>
                                  setState(() => _stressLevel = v.toInt()),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // 2. DIET & ALLERGIES
                    _buildSectionContainer(
                      title: "Dietary Preferences",
                      icon: Icons.restaurant_menu,
                      color: Colors.teal,
                      children: [
                        // 🎯 UPDATED: Use dynamic options for Food Habit
                        _buildDropdownRow(
                          "Food Habit",
                          _foodHabit,
                          foodHabitOptions,
                          (v) => setState(() => _foodHabit = v!),
                        ),

                        const SizedBox(height: 16),
                        _buildDropdownRow(
                          "Water Intake",
                          _waterIntake,
                          [
                            "< 1 Liter",
                            "1-2 Liters",
                            "2-3 Liters",
                            "3-4 Liters",
                            "> 4 Liters",
                          ],
                          (v) => setState(() => _waterIntake = v!),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          initialValue: _restrictedDiet,
                          decoration: const InputDecoration(
                            labelText: "Restricted Diet (Optional)",
                            hintText: "e.g. Gluten Free, Keto, Low Carb",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => _restrictedDiet = v,
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Food Allergies",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _openMasterSelection(
                                title: "Select Allergies",
                                masterData: allergyMaster,
                                selectedItems: _foodAllergies,
                                provider: allergyProvider,
                                collectionPath: MasterCollectionMapper.getPath(
                                  MasterEntity.entity_allergy,
                                ),
                                onConfirm: (result) =>
                                    setState(() => _foodAllergies = result),
                              ),
                              icon: const Icon(Icons.playlist_add, size: 18),
                              label: const Text("Select"),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (_foodAllergies.isEmpty)
                              const Text(
                                "None selected",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ..._foodAllergies.map(
                              (a) => Chip(
                                label: Text(a),
                                onDeleted: widget.isReadOnly
                                    ? null
                                    : () => setState(
                                        () => _foodAllergies.remove(a),
                                      ),
                                backgroundColor: Colors.teal.shade50,
                                labelStyle: TextStyle(
                                  color: Colors.teal.shade900,
                                ),
                                deleteIconColor: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // 3. MEDICAL
                    _buildSectionCard(
                      title: "Medical Conditions",
                      icon: Icons.monitor_heart,
                      color: Colors.redAccent,
                      dataMap: _medicalHistory,
                      masterData: medicalMaster,
                      providerToRefresh: medicalConditionProvider,
                      collectionPath: MasterCollectionMapper.getPath(
                        MasterEntity.entity_disease,
                      ),
                      placeholder: "Tap to set duration",
                      dialogTitle: "Select Conditions",
                      onUpdate: (key, val) => _medicalHistory[key] = val,
                      onDelete: (key) => _medicalHistory.remove(key),
                      onTapItem: (key, val) => _openMedicalConfigSheet(
                        key,
                        val,
                        (v) => setState(() => _medicalHistory[key] = v),
                      ),
                    ),

                    // 4. MEDICATIONS
                    _buildSectionCard(
                      title: "Existing Medications",
                      icon: Icons.medication,
                      color: Colors.blue,
                      dataMap: _existingMeds,
                      masterData: medMaster,
                      providerToRefresh: medicineMasterProvider,
                      collectionPath: MasterCollectionMapper.getPath(
                        MasterEntity.entity_supplement,
                      ),
                      placeholder: "Tap to set dosage & freq",
                      dialogTitle: "Select Medications",
                      isManualAddEnabled: true,
                      onUpdate: (key, val) => _existingMeds[key] = val,
                      onDelete: (key) => _existingMeds.remove(key),
                      onTapItem: (key, val) => _openExistingMedConfigSheet(
                        key,
                        val,
                        (v) => setState(() => _existingMeds[key] = v),
                      ),
                    ),

                    // 5. GI
                    _buildSectionCard(
                      title: "GI / Digestive Health",
                      icon: Icons.spa,
                      color: Colors.green,
                      dataMap: _giDetails,
                      masterData: giMaster,
                      providerToRefresh: giDetailsProvider,
                      collectionPath: MasterCollectionMapper.getPath(
                        MasterEntity.entity_giSymptom,
                      ),
                      placeholder: "Tap to set severity",
                      dialogTitle: "Select GI Symptoms",
                      onUpdate: (key, val) => _giDetails[key] = val,
                      onDelete: (key) => _giDetails.remove(key),
                      onTapItem: (key, val) => _openGIConfigSheet(
                        key,
                        val,
                        (v) => setState(() => _giDetails[key] = v),
                      ),
                    ),

                    // 6. CAFFEINE
                    _buildSectionCard(
                      title: "Caffeine Sources",
                      icon: Icons.coffee,
                      color: Colors.brown,
                      dataMap: _caffeineIntake,
                      masterData: caffeineMaster,
                      providerToRefresh: caffeineProvider,
                      collectionPath: MasterCollectionMapper.getPath(
                        MasterEntity.entity_caffeineSource,
                      ),
                      placeholder: "Tap to set quantity",
                      dialogTitle: "Select Sources",
                      onUpdate: (key, val) => _caffeineIntake[key] = val,
                      onDelete: (key) => _caffeineIntake.remove(key),
                      onTapItem: (key, val) => _openHabitConfigSheet(
                        key,
                        val,
                        (v) => setState(() => _caffeineIntake[key] = v),
                        isCaffeine: true,
                      ),
                    ),

                    // 7. ACTIVITY
                    _buildSectionCard(
                      title: "Physical Activity Details",
                      icon: Icons.directions_run,
                      color: Colors.orange,
                      dataMap: _activityHabits,
                      masterData: activityMaster,
                      providerToRefresh: activityProvider,
                      collectionPath: MasterCollectionMapper.getPath(
                        MasterEntity.entity_LifestyleHabit,
                      ),
                      placeholder: "Tap to set duration",
                      dialogTitle: "Select Activities",
                      onUpdate: (key, val) => _activityHabits[key] = val,
                      onDelete: (key) => _activityHabits.remove(key),
                      onTapItem: (key, val) => _openHabitConfigSheet(
                        key,
                        val,
                        (v) => setState(() => _activityHabits[key] = v),
                      ),
                    ),

                    const SizedBox(height: 30),
                    if (!widget.isReadOnly)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveHistory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigoAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "SAVE HISTORY",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🧩 UNIFIED SELECTION HELPER
  // ===========================================================================
  void _openMasterSelection({
    required String title,
    required Map<String, String> masterData,
    required List<String> selectedItems,
    required AutoDisposeFutureProvider<Map<String, String>> provider,
    required String collectionPath,
    required Function(List<String>) onConfirm,
  }) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GenericMultiSelectDialog(
        title: title,
        items: masterData.keys.toList(),
        itemNameIdMap: masterData,
        initialSelectedItems: selectedItems,
        collectionPath: collectionPath,
        providerToRefresh: provider,
      ),
    );

    if (result != null) {
      onConfirm(result);
    }
  }

  // ===========================================================================
  // 🎨 UI HELPERS
  // ===========================================================================
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, String> dataMap,
    required Map<String, String> masterData,
    required String placeholder,
    required String dialogTitle,
    required AutoDisposeFutureProvider<Map<String, String>> providerToRefresh,
    required String collectionPath,
    required Function(String, String) onUpdate,
    required Function(String) onDelete,
    required Function(String, String) onTapItem,
    bool isManualAddEnabled = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          if (!widget.isReadOnly)
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _openMasterSelection(
                      title: dialogTitle,
                      masterData: masterData,
                      selectedItems: dataMap.keys.toList(),
                      provider: providerToRefresh,
                      collectionPath: collectionPath,
                      onConfirm: (result) {
                        setState(() {
                          dataMap.removeWhere(
                            (key, value) => !result.contains(key),
                          );
                          for (var item in result) {
                            if (!dataMap.containsKey(item))
                              dataMap[item] = "Not specified";
                          }
                        });
                      },
                    ),
                    icon: const Icon(Icons.playlist_add, size: 20),
                    label: const Text("Select from List"),
                    style: TextButton.styleFrom(
                      foregroundColor: color,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                if (isManualAddEnabled)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _openManualAddSheet(
                        title,
                        (val) => setState(() => dataMap[val] = "Not specified"),
                      ),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text("Manual Add"),
                      style: TextButton.styleFrom(
                        foregroundColor: color,
                        alignment: Alignment.centerRight,
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          if (dataMap.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "No items recorded.",
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ...dataMap.entries.map(
            (entry) => _buildDetailTile(
              title: entry.key,
              detail: entry.value,
              placeholder: placeholder,
              color: color,
              onTap: () => onTapItem(entry.key, entry.value),
              onDelete: () => setState(() => onDelete(entry.key)),
            ),
          ),
        ],
      ),
    );
  }

  // [SHEETS & HELPERS UNCHANGED]
  void _openMedicalConfigSheet(
    String name,
    String currentVal,
    Function(String) onSave,
  ) {
    String durationVal = '';
    String unit = 'Years';
    final parts = currentVal.split(' ');
    if (parts.length >= 2 && double.tryParse(parts[0]) != null) {
      durationVal = parts[0];
      unit = parts.sublist(1).join(' ');
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (c, st) => Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Details: $name",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: durationVal,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Duration",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => durationVal = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: ["Days", "Weeks", "Months", "Years"].contains(unit)
                          ? unit
                          : "Years",
                      decoration: const InputDecoration(
                        labelText: "Unit",
                        border: OutlineInputBorder(),
                      ),
                      items: ["Days", "Weeks", "Months", "Years"]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => st(() => unit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onSave("$durationVal $unit");
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("SAVE DETAILS"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openExistingMedConfigSheet(
    String name,
    String currentVal,
    Function(String) onSave,
  ) {
    String dosage = '';
    String freq = '1-0-1';
    String durationVal = '';
    String unit = 'Years';
    if (currentVal.contains('•')) {
      final parts = currentVal.split('•');
      if (parts.isNotEmpty) dosage = parts[0].replaceAll('mg', '').trim();
      if (parts.length > 1) freq = parts[1].trim();
      if (parts.length > 2) {
        final dParts = parts[2].trim().split(' ');
        if (dParts.isNotEmpty) durationVal = dParts[0];
        if (dParts.length > 1) unit = dParts[1];
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (c, st) => Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Medication: $name",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: dosage,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Dosage (mg)",
                        suffixText: "mg",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => dosage = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Frequency",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ["1-0-1", "1-0-0", "0-0-1", "1-1-1", "SOS"]
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: freq == f,
                            onSelected: (v) => st(() => freq = f),
                            selectedColor: Colors.blue.shade100,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: durationVal,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Duration",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => durationVal = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: ["Days", "Weeks", "Months", "Years"].contains(unit)
                          ? unit
                          : "Years",
                      decoration: const InputDecoration(
                        labelText: "Unit",
                        border: OutlineInputBorder(),
                      ),
                      items: ["Days", "Weeks", "Months", "Years"]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => st(() => unit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onSave("${dosage}mg • $freq • $durationVal $unit");
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("SAVE DETAILS"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openGIConfigSheet(
    String name,
    String currentVal,
    Function(String) onSave,
  ) {
    String durationVal = '';
    String unit = 'Months';
    String freq = 'Daily';
    String severity = 'Moderate';
    String note = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (c, st) => Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Symptom: $name",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: durationVal,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Duration",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => durationVal = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: unit,
                      decoration: const InputDecoration(
                        labelText: "Unit",
                        border: OutlineInputBorder(),
                      ),
                      items: ["Days", "Weeks", "Months", "Years"]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => st(() => unit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: severity,
                decoration: const InputDecoration(
                  labelText: "Severity",
                  border: OutlineInputBorder(),
                ),
                items: ["Mild", "Moderate", "Severe"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => st(() => severity = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Frequency",
                  hintText: "e.g. Daily, After meals",
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => freq = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Special Note (Optional)",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (v) => note = v,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    String result = "$severity • $freq • $durationVal $unit";
                    if (note.isNotEmpty) result += " • Note: $note";
                    onSave(result);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("SAVE DETAILS"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openHabitConfigSheet(
    String name,
    String currentVal,
    Function(String) onSave, {
    bool isCaffeine = false,
  }) {
    String durationVal = '';
    String unit = 'Years';
    String freq = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (c, st) => Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: isCaffeine ? "Quantity per Day" : "Frequency",
                  hintText: isCaffeine ? "e.g. 2 Cups" : "e.g. Daily, 3x/Week",
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => freq = v,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: durationVal,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Duration",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => durationVal = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: unit,
                      decoration: const InputDecoration(
                        labelText: "Unit",
                        border: OutlineInputBorder(),
                      ),
                      items: ["Days", "Weeks", "Months", "Years"]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => st(() => unit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onSave("$freq • $durationVal $unit");
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("SAVE DETAILS"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openManualAddSheet(String title, Function(String) onAdd) {
    _manualMedController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add $title"),
        content: TextField(
          controller: _manualMedController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Type name here..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_manualMedController.text.isNotEmpty) {
                onAdd(_manualMedController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDropdownRow(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: widget.isReadOnly ? null : onChanged,
    );
  }

  // 🎯 SAVE LOGIC
  Future<void> _saveHistory() async {
    setState(() => _isLoading = true);
    try {
      final updateData = {
        'medicalHistory': _medicalHistory,
        'prescribedMedications': _existingMeds,
        'giDetails': _giDetails,
        'caffeineIntake': _caffeineIntake,
        'otherLifestyleHabits': _activityHabits,
        'activityType': _activityType,
        'sleepQuality': _sleepQuality,
        'stressLevel': _stressLevel,
        'foodHabit': _foodHabit,
        'waterIntake': {'value': _waterIntake},
        'foodAllergies': _foodAllergies,
        'menstrualStatus': _menstrualStatus,
        'restrictedDiet': _restrictedDiet,

        'sessionId': widget.sessionId,
      };

      await ref
          .read(vitalsServiceProvider)
          .updateHistoryData(
            clientId: widget.client.id,
            updateData: updateData,
            existingVitals: widget.latestVitals,
          );
      await ref
          .read(firestoreProvider)
          .collection('consultation_sessions')
          .doc(widget.sessionId)
          .update({
            'steps.history': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      widget.onSaveComplete(true);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  Widget _buildDetailTile({
    required String title,
    required String detail,
    required String placeholder,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    // 1. Content Widget
    Widget content = GestureDetector(
      onTap: widget.isReadOnly ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (detail != 'Not specified' && detail.isNotEmpty)
                        ? detail
                        : placeholder,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                      (detail != 'Not specified' && detail.isNotEmpty)
                          ? Colors.black87
                          : Colors.grey,
                      fontStyle:
                      (detail != 'Not specified' && detail.isNotEmpty)
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.isReadOnly)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );

    // 2. Return plain content if ReadOnly
    if (widget.isReadOnly) return content;

    // 3. Return Dismissible for Swipe Actions
    return Dismissible(
      key: Key(title),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (direction) => onDelete(),
      child: content,
    );
  }
}
