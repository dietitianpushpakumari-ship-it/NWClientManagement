import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:nutricare_client_management/admin/admin_provider.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/diet_plan_editor.dart';
import 'package:nutricare_client_management/admin/generic_master_model.dart';
import 'package:nutricare_client_management/admin/generic_service.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/labvital/premium_habit_select_sheet.dart';
import 'package:nutricare_client_management/helper/diet_plan_pdf_generator.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/master/model/food_item.dart';
import 'package:nutricare_client_management/master/model/meal_master_name.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:printing/printing.dart';

class ClientDietPlanEntryPage extends ConsumerStatefulWidget {
  final String? planId;
  final ClientDietPlanModel? initialPlan;
  final VoidCallback onMealPlanSaved;
  final String? sessionId;

  const ClientDietPlanEntryPage({
    super.key,
    this.planId,
    this.initialPlan,
    required this.onMealPlanSaved,
    this.sessionId,
  });

  @override
  ConsumerState<ClientDietPlanEntryPage> createState() => _ClientDietPlanEntryPageState();
}

class _ClientDietPlanEntryPageState extends ConsumerState<ClientDietPlanEntryPage> {
  final Logger logger = Logger();

  bool _isSaving = false;
  bool _isLoadingData = true;

  // --- Client Specific State ---
  double _targetCalories = 1800;
  String _dietType = 'Balanced';
  bool _isProvisional = false;

  double _waterGoal = 3.0;
  double _sleepGoal = 7.5;
  int _stepGoal = 8000;
  int _mindfulnessGoal = 15;
  List<String> _assignedHabitIds = [];

  ClientDietPlanModel _currentPlan = const ClientDietPlanModel();
  List<FoodItem> _allFoodItems = [];

  // 🎯 FIX 1: Add this missing variable
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

    // Sort meals by order to ensure tabs appear correctly
    meals.sort((a, b) => (a.order).compareTo(b.order));

    ClientDietPlanModel plan;
    if (widget.planId != null) {
      plan = await clientDietPlanService.fetchPlanById(widget.planId!);
    } else if (widget.initialPlan != null) {
      plan = widget.initialPlan!;
    } else {
      // Default / Fallback Plan
      final initialMeals = meals.map((m) => DietPlanMealModel(id: m.id, mealNameId: m.id, mealName: m.name, items: [], order: m.order)).toList();
      plan = ClientDietPlanModel(days: [MasterDayPlanModel(id: 'd1', dayName: 'Fixed Day', meals: initialMeals)]);
    }

    // Sort meals within the plan to match master order
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
        _allMealNames = meals; // 🎯 FIX 2: Populate the list
        _currentPlan = plan;

        // Initialize Client-Specific Fields
        _targetCalories = plan.targetCalories ?? 1800;
        _dietType = plan.dietType ?? 'Balanced';
        _isProvisional = plan.isProvisional;
        _waterGoal = plan.dailyWaterGoal;
        _sleepGoal = plan.dailySleepGoal;
        _stepGoal = plan.dailyStepGoal;
        _mindfulnessGoal = plan.dailyMindfulnessMinutes;
        _assignedHabitIds = List.from(plan.assignedHabitIds);

