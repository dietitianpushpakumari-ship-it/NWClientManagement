import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

// 🎯 WIDGETS
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_master_service.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_model.dart';
import 'package:nutricare_client_management/admin/labvital/premium_habit_select_sheet.dart';
import 'package:nutricare_client_management/admin/labvital/premium_master_select_sheet.dart';
import 'package:nutricare_client_management/admin/labvital/premium_master_select_sheet.dart';
import 'package:nutricare_client_management/admin/labvital/vitals_picker_sheet.dart';

// 🎯 MODELS & SERVICES
// ... (Keep existing imports) ...
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/screen/premium_meal_entry_list.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/modules/master/model/food_item.dart';
import 'package:nutricare_client_management/modules/master/model/meal_master_name.dart';
import 'package:nutricare_client_management/modules/master/model/diagonosis_master.dart';
import 'package:nutricare_client_management/modules/master/model/guidelines.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_model.dart';
import 'package:nutricare_client_management/modules/client/screen/suppliment_master_model.dart';
import 'package:nutricare_client_management/admin/habit_master_model.dart'; // 🎯
import 'package:nutricare_client_management/admin/habit_master_service.dart'; // 🎯

import 'package:nutricare_client_management/modules/client/services/client_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/modules/master/service/food_item_service.dart';
import 'package:nutricare_client_management/modules/master/service/master_meal_name_service.dart';
import 'package:nutricare_client_management/modules/master/service/diagonosis_master_service.dart';
import 'package:nutricare_client_management/modules/master/service/guideline_service.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_service.dart';
import 'package:nutricare_client_management/modules/client/screen/Suppliment_master_service.dart';


extension IterableExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class ClientDietPlanEntryPage extends StatefulWidget {
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
  State<ClientDietPlanEntryPage> createState() => _ClientDietPlanEntryPageState();
}

class _ClientDietPlanEntryPageState extends State<ClientDietPlanEntryPage> with TickerProviderStateMixin {
  final Logger logger = Logger();
  final ClinicalMasterService _clinicalService = ClinicalMasterService();

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
    final foods = await FoodItemService().fetchAllActiveFoodItems();
    final meals = await MasterMealNameService().fetchAllMealNames();
    meals.sort((a, b) => (a.startTime ?? "").compareTo(b.startTime ?? ""));

    ClientDietPlanModel plan;
    if (widget.planId != null) {
      plan = await ClientDietPlanService().fetchPlanById(widget.planId!);
    } else if (widget.initialPlan != null) {
      plan = widget.initialPlan!;
    } else {
      final initialMeals = meals.map((m) => DietPlanMealModel(id: m.id, mealNameId: m.id, mealName: m.enName, items: [], order: m.order)).toList();
      plan = ClientDietPlanModel(days: [MasterDayPlanModel(id: 'd1', dayName: 'Fixed Day', meals: initialMeals)]);
    }

