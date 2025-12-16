import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

import 'package:nutricare_client_management/admin/labvital/clinical_master_service.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/labvital/premium_habit_select_sheet.dart';
import 'package:nutricare_client_management/admin/labvital/premium_master_select_sheet.dart';
import 'package:nutricare_client_management/admin/labvital/vitals_picker_sheet.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/master/model/food_item.dart';
import 'package:nutricare_client_management/master/model/guidelines.dart';
import 'package:nutricare_client_management/master/model/meal_master_name.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/screen/premium_meal_entry_list.dart';

import 'package:nutricare_client_management/master/model/diagonosis_master.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_model.dart';
import 'package:nutricare_client_management/modules/client/screen/suppliment_master_model.dart';
import 'package:nutricare_client_management/admin/habit_master_model.dart';
import 'package:nutricare_client_management/admin/habit_master_service.dart';



extension IterableExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class ClientDietPlanEntryPage extends ConsumerStatefulWidget {
  final String? planId;
  final ClientDietPlanModel? initialPlan;
  final VoidCallback onMealPlanSaved;

  const ClientDietPlanEntryPage({
    super.key,
    this.planId,
    this.initialPlan,
    required this.onMealPlanSaved
  });

  @override
  ConsumerState<ClientDietPlanEntryPage> createState() => _ClientDietPlanEntryPageState();
}

class _ClientDietPlanEntryPageState extends ConsumerState<ClientDietPlanEntryPage> with TickerProviderStateMixin {
  final Logger logger = Logger();

  TabController? _tabController;
  bool _isSaving = false;
  bool _isLoadingData = true;

  // --- PLAN DATA ---
  String _planName = '';
  VitalsModel? _linkedVitals;

  List<String> _diagnosisIds = [];
  List<String> _guidelineIds = [];
  List<String> _supplementIds = [];
  List<String> _investigationIds = [];

  List<String> _complaints = [];
  List<String> _clinicalNotes = [];
  List<String> _instructions = [];

  int _followUpDays = 0;
  bool _isProvisional = false;

  // 🎯 GOALS & HABITS STATE
  double _waterGoal = 3.0;
  double _sleepGoal = 7.5;
  int _stepGoal = 8000;
  int _mindfulnessGoal = 15;
  List<String> _assignedHabitIds = [];

  ClientDietPlanModel _currentPlan = const ClientDietPlanModel();
  List<FoodItem> _allFoodItems = [];
  List<MasterMealName> _allMealNames = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final foodItemService = ref.read(foodItemServiceProvider);
    final masterMealNameService = ref.read(masterMealNameServiceProvider);
    final clientDietPlanService = ref.read(clientDietPlanServiceProvider);
    final foods = await foodItemService.fetchAllActiveFoodItems();
    final meals = await masterMealNameService.fetchAllMealNames();
    meals.sort((a, b) => (a.startTime ?? "").compareTo(b.startTime ?? ""));

    ClientDietPlanModel plan;
    if (widget.planId != null) {
      plan = await clientDietPlanService.fetchPlanById(widget.planId!);
    } else if (widget.initialPlan != null) {
      plan = widget.initialPlan!;
    } else {
      final initialMeals = meals.map((m) => DietPlanMealModel(id: m.id, mealNameId: m.id, mealName: m.name, items: [], order: m.order)).toList();
      plan = ClientDietPlanModel(days: [MasterDayPlanModel(id: 'd1', dayName: 'Fixed Day', meals: initialMeals)]);
    }

    VitalsModel? loadedVitals;
    if (plan.linkedVitalsId != null && plan.linkedVitalsId!.isNotEmpty && plan.clientId.isNotEmpty) {
      try {
        final vitalsService = ref.read(vitalsServiceProvider);
        final allVitals = await vitalsService.getClientVitals(plan.clientId);
        loadedVitals = IterableExtensions(allVitals).firstWhereOrNull((v) => v.id == plan.linkedVitalsId);
      } catch (e) {
        logger.w("Could not load linked vitals: $e");
      }
    }

