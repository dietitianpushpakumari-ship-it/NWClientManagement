import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
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
  static const List<String> _dosageOptions = [
    '1-0-1 (Morning & Night)', '1-1-1 (Thrice a day)', '0-0-1 (Night only)',
    '1-0-0 (Morning only)', '1-1-0 (Morning & Afternoon)', 'Once a week', 'SOS (As needed)'
  ];

  static const List<String> _timingOptions = ['AF (After Food)', 'BF (Before Food)', 'Empty Stomach', 'Bedtime'];

  final Logger logger = Logger();
  TabController? _tabController; // For Meals
  TabController? _dayTabController; // For Days (Weekly)

  bool _isSaving = false;
  bool _isLoadingData = true;

  String _planName = '';
  VitalsModel? _linkedVitals;
  List<String> _guidelineIds = [];
  Map<String, String> _supplementDosages = {};
  List<String> _investigationIds = [];
  int _followUpDays = 0;
  bool _isProvisional = false;

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
    meals.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    ClientDietPlanModel plan;
    if (widget.planId != null) {
      plan = await clientDietPlanService.fetchPlanById(widget.planId!);
    } else if (widget.initialPlan != null) {
      plan = widget.initialPlan!;
    } else {
      // Fallback
      final initialMeals = meals.map((m) => DietPlanMealModel(id: m.id, mealNameId: m.id, mealName: m.name, items: [], order: m.order)).toList();
      plan = ClientDietPlanModel(days: [MasterDayPlanModel(id: 'd1', dayName: 'Fixed Day', meals: initialMeals)]);
    }

    final updatedDays = plan.days.map((day) {
      final sortedMeals = List<DietPlanMealModel>.from(day.meals);
      sortedMeals.sort((a, b) {
        final orderA = meals.firstWhereOrNull((m) => m.id == a.mealNameId)?.order ?? 99;
        final orderB = meals.firstWhereOrNull((m) => m.id == b.mealNameId)?.order ?? 99;
        return orderA.compareTo(orderB);
      });
      return day.copyWith(meals: sortedMeals);
    }).toList();

    plan = plan.copyWith(days: updatedDays);

    if (mounted) {
      setState(() {
        _allFoodItems = foods;
        _allMealNames = meals;
        _currentPlan = plan;
        _planName = plan.name;
        _guidelineIds = List.from(plan.guidelineIds);
        _supplementDosages = Map<String, String>.from(plan.suplimentIdsMap ?? {});
        _investigationIds = List.from(plan.investigationIds);
        _followUpDays = plan.followUpDays ?? 0;
        _isProvisional = plan.isProvisional;
        _waterGoal = plan.dailyWaterGoal;
        _sleepGoal = plan.dailySleepGoal;
        _stepGoal = plan.dailyStepGoal;
        _mindfulnessGoal = plan.dailyMindfulnessMinutes;
        _assignedHabitIds = List.from(plan.assignedHabitIds);

        // 🎯 Initialize Day Tab Controller for Weekly Plans
        if (_currentPlan.days.length > 1) {
          _dayTabController = TabController(length: _currentPlan.days.length, vsync: this);
          _dayTabController!.addListener(() {
            if (!_dayTabController!.indexIsChanging) setState(() {});
          });
        }

        // 🎯 Initialize Meal Tab Controller
        if (_currentPlan.days.isNotEmpty) {
          _tabController = TabController(length: _currentPlan.days.first.meals.length, vsync: this);
        }

        _isLoadingData = false;
      });
    }
  }

  void _updateMealItems(String mealId, List<DietPlanItemModel> newItems) {
    setState(() {
      final int currentDayIndex = _dayTabController?.index ?? 0;
      final day = _currentPlan.days[currentDayIndex];
      final mealIndex = day.meals.indexWhere((m) => m.id == mealId);

      if (mealIndex == -1) return;

      final updatedMeals = List<DietPlanMealModel>.from(day.meals);
      updatedMeals[mealIndex] = updatedMeals[mealIndex].copyWith(items: newItems);

      final updatedDays = List<MasterDayPlanModel>.from(_currentPlan.days);
      updatedDays[currentDayIndex] = day.copyWith(meals: updatedMeals);

      _currentPlan = _currentPlan.copyWith(days: updatedDays);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData || _currentPlan.days.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isWeekly = _currentPlan.days.length == 7;
    final int currentDayIndex = _dayTabController?.index ?? 0;
    final currentDayMeals = _currentPlan.days[currentDayIndex].meals;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSummarySelector(),
            if (isWeekly && _dayTabController != null)
              TabBar(
                controller: _dayTabController,
                isScrollable: true,
                labelColor: Colors.teal,
                indicatorColor: Colors.teal,
                tabs: _currentPlan.days.map((d) => Tab(text: d.dayName)).toList(),
              ),
            if (_tabController != null)
              Container(
                height: 45,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicator: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(20)),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: currentDayMeals.map((m) => Tab(text: m.mealName)).toList(),
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: currentDayMeals.map((meal) => PremiumMealEntryList(
                  meal: meal,
                  allFoodItems: _allFoodItems,
                  onUpdate: (items) => _updateMealItems(meal.id, items),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          const Text("Diet Planner", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(
            icon: _isSaving ? const CircularProgressIndicator() : const Icon(Icons.save, color: Colors.indigo),
            onPressed: _isSaving ? null : _savePlan,
          )
        ],
      ),
    );
  }

  Widget _buildSummarySelector() {
    return GestureDetector(
      onTap: _openSettingsSheet,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_planName.isEmpty ? "Untitled Plan" : _planName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text("Tap to edit goals & clinical notes", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const Icon(Icons.settings, color: Colors.indigo),
          ],
        ),
      ),
    );
  }

  // ... [Keep your existing _openSettingsSheet and helper methods from current code] ...

  Future<void> _savePlan() async {
    if (_planName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please set a Plan Name in settings.")));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updatedPlan = _currentPlan.copyWith(
        name: _planName,
        dailyWaterGoal: _waterGoal,
        dailySleepGoal: _sleepGoal,
        dailyStepGoal: _stepGoal,
        dailyMindfulnessMinutes: _mindfulnessGoal,
        assignedHabitIds: _assignedHabitIds,
        suplimentIdsMap: _supplementDosages,
        guidelineIds: _guidelineIds,
        investigationIds: _investigationIds,
        followUpDays: _followUpDays,
        isProvisional: _isProvisional,
      );
      await ref.read(clientDietPlanServiceProvider).savePlan(updatedPlan);
      widget.onMealPlanSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      logger.e("Save failed: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
      isDismissible: false,
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

                    // 4. Protocols (Existing)
                    _buildPremiumCard(
                        title: "Protocols & Instructions",
                        icon: Icons.rule,
                        color: Colors.teal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMultiSelectWithChips<Guideline>(context,
                                service: _guidelineService, title: "Guidelines", selectedIds: _guidelineIds, stream: _guidelineService.streamAllActive(), getName: (g) => g.name, getId: (g) => g.id,
                                // 🎯 FIX: ADD LOCALIZED NAMES
                                onAdd: (name, localizedNames) async => await _guidelineService.save(Guideline(id: '', name: name, nameLocalized: localizedNames)),
                                onEdit: (item, name, localizedNames) async => await _guidelineService.save(item.copyWith(name: name, nameLocalized: localizedNames)),
                                onDelete: (item) async => await _guidelineService.softDelete(item.id),
                                onUpdate: (ids) => updateState(() => _guidelineIds = ids),
                                nameResolver: (ids) => _guidelineService.fetchGuidelinesByIds(ids).then((l) => l.map((e) => e.name).toList())
                            ),
                            const SizedBox(height: 20),
                            // 🎯 FIX 4: Investigation Masterin
                            _buildMultiSelectWithChips<InvestigationMasterModel>(context,
                                service: _investigationService, title: "Investigations", selectedIds: _investigationIds, stream: _investigationService.getInvestigation(), getName: (i) => i.name, getId: (i) => i.id,
                                onAdd: (name, localizedNames) async => await _investigationService.addOrUpdateInvestigation(InvestigationMasterModel(id: '', name: name, nameLocalized: localizedNames)),
                                onEdit: (item, name, localizedNames) async => await _investigationService.addOrUpdateInvestigation(item.copyWith(name: name, nameLocalized: localizedNames)),
                                onDelete: (item) async => await _investigationService.softDeleteInvestigation(item.id),
                                onUpdate: (ids) => updateState(() => _investigationIds = ids),
                                nameResolver: (ids) => _investigationService.fetchAllInvestigationMasterByIds(ids).then((l) => l.map((e) => e.name).toList())
                            ),
                            const SizedBox(height: 20),
                            _buildSupplementSection(updateState, _supplementationService),
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
  Widget _buildTextField(String label, {String? initialValue, Function(String)? onChanged, bool isNumber = false}) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
    );
  }
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
                  label: Text(habit.name, style: const TextStyle(fontSize: 11)),
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
              if (!snapshot.hasData)
                return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2));
              final names = snapshot.data!;
              if (names.length != selectedIds.length) {
                return const SizedBox(); // Return empty while syncing
              }
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
  Widget _buildSupplementSection(Function(VoidCallback) updateState, dynamic service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Supplements & Dosage", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            InkWell(
              onTap: () async {
                final result = await showModalBottomSheet<List<String>>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => PremiumMasterSelectSheet<SupplimentMasterModel>(
                    title: "Select Supplements",
                    itemLabel: "Supplement",
                    stream: service.getSupplimentMaster(),
                    getName: (s) => s.name,
                    getId: (s) => s.id,
                    selectedIds: _supplementDosages.keys.toList(),
                    onAdd: (name, loc) async => await service.addOrUpdateSupplimentMaster(SupplimentMasterModel(id: '', name: name, nameLocalized: loc)),
                    onEdit: (item, name, loc) async => await service.addOrUpdateSupplimentMaster(item.copyWith(name: name, nameLocalized: loc)),
                    onDelete: (item) async => await service.softDeleteSupplimentMaster(item.id),
                  ),
                );
                if (result != null) {
                  updateState(() {
                    // Keep existing dosages for items still selected, add new ones as empty
                    Map<String, String> newMap = {};
                    for (var id in result) {
                      newMap[id] = _supplementDosages[id] ?? "";
                    }
                    _supplementDosages = newMap;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.indigo.withOpacity(.1), borderRadius: BorderRadius.circular(20)),
                child: const Text("Edit / Add", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_supplementDosages.isEmpty)
          const Text("None selected", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13))
        else
          FutureBuilder<List<SupplimentMasterModel>>(
            future: service.fetchAllSupplimentMasterMasterByIds(_supplementDosages.keys.toList()),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              return Column(
                children: snapshot.data!.map((item) {
                  // Parse the stored value: "Pattern | Timing"
                  final currentVal = _supplementDosages[item.id] ?? "";
                  final parts = currentVal.split(" | ");

                  // Default to standard patterns if data is missing
                  String currentPattern = parts.isNotEmpty && _dosageOptions.contains(parts[0])
                      ? parts[0]
                      : _dosageOptions[0]; // Default: 1-0-1

                  String currentTiming = parts.length > 1 && _timingOptions.contains(parts[1])
                      ? parts[1]
                      : _timingOptions[0]; // Default: AF

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // 🎯 Dropdown 1: Pattern (1-0-1, etc.)
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: currentPattern,
                                decoration: _inputDec("Frequency", Icons.medication),
                                items: _dosageOptions.map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v, style: const TextStyle(fontSize: 12))
                                )).toList(),
                                onChanged: (val) => updateState(() {
                                  _supplementDosages[item.id] = "$val | $currentTiming";
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 🎯 Dropdown 2: Meal Timing (BF/AF)
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: currentTiming,
                                decoration: _inputDec("Timing", Icons.restaurant),
                                items: _timingOptions.map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v, style: const TextStyle(fontSize: 12))
                                )).toList(),
                                onChanged: (val) => updateState(() {
                                  _supplementDosages[item.id] = "$currentPattern | $val";
                                }),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                              onPressed: () => updateState(() => _supplementDosages.remove(item.id)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
    );
  }
}