        _isLoadingData = false;
      });
    }
  }

  // --- SAVE & PRINT LOGIC ---

  ClientDietPlanModel _preparePlanForSave() {
    return _currentPlan.copyWith(
      targetCalories: _targetCalories,
      dietType: _dietType,
      dailyWaterGoal: _waterGoal,
      dailySleepGoal: _sleepGoal,
      dailyStepGoal: _stepGoal,
      dailyMindfulnessMinutes: _mindfulnessGoal,
      assignedHabitIds: _assignedHabitIds,
      isProvisional: _isProvisional,
    );
  }

  Future<void> _saveAndPrint() async {
    final success = await _savePlan(closeOnSuccess: false);
    if (!success) return;

    setState(() => _isSaving = true);

    try {
      final clientService = ref.read(clientServiceProvider);
      final vitalsService = ref.read(vitalsServiceProvider);
      final adminService = ref.read(adminProfileServiceProvider);

      final client = await clientService.getClientById(_currentPlan.clientId);
      if (client == null) throw "Client data not found";

      VitalsModel? vitals;
      if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
        vitals = await vitalsService.getVitalsBySessionId(widget.sessionId!);
      }
      vitals ??= await vitalsService.getLatestVitals(_currentPlan.clientId);

      // Safety Fallback
      vitals ??= VitalsModel(
          id: 'temp', clientId: _currentPlan.clientId,
          date: DateTime.now(), heightCm: 0, weightKg: 0,
          bodyFatPercentage: 0, isFirstConsultation: false
      );

      final adminProfile = await adminService.fetchAdminProfile();
      if (adminProfile == null) throw "Dietitian profile not found";

      final pdfBytes = await DietPlanPdfGenerator.generatePlanPdf(
        clientPlan: _preparePlanForSave(),
        vitals: vitals,
        client: client,
        dietitianProfile: adminProfile,
        ref: ref,
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: 'Diet_Plan_${client.name}.pdf',
      );

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Print Failed: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _savePlan({bool closeOnSuccess = true}) async {
    setState(() => _isSaving = true);
    try {
      final updatedPlan = _preparePlanForSave();
      await ref.read(clientDietPlanServiceProvider).savePlan(updatedPlan);

      if (widget.sessionId != null) {
        await ref.read(firestoreProvider).collection('consultation_sessions').doc(widget.sessionId).update({
          'steps.diet': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      widget.onMealPlanSaved();

      if (closeOnSuccess && mounted) {
        Navigator.pop(context);
      }
      return true;
    } catch (e) {
      logger.e("Save failed: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      return false;
    } finally {
      if (mounted && !closeOnSuccess) setState(() => _isSaving = false);
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData || _currentPlan.days.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSummarySelector(),

            // 🎯 SHARED DIET EDITOR
            Expanded(
              child: DietPlanEditor(
                days: _currentPlan.days,
                allFoodItems: _allFoodItems,
                allMealNames: _allMealNames, // 🎯 FIX 3: Pass the meal names
                targetCalories: _targetCalories,
                isWeekly: _currentPlan.days.length > 1,
                onDaysChanged: (updatedDays) {
                  setState(() {
                    _currentPlan = _currentPlan.copyWith(days: updatedDays);
                  });
                },
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
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.print_rounded, color: Colors.teal),
                tooltip: "Save & Print",
                onPressed: _isSaving ? null : _saveAndPrint,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: _isSaving ? const CircularProgressIndicator() : const Icon(Icons.save, color: Colors.indigo),
                tooltip: "Save & Close",
                onPressed: _isSaving ? null : () => _savePlan(closeOnSuccess: true),
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- GOAL SETTINGS WIDGETS ---

  Widget _buildSummarySelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF3F51B5).withOpacity(0.12), blurRadius: 25, offset: const Offset(0, 10))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openSettingsSheet,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("DIET PLAN TARGETS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade400, letterSpacing: 1.2)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text("${_targetCalories.toInt()} kcal", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                            Container(margin: const EdgeInsets.symmetric(horizontal: 8), width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle)),
                            Text(_dietType, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ),
                    const Icon(Icons.tune_rounded, color: Colors.indigo, size: 24),
                  ],
                ),
                if (_isProvisional) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text("PROVISIONAL (DRAFT) PLAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800))),
                  ),
                ],
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniIndicator(Icons.water_drop_rounded, "${_waterGoal.toStringAsFixed(1)}L", Colors.blue),
                    _buildMiniIndicator(Icons.bedtime_rounded, "${_sleepGoal.toStringAsFixed(1)}h", Colors.deepPurple),
                    _buildMiniIndicator(Icons.directions_walk_rounded, "${(_stepGoal / 1000).toStringAsFixed(1)}k", Colors.orange),
                    _buildMiniIndicator(Icons.self_improvement_rounded, "${_mindfulnessGoal}m", Colors.teal),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniIndicator(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.7)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
      ],
    );
  }

  void _openSettingsSheet() {
    final _habitService = ref.read(habitMasterServiceProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75, minChildSize: 0.5, maxChildSize: 0.95,
        builder: (_, controller) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setSheetState) {
              void updateState(VoidCallback fn) {
                setSheetState(fn);
                setState(fn);
              }

              return Container(
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
                child: Column(
                  children: [
                    Center(child: Container(margin: const EdgeInsets.only(top: 12, bottom: 20), width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text("Plan Targets", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    ),
                    const Divider(height: 30),
                    Expanded(
                      child: ListView(
                        controller: controller,
                        padding: const EdgeInsets.all(24),
                        children: [
                          _buildPremiumGoalCard(
                            title: "Plan Status",
                            icon: Icons.flag_rounded,
                            color: _isProvisional ? Colors.orange : Colors.green,
                            value: _isProvisional ? "Draft" : "Final",
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text("Mark as Provisional", style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text("Draft plans are not counted in reports."),
                              value: _isProvisional,
                              activeColor: Colors.orange,
                              onChanged: (v) => updateState(() => _isProvisional = v),
                            ),
                          ),
                          _buildPremiumGoalCard(
                            title: "Calorie Target",
                            icon: Icons.local_fire_department_rounded,
                            color: Colors.orange,
                            value: "${_targetCalories.toInt()} kcal",
                            child: Slider(value: _targetCalories, min: 1000, max: 4000, divisions: 60, onChanged: (v) => updateState(() => _targetCalories = v)),
                          ),
                          _buildPremiumGoalCard(
                            title: "Diet Strategy",
                            icon: Icons.restaurant_rounded,
                            color: Colors.indigo,
                            value: _dietType,
                            child: Wrap(spacing: 8, children: ["Balanced", "High Protein", "Low Carb", "Keto", "Veg"].map((type) => ChoiceChip(
                                label: Text(type), selected: _dietType == type, onSelected: (val) => updateState(() => _dietType = type)
                            )).toList()),
                          ),
                          _buildPremiumGoalCard(
                            title: "Daily Hydration", icon: Icons.water_drop_rounded, color: Colors.blueAccent, value: "${_waterGoal.toStringAsFixed(1)} L",
                            child: Slider(value: _waterGoal, min: 1.0, max: 6.0, divisions: 10, onChanged: (v) => updateState(() => _waterGoal = v)),
                          ),
                          _buildPremiumGoalCard(
                            title: "Sleep Duration", icon: Icons.bedtime_rounded, color: Colors.deepPurpleAccent, value: "${_sleepGoal.toStringAsFixed(1)} Hr",
                            child: Slider(value: _sleepGoal, min: 4.0, max: 12.0, divisions: 16, onChanged: (v) => updateState(() => _sleepGoal = v)),
                          ),
                          _buildPremiumGoalCard(
                            title: "Daily Steps", icon: Icons.directions_walk_rounded, color: Colors.orangeAccent, value: "${_stepGoal.toStringAsFixed(0)}",
                            child: Slider(value: _stepGoal.toDouble(), min: 1000, max: 20000, divisions: 19, onChanged: (v) => updateState(() => _stepGoal = v.toInt())),
                          ),
                          _buildHabitSection(updateState, _habitService),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: const Text("SAVE SETTINGS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              );
            }
        ),
      ),
    );
  }

  Widget _buildPremiumGoalCard({required String title, required IconData icon, required Color color, required String value, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color.withOpacity(0.04), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
          ]),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _buildHabitSection(Function(VoidCallback) updateState, GenericMasterService genericService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Assigned Habits", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final result = await showModalBottomSheet<List<String>>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => PremiumHabitSelectSheet(initialSelectedIds: _assignedHabitIds));
            if (result != null) updateState(() => _assignedHabitIds = result);
          },
          child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: const Center(child: Text("+ Add Habits", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)))),
        ),
        const SizedBox(height: 12),
        if (_assignedHabitIds.isNotEmpty)
          StreamBuilder<List<GenericMasterModel>>(
            stream: genericService.streamActiveItems(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final selectedHabits = snapshot.data!.where((h) => _assignedHabitIds.contains(h.id)).toList();
              return Wrap(spacing: 8, runSpacing: 8, children: selectedHabits.map((habit) => Chip(label: Text(habit.name), onDeleted: () => updateState(() => _assignedHabitIds.remove(habit.id)))).toList());
            },
          )
      ],
    );
  }
}