    VitalsModel? loadedVitals;
    if (plan.linkedVitalsId != null && plan.linkedVitalsId!.isNotEmpty && plan.clientId.isNotEmpty) {
      try {
        final allVitals = await VitalsService().getClientVitals(plan.clientId);
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
                        color: Colors.indigo,
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
                            _buildHabitSection(updateState),
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
                            _buildMultiSelectWithChips<DiagnosisMasterModel>(context, title: "Diagnosis", selectedIds: _diagnosisIds, stream: DiagnosisMasterService().getDiagnoses(), getName: (d) => d.enName, getId: (d) => d.id, onAdd: (name) async => await DiagnosisMasterService().addOrUpdateDiagnosis(DiagnosisMasterModel(id: '', enName: name)), onEdit: (item, name) async => await DiagnosisMasterService().addOrUpdateDiagnosis(item.copyWith(enName: name)), onDelete: (item) async => await DiagnosisMasterService().softDeleteDiagnosis(item.id), onUpdate: (ids) => updateState(() => _diagnosisIds = ids), nameResolver: (ids) => DiagnosisMasterService().fetchAllDiagnosisMasterByIds(ids).then((l) => l.map((e) => e.enName).toList())),
                            const SizedBox(height: 20),
                            _buildStringMultiSelectWithChips(context, title: "Chief Complaints", selectedItems: _complaints, collection: ClinicalMasterService.colComplaints, onUpdate: (list) => updateState(() => _complaints = list)),
                            const SizedBox(height: 20),
                            _buildStringMultiSelectWithChips(context, title: "Clinical Notes", selectedItems: _clinicalNotes, collection: ClinicalMasterService.colClinicalNotes, onUpdate: (list) => updateState(() => _clinicalNotes = list)),
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
                            _buildMultiSelectWithChips<Guideline>(context, title: "Guidelines", selectedIds: _guidelineIds, stream: GuidelineService().streamAllActive(), getName: (g) => g.enTitle, getId: (g) => g.id, onAdd: (name) async => await GuidelineService().save(Guideline(id: '', enTitle: name)), onEdit: (item, name) async => await GuidelineService().save(item.copyWith(enTitle: name)), onDelete: (item) async => await GuidelineService().softDelete(item.id), onUpdate: (ids) => updateState(() => _guidelineIds = ids), nameResolver: (ids) => GuidelineService().fetchGuidelinesByIds(ids).then((l) => l.map((e) => e.enTitle).toList())),
                            const SizedBox(height: 20),
                            _buildMultiSelectWithChips<InvestigationMasterModel>(context, title: "Investigations", selectedIds: _investigationIds, stream: InvestigationMasterService().getInvestigation(), getName: (i) => i.enName, getId: (i) => i.id, onAdd: (name) async => await InvestigationMasterService().addOrUpdateInvestigation(InvestigationMasterModel(id: '', enName: name)), onEdit: (item, name) async => await InvestigationMasterService().addOrUpdateInvestigation(item.copyWith(enName: name)), onDelete: (item) async => await InvestigationMasterService().softDeleteInvestigation(item.id), onUpdate: (ids) => updateState(() => _investigationIds = ids), nameResolver: (ids) => InvestigationMasterService().fetchAllInvestigationMasterByIds(ids).then((l) => l.map((e) => e.enName).toList())),
                            const SizedBox(height: 20),
                            _buildMultiSelectWithChips<SupplimentMasterModel>(context, title: "Supplements", selectedIds: _supplementIds, stream: SupplimentMasterService().getSupplimentMaster(), getName: (s) => s.enName, getId: (s) => s.id, onAdd: (name) async => await SupplimentMasterService().addOrUpdateSupplimentMaster(SupplimentMasterModel(id: '', enName: name)), onEdit: (item, name) async => await SupplimentMasterService().addOrUpdateSupplimentMaster(item.copyWith(enName: name)), onDelete: (item) async => await SupplimentMasterService().softDeleteSupplimentMaster(item.id), onUpdate: (ids) => updateState(() => _supplementIds = ids), nameResolver: (ids) => SupplimentMasterService().fetchAllSupplimentMasterMasterByIds(ids).then((l) => l.map((e) => e.enName).toList())),
                            const SizedBox(height: 20),
                            _buildStringMultiSelectWithChips(context, title: "Client Instructions", selectedItems: _instructions, collection: ClinicalMasterService.colInstructions, onUpdate: (list) => updateState(() => _instructions = list)),
                          ],
                        )
                    ),

                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
  Widget _buildHabitSection(Function(VoidCallback) updateState) {
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
            stream: HabitMasterService().streamAllHabits(),
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

  // ... (Other Helpers: _buildVitalsLinker, _buildMultiSelectWithChips, etc. same as previous)
  // I will include them briefly to ensure the file is complete.

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

  Widget _buildMultiSelectWithChips<T>(
      BuildContext context, {
        required String title,
        required List<String> selectedIds,
        required Stream<List<T>> stream,
        required String Function(T) getName,
        required String Function(T) getId,
        required Future<void> Function(String) onAdd,
        required Future<void> Function(T, String) onEdit,
        required Future<void> Function(T) onDelete,
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
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(20)), child: const Text("Edit / Add", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo))),
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

  Widget _buildStringMultiSelectWithChips(BuildContext context, {required String title, required List<String> selectedItems, required String collection, required Function(List<String>) onUpdate}) {
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
                    title: "Select $title", itemLabel: title, stream: _clinicalService.streamActiveItems(collection),
                    getName: (c) => c.name, getId: (c) => c.name,
                    onAdd: (name) async => await _clinicalService.addItem(collection, name),
                    onEdit: (item, name) async => await _clinicalService.saveItem(collection, ClinicalItemModel(id: item.id, name: name)),
                    onDelete: (item) async => await _clinicalService.deleteItem(collection, item.id),
                    selectedIds: selectedItems,
                  ),
                );
                if (result != null) onUpdate(result);
              },
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(20)), child: const Text("Edit / Add", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo))),
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
      await ClientDietPlanService().savePlan(finalPlan);
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
  @override
  Widget build(BuildContext context) {
    // ... (Standard Scaffold with Stack logic) ...
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 80, spreadRadius: 20)]))),
          if (_isLoadingData) const Center(child: CircularProgressIndicator()) else SafeArea(
            child: Column(
              children: [
                // ... Header ...
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]), child: const Icon(Icons.arrow_back, size: 20))),
                      const Text("Diet Planner", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                      Row(children: [
                        Transform.scale(scale: 0.8, child: Switch(value: !_isProvisional, onChanged: (v) => setState(() => _isProvisional = !v), activeColor: Colors.green, inactiveThumbColor: Colors.amber)),
                        Text(!_isProvisional ? "Final" : "Draft", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: !_isProvisional ? Colors.green : Colors.amber.shade800)),
                        const SizedBox(width: 12),
                        ElevatedButton(onPressed: _isSaving ? null : _savePlan, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)), child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
                      ])
                    ],
                  ),
                ),
                // Summary Card
                GestureDetector(
                  onTap: _openSettingsSheet,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)], border: Border.all(color: Colors.indigo.withOpacity(0.1))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_planName.isEmpty ? "Tap to Setup Plan" : _planName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.monitor_heart, size: 14, color: _linkedVitals != null ? Colors.green : Colors.orange),
                              const SizedBox(width: 4),
                              Text(_linkedVitals != null ? "Vitals Linked" : "Missing Vitals", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ]),
                          ],
                        ),
                        const Icon(Icons.settings, color: Colors.indigo),
                      ],
                    ),
                  ),
                ),

                // Tabs
                Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicator: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(20)),
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: _currentPlan.days.first.meals.map((m) => Tab(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(m.mealName)))).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _currentPlan.days.first.meals.map((meal) {
                      return PremiumMealEntryList(
                        meal: meal,
                        allFoodItems: _allFoodItems,
                        onUpdate: (items) => _updateMealItems(meal.id, items),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}