    if (mounted) {
      setState(() {
        _allFoodItems = foods;
        _allMealNames = meals;
        _currentPlan = plan;

        _planName = plan.name;
        _diagnosisIds = List.from(plan.diagnosisIds);
        _guidelineIds = List.from(plan.guidelineIds);
        _supplementIds = List.from(plan.suplimentIds);
        _investigationIds = List.from(plan.investigationIds);

        _complaints = _parseList(plan.complaints);
        _clinicalNotes = _parseList(plan.clinicalNotes, separator: '\n');
        _instructions = _parseList(plan.instructions, separator: '\n');

        _followUpDays = plan.followUpDays ?? 0;
        _isProvisional = plan.isProvisional;
        _linkedVitals = loadedVitals;

        // 🎯 Load Goals
        _waterGoal = plan.dailyWaterGoal;
        _sleepGoal = plan.dailySleepGoal;
        _stepGoal = plan.dailyStepGoal;
        _mindfulnessGoal = plan.dailyMindfulnessMinutes.toDouble().toInt();
        _assignedHabitIds = List.from(plan.assignedHabitIds);

        if (plan.days.isNotEmpty) {
          _tabController = TabController(length: plan.days.first.meals.length, vsync: this);
        }
        _isLoadingData = false;
      });
    }
  }

  List<String> _parseList(String text, {String separator = ', '}) {
    if (text.isEmpty) return [];
    return text.split(separator).where((s) => s.trim().isNotEmpty).map((e) => e.trim()).toList();
  }

  // --- SHEET LAUNCHERS ---

  void _openSettingsSheet() {

    final _diagonisService = ref.read(diagnosisMasterServiceProvider);
    final _guidelineService = ref.read(guidelineServiceProvider);
    final _investigationService = ref.read(investigationMasterServiceProvider);
    final _supplementationService = ref.read(supplimentMasterServiceProvider);
    final _clinicalService = ref.read(clinicalMasterServiceProvider); // Added clinical service
    final _habitService = ref.read(habitMasterServiceProvider); // Added habit service

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        builder: (_, controller) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setSheetState) {
              // Helper to sync state between sheet and parent
              void updateState(VoidCallback fn) {
                setSheetState(fn);
                setState(fn);
              }

              return Container(
                decoration: const BoxDecoration(color: Color(0xFFF8F9FE), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text("Plan Settings & Context", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // 1. Identity
                    _buildPremiumCard(
                        title: "Identity",
                        icon: Icons.badge,
                        color: Theme.of(context).colorScheme.primary,
                        child: Column(children: [_buildTextField("Plan Name", initialValue: _planName, onChanged: (v) => _planName = v), const SizedBox(height: 12), _buildTextField("Follow-up (Days)", initialValue: _followUpDays > 0 ? _followUpDays.toString() : "", isNumber: true, onChanged: (v) => _followUpDays = int.tryParse(v) ?? 0)])
                    ),

                    // 2. Lifestyle Goals (🎯 NEW)
                    _buildPremiumCard(
                        title: "Lifestyle Goals",
                        icon: Icons.track_changes,
                        color: Colors.green,
                        child: Column(
                          children: [
                            _buildSlider("Water", _waterGoal, 1.0, 5.0, 8, "${_waterGoal.toStringAsFixed(1)} L", Colors.blue, (v) => updateState(() => _waterGoal = v)),
                            _buildSlider("Sleep", _sleepGoal, 4.0, 10.0, 12, "${_sleepGoal.toStringAsFixed(1)} Hrs", Colors.deepPurple, (v) => updateState(() => _sleepGoal = v)),
                            _buildSlider("Steps", _stepGoal.toDouble(), 1000, 20000, 19, "$_stepGoal", Colors.orange, (v) => updateState(() => _stepGoal = v.toInt())),
                            _buildSlider("Mindfulness", _mindfulnessGoal.toDouble(), 0, 60, 6, "$_mindfulnessGoal Min", Colors.teal, (v) => updateState(() => _mindfulnessGoal = v.toInt())),

                            const Divider(height: 30),
                            _buildHabitSection(updateState, _habitService), // Pass service
                          ],
                        )
                    ),

                    // 3. Clinical Context (Existing)
                    _buildPremiumCard(
                        title: "Clinical Context",
                        icon: Icons.medical_services,
                        color: Colors.purple,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildVitalsLinker(updateState),
                            const Divider(height: 30),
                            // 🎯 FIX 1: Diagnosis Master
                            _buildMultiSelectWithChips<DiagnosisMasterModel>(context,
                                service: _diagonisService, // Pass service
                                title: "Diagnosis", selectedIds: _diagnosisIds, stream: _diagonisService.getDiagnoses(), getName: (d) => d.enName, getId: (d) => d.id,
                                // 🎯 FIX: ADD LOCALIZED NAMES TO ONADD/ONEDIT
                                onAdd: (name, localizedNames) async => await _diagonisService.addOrUpdateDiagnosis(DiagnosisMasterModel(id: '', enName: name, nameLocalized: localizedNames)),
                                onEdit: (item, name, localizedNames) async => await _diagonisService.addOrUpdateDiagnosis(item.copyWith(enName: name, nameLocalized: localizedNames)),
                                onDelete: (item) async => await _diagonisService.softDeleteDiagnosis(item.id),
                                onUpdate: (ids) => updateState(() => _diagnosisIds = ids),
                                nameResolver: (ids) => _diagonisService.fetchAllDiagnosisMasterByIds(ids).then((l) => l.map((e) => e.enName).toList())
                            ),
                            const SizedBox(height: 20),
                            // 🎯 FIX 2: Complaints Master
                            _buildStringMultiSelectWithChips(context,
                                service: _clinicalService, // Pass service
                                title: "Chief Complaints", selectedItems: _complaints, collection: ClinicalMasterService.colComplaints, onUpdate: (list) => updateState(() => _complaints = list)
                            ),
                            const SizedBox(height: 20),
                            // 🎯 FIX 3: Clinical Notes Master
                            _buildStringMultiSelectWithChips(context,
                                service: _clinicalService, // Pass service
                                title: "Clinical Notes", selectedItems: _clinicalNotes, collection: ClinicalMasterService.colClinicalNotes, onUpdate: (list) => updateState(() => _clinicalNotes = list)
                            ),
                          ],
                        )
                    ),

                    // 4. Protocols (Existing)
                    _buildPremiumCard(
                        title: "Protocols & Instructions",
                        icon: Icons.rule,
                        color: Colors.teal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMultiSelectWithChips<Guideline>(context,
                                service: _guidelineService, title: "Guidelines", selectedIds: _guidelineIds, stream: _guidelineService.streamAllActive(), getName: (g) => g.enTitle, getId: (g) => g.id,
                                // 🎯 FIX: ADD LOCALIZED NAMES
                                onAdd: (name, localizedNames) async => await _guidelineService.save(Guideline(id: '', enTitle: name, titleLocalized: localizedNames)),
                                onEdit: (item, name, localizedNames) async => await _guidelineService.save(item.copyWith(enTitle: name, titleLocalized: localizedNames)),
                                onDelete: (item) async => await _guidelineService.softDelete(item.id),
                                onUpdate: (ids) => updateState(() => _guidelineIds = ids),
                                nameResolver: (ids) => _guidelineService.fetchGuidelinesByIds(ids).then((l) => l.map((e) => e.enTitle).toList())
                            ),
                            const SizedBox(height: 20),
                            // 🎯 FIX 4: Investigation Master
                            _buildMultiSelectWithChips<InvestigationMasterModel>(context,
                                service: _investigationService, title: "Investigations", selectedIds: _investigationIds, stream: _investigationService.getInvestigation(), getName: (i) => i.enName, getId: (i) => i.id,
                                onAdd: (name, localizedNames) async => await _investigationService.addOrUpdateInvestigation(InvestigationMasterModel(id: '', enName: name, nameLocalized: localizedNames)),
                                onEdit: (item, name, localizedNames) async => await _investigationService.addOrUpdateInvestigation(item.copyWith(enName: name, nameLocalized: localizedNames)),
                                onDelete: (item) async => await _investigationService.softDeleteInvestigation(item.id),
                                onUpdate: (ids) => updateState(() => _investigationIds = ids),
                                nameResolver: (ids) => _investigationService.fetchAllInvestigationMasterByIds(ids).then((l) => l.map((e) => e.enName).toList())
                            ),
                            const SizedBox(height: 20),
                            // 🎯 FIX 5: Supplementation Master
                            _buildMultiSelectWithChips<SupplimentMasterModel>(context,
                                service: _supplementationService, title: "Supplements", selectedIds: _supplementIds, stream: _supplementationService.getSupplimentMaster(), getName: (s) => s.enName, getId: (s) => s.id,
                                onAdd: (name, localizedNames) async => await _supplementationService.addOrUpdateSupplimentMaster(SupplimentMasterModel(id: '', enName: name, nameLocalized: localizedNames)),
                                onEdit: (item, name, localizedNames) async => await _supplementationService.addOrUpdateSupplimentMaster(item.copyWith(enName: name, nameLocalized: localizedNames)),
                                onDelete: (item) async => await _supplementationService.softDeleteSupplimentMaster(item.id),
                                onUpdate: (ids) => updateState(() => _supplementIds = ids),
                                nameResolver: (ids) => _supplementationService.fetchAllSupplimentMasterMasterByIds(ids).then((l) => l.map((e) => e.enName).toList())
                            ),
                            const SizedBox(height: 20),
                            // 🎯 FIX 6: Client Instructions Master
                            _buildStringMultiSelectWithChips(context,
                                service: _clinicalService, // Pass service
                                title: "Client Instructions", selectedItems: _instructions, collection: ClinicalMasterService.colInstructions, onUpdate: (list) => updateState(() => _instructions = list)
                            ),
                          ],
                        )
                    ),

                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text("DONE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            }
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  // 🎯 Slider Helper
  Widget _buildSlider(String label, double val, double min, double max, int divs, String displayVal, Color color, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            Text(displayVal, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        Slider(value: val, min: min, max: max, divisions: divs, activeColor: color, label: displayVal, onChanged: onChanged),
      ],
    );
  }

  // 🎯 Habit Section
  Widget _buildHabitSection(Function(VoidCallback) updateState, HabitMasterService habitService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Daily Habits", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            InkWell(
              onTap: () async {
                final result = await showModalBottomSheet<List<String>>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => PremiumHabitSelectSheet(initialSelectedIds: _assignedHabitIds),
                );
                if (result != null) {
                  updateState(() => _assignedHabitIds = result);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                child: const Text("Manage Habits", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_assignedHabitIds.isEmpty)
          const Text("No habits assigned.", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic))
        else
          StreamBuilder<List<HabitMasterModel>>(
            stream: habitService.streamActiveHabits(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              // Filter locally for speed
              final allHabits = snapshot.data!;
              final selectedHabits = allHabits.where((h) => _assignedHabitIds.contains(h.id)).toList();

              return Wrap(
                spacing: 8, runSpacing: 8,
                children: selectedHabits.map((habit) => Chip(
                  label: Text(habit.title, style: const TextStyle(fontSize: 11)),
                  avatar: Icon(habit.iconData, size: 14, color: Colors.white),
                  backgroundColor: Colors.teal,
                  labelStyle: const TextStyle(color: Colors.white),
                  deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white70),
                  onDeleted: () => updateState(() => _assignedHabitIds.remove(habit.id)),
                )).toList(),
              );
            },
          )
      ],
    );
  }

  // 🎯 Vitals Linker
  Widget _buildVitalsLinker(Function(VoidCallback) updateState) {
    String dateStr = _linkedVitals != null ? DateFormat('dd MMM').format(_linkedVitals!.date) : "";
    String detailStr = _linkedVitals != null ? "${_linkedVitals!.weightKg}kg | BMI ${_linkedVitals!.bmi.toStringAsFixed(1)}" : "Select a record to link clinical data";
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(_linkedVitals == null ? "Link Vitals Record" : "Vitals: $dateStr", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(detailStr, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blueGrey),
      onTap: () async {
        final result = await showModalBottomSheet<VitalsModel>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => VitalsPickerSheet(clientId: widget.initialPlan?.clientId ?? "", selectedId: _linkedVitals?.id),
        );
        if (result != null) {
          updateState(() => _linkedVitals = result);
        }
      },
    );
  }

  // 🎯 Multi-Select (Generic Master Data)
  Widget _buildMultiSelectWithChips<T>(
      BuildContext context, {
        required dynamic service, // Placeholder for service instance
        required String title,
        required List<String> selectedIds,
        required Stream<List<T>> stream,
        required String Function(T) getName,
        required String Function(T) getId,
        // 🎯 FIX: Updated signature to accept localized map
        required Future<void> Function(String name, Map<String, String> localizedNames) onAdd,
        required Future<void> Function(T item, String newName, Map<String, String> localizedNames) onEdit,
        required Future<void> Function(T item) onDelete,
        required Function(List<String>) onUpdate,
        required Future<List<String>> Function(List<String>) nameResolver,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            InkWell(
              onTap: () async {
                final result = await showModalBottomSheet<List<String>>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => PremiumMasterSelectSheet<T>(
                    title: "Select $title", itemLabel: title, stream: stream,
                    getName: getName, getId: getId, onAdd: onAdd, onEdit: onEdit, onDelete: onDelete, selectedIds: selectedIds,
                  ),
                );
                if (result != null) onUpdate(result);
              },
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.1), borderRadius: BorderRadius.circular(20)), child: Text("Edit / Add", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (selectedIds.isEmpty)
          const Text("None selected", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13))
        else
          FutureBuilder<List<String>>(
            future: nameResolver(selectedIds),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2));
              final names = snapshot.data!;
              return Wrap(
                spacing: 8, runSpacing: 8,
                children: names.asMap().entries.map((entry) {
                  final id = selectedIds[entry.key];
                  return Chip(
                    label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                    onDeleted: () => onUpdate(List.from(selectedIds)..remove(id)),
                    backgroundColor: Colors.white, elevation: 1, side: BorderSide(color: Colors.grey.shade200),
                    deleteIcon: const Icon(Icons.close, size: 14, color: Colors.grey),
                  );
                }).toList(),
              );
            },
          )
      ],
    );
  }

  // 🎯 String Multi-Select (Clinical Masters like Complaints/Notes)
  Widget _buildStringMultiSelectWithChips(BuildContext context, {required ClinicalMasterService service, required String title, required List<String> selectedItems, required String collection, required Function(List<String>) onUpdate}) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            InkWell(
              onTap: () async {
                final result = await showModalBottomSheet<List<String>>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => PremiumMasterSelectSheet<ClinicalItemModel>(
                    title: "Select $title", itemLabel: title, stream: service.streamActiveItems(collection),
                    getName: (c) => c.name, getId: (c) => c.name,

                    // 🎯 FIX ERROR 3 & 4: Correctly handle three arguments
                    onAdd: (name, localizedNames) async => await service.addItem(collection, name, localizedNames),
                    onEdit: (item, name, localizedNames) async => await service.saveItem(collection, item.copyWith(name: name, nameLocalized: localizedNames)),

                    onDelete: (item) async => await service.deleteItem(collection, item.id),
                    selectedIds: selectedItems,
                  ),
                );
                if (result != null) onUpdate(result);
              },
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.1), borderRadius: BorderRadius.circular(20)), child: Text("Edit / Add", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (selectedItems.isEmpty)
          const Text("None selected", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13))
        else
          Wrap(
            spacing: 8, runSpacing: 8,
            children: selectedItems.map((item) => Chip(
              label: Text(item, style: const TextStyle(fontSize: 12)),
              onDeleted: () => onUpdate(List.from(selectedItems)..remove(item)),
              backgroundColor: Colors.white, elevation: 1, side: BorderSide(color: Colors.grey.shade200),
              deleteIcon: const Icon(Icons.close, size: 14, color: Colors.grey),
            )).toList(),
          )
      ],
    );
  }

  Future<void> _savePlan() async {

    if (_planName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please set a Plan Name in settings.")));
      _openSettingsSheet();
      return;
    }
    setState(() => _isSaving = true);

    final finalPlan = _currentPlan.copyWith(
      id: widget.planId ?? _currentPlan.id,
      name: _planName,
      diagnosisIds: _diagnosisIds,
      guidelineIds: _guidelineIds,
      linkedVitalsId: _linkedVitals?.id,
      suplimentIds: _supplementIds,
      investigationIds: _investigationIds,
      instructions: _instructions.join('\n'),
      clinicalNotes: _clinicalNotes.join('\n'),
      complaints: _complaints.join(', '),
      followUpDays: _followUpDays,
      isProvisional: _isProvisional,
      // 🎯 SAVE GOALS
      dailyWaterGoal: _waterGoal,
      dailySleepGoal: _sleepGoal,
      dailyStepGoal: _stepGoal,
      dailyMindfulnessMinutes: _mindfulnessGoal,
      assignedHabitIds: _assignedHabitIds,
    );

    try {
      final  _clientDietPlanService = ref.watch(clientDietPlanServiceProvider);
      await _clientDietPlanService.savePlan(finalPlan);
      widget.onMealPlanSaved();
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plan saved!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _updateMealItems(String mealId, List<DietPlanItemModel> newItems) {
    setState(() {
      final day = _currentPlan.days.first;
      final mealIndex = day.meals.indexWhere((m) => m.id == mealId);
      if (mealIndex == -1) return;
      final updatedMeals = List<DietPlanMealModel>.from(day.meals);
      updatedMeals[mealIndex] = updatedMeals[mealIndex].copyWith(items: newItems);
      _currentPlan = _currentPlan.copyWith(days: [day.copyWith(meals: updatedMeals)]);
    });
  }

  Widget _buildTextField(String label, {String? initialValue, Function(String)? onChanged, bool isNumber = false}) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
    );
  }

  Widget _buildPremiumCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))], border: Border.all(color: color.withOpacity(0.1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 12), Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
  // ... Build Method (Same as previous, just ensuring it's clear this is the full file logic) ...
// ... [Existing Imports] ...
// Make sure to import: import 'dart:ui';

// ... [State Class] ...
  // Replace Scaffold contents with this structure:
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          if (_isLoadingData) const Center(child: CircularProgressIndicator()) else SafeArea(
            child: Column(
              children: [
                // 1. HEADER
                _buildHeader(context),

                // 2. CONTENT
                Expanded(
                  child: Column(
                    children: [
                      // Summary Card
                      GestureDetector(
                        onTap: _openSettingsSheet,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_planName.isEmpty ? "Setup Plan" : _planName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text(_linkedVitals != null ? "Vitals Linked" : "No Vitals", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                              Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                            ],
                          ),
                        ),
                      ),

                      // Tabs
                      if (_tabController != null)
                        Container(
                          height: 40, margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: TabBar(
                            controller: _tabController, isScrollable: true,
                            indicator: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(20)),
                            labelColor: Colors.white, unselectedLabelColor: Colors.grey,
                            tabs: _currentPlan.days.first.meals.map((m) => Tab(text: m.mealName)).toList(),
                          ),
                        ),

                      const SizedBox(height: 10),

                      // List
                      if (_tabController != null)
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: _currentPlan.days.first.meals.map((meal) => PremiumMealEntryList(
                              meal: meal, allFoodItems: _allFoodItems, onUpdate: (items) => _updateMealItems(meal.id, items),
                            )).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white.withOpacity(0.8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back)),
              const Text("Diet Planner", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text(_isProvisional ? "Draft" : "Final", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _isProvisional ? Colors.orange : Colors.green)),
                  Switch(value: !_isProvisional, onChanged: (v) => setState(() => _isProvisional = !v), activeColor: Colors.green),
                  IconButton(onPressed: _isSaving ? null : _savePlan, icon: _isSaving ? const CircularProgressIndicator() : Icon(Icons.save, color: Theme.of(context).colorScheme.primary))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
// ...
}