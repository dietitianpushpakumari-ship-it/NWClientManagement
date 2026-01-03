import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/diet_plan_editor.dart';
import 'package:nutricare_client_management/admin/generic_master_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/master/model/food_item.dart';
import 'package:nutricare_client_management/master/model/meal_master_name.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/master_diet_planner/generic_multi_select_dialogg.dart';

// Enums and Helpers
extension IterableExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) { if (test(element)) return element; }
    return null;
  }
}

enum PlanCycleType { singleDay, weekly }

final categoryListProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final cats = await ref.watch(dietPlanCategoryServiceProvider).fetchActiveItems();
  return { for (var c in cats) c.name: c.id };
});

class MasterDietPlanEntryPage extends ConsumerStatefulWidget {
  final String? planId;
  final MasterDietPlanModel? initialPlan;
  final PlanCycleType? initialCycleType;

  const MasterDietPlanEntryPage({super.key, this.planId, this.initialPlan, this.initialCycleType});

  @override
  ConsumerState<MasterDietPlanEntryPage> createState() => _MasterDietPlanEntryPageState();
}

class _MasterDietPlanEntryPageState extends ConsumerState<MasterDietPlanEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<MasterMealName> _allMealNames = [];

  List<String> _selectedCategoryIds = [];
  MasterDietPlanModel _currentPlan = const MasterDietPlanModel();
  List<FoodItem> _allFoodItems = [];
  List<GenericMasterModel> _allCategories = [];
  bool _isSaving = false;
  late PlanCycleType _activeCycleType;

  final List<String> _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _activeCycleType = widget.initialCycleType ?? (widget.initialPlan?.days.length == 7 ? PlanCycleType.weekly : PlanCycleType.singleDay);
    _loadData();
  }

  Future<void> _loadData() async {
    final foods = await ref.read(foodItemServiceProvider).fetchAllActiveFoodItems();
    final meals = await ref.read(masterMealNameServiceProvider).fetchAllMealNames();
    final cats = await ref.read(dietPlanCategoryServiceProvider).fetchActiveItems();
    meals.sort((a, b) => (a.order).compareTo(b.order));
    MasterDietPlanModel plan;

    if (widget.planId != null || widget.initialPlan != null) {
      plan = widget.initialPlan ?? await ref.read(masterDietPlanServiceProvider).fetchPlanById(widget.planId!);
    } else {
      // Initialize New Plan
      final List<MasterDayPlanModel> initialDays = [];
      final initialMeals = meals.map((m) => DietPlanMealModel(id: m.id, mealNameId: m.id, mealName: m.name, items: [], order: m.order)).toList();

      if (_activeCycleType == PlanCycleType.weekly) {
        for(int i = 0; i < 7; i++) {
          initialDays.add(MasterDayPlanModel(id: 'd${i+1}', dayName: _dayNames[i], meals: initialMeals));
        }
      } else {
        initialDays.add(MasterDayPlanModel(id: 'd1', dayName: 'Fixed Day', meals: initialMeals));
      }
      plan = MasterDietPlanModel(days: initialDays);
    }

    _nameController.text = plan.name;
    _descriptionController.text = plan.description;
    _selectedCategoryIds = List.from(plan.dietPlanCategoryIds);

    if (mounted) {
      setState(() {
        _currentPlan = plan;
        _allFoodItems = foods;
        _allCategories = cats;
      });
    }
  }

  // --- SAVE & DELETE ---

  Future<void> _confirmDelete() async {
    if (_currentPlan.id.isEmpty) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to permanently delete the template '${_currentPlan.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      try {
        await ref.read(masterDietPlanServiceProvider).deletePlan(_currentPlan.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Template deleted successfully!")));
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deletion failed: $e')));
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one Goal Category.")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(masterDietPlanServiceProvider).savePlan(_currentPlan.copyWith(
          id: widget.planId ?? _currentPlan.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          dietPlanCategoryIds: _selectedCategoryIds,
          days: _currentPlan.days
      ));
      if (mounted) Navigator.pop(context);
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  // --- CATEGORY SELECTOR ---

  void _openCategorySelector() async {
    if (_allCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Category data not loaded yet.")));
      return;
    }

    final categoryNameIdMap = { for (var c in _allCategories) c.name: c.id };
    final currentSelectedNames = _allCategories
        .where((c) => _selectedCategoryIds.contains(c.id))
        .map((c) => c.name)
        .toList();

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GenericMultiSelectDialog(
        title: "Select Goal Categories",
        items: _allCategories.map((c) => c.name).toList(),
        itemNameIdMap: categoryNameIdMap,
        initialSelectedItems: currentSelectedNames,
        collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_DietPlanCategories),
        providerToRefresh: categoryListProvider,
      ),
    );

    if (result != null) {
      // Reload categories to handle newly added ones
      await _loadData();
      final newMap = { for (var c in _allCategories) c.name: c.id };
      final selectedIds = result.map((name) => newMap[name] ?? '').where((id) => id.isNotEmpty).toList();
      setState(() => _selectedCategoryIds = selectedIds);
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.initialPlan != null || widget.planId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Background Decoration
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          Column(
            children: [
              _buildHeader(widget.planId == null ? "New Template" : "Edit Template", onSave: _save, isLoading: _isSaving, isEditMode: isEditMode),

              Expanded(
                child: _allFoodItems.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                  children: [
                    _buildModeDisplay(),

                    // Template Metadata Form
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                      child: Form(
                        key: _formKey,
                        child: Column(children: [
                          _buildTextField(_nameController, "Template Name", Icons.label, required: true),
                          const SizedBox(height: 12),
                          _buildCategorySelectorField(),
                          const SizedBox(height: 12),
                          _buildTextField(_descriptionController, "Description", Icons.description, maxLines: 2),
                        ]),
                      ),
                    ),

                    // 🎯 SHARED DIET EDITOR
                    Expanded(
                      child: DietPlanEditor(
                        days: _currentPlan.days,
                        allFoodItems: _allFoodItems,
                        targetCalories: 2000, // Default for templates
                        isWeekly: _currentPlan.days.length > 1,
                        allMealNames: _allMealNames,
                        onDaysChanged: (updatedDays) {
                          setState(() {
                            _currentPlan = _currentPlan.copyWith(days: updatedDays);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildModeDisplay() {
    final isWeekly = _currentPlan.days.length > 1;
    Color color = isWeekly ? Colors.teal : Colors.blueGrey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Text(
          isWeekly ? "WEEKLY CYCLE (7 DAYS)" : "SINGLE DAY CYCLE (FIXED)",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCategorySelectorField() {
    final selectedNames = _allCategories
        .where((c) => _selectedCategoryIds.contains(c.id))
        .map((c) => c.name)
        .toList();

    String categoryLabel = _selectedCategoryIds.isEmpty
        ? "Select Goal Categories (Required)"
        : "Selected: ${selectedNames.join(', ')}";

    return GestureDetector(
      onTap: _openCategorySelector,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _selectedCategoryIds.isEmpty ? Colors.red : Colors.grey.shade300),
        ),
        child: Text(
          categoryLabel,
          style: TextStyle(
            color: _selectedCategoryIds.isEmpty ? Colors.red : Colors.black,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildHeader(String title, {required VoidCallback onSave, required bool isLoading, required bool isEditMode}) {
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
            if (isEditMode)
              IconButton(onPressed: isLoading ? null : _confirmDelete, icon: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 28)),
            const SizedBox(width: 10),
            IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.save, color: Colors.teal, size: 28))
          ]),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController c, String l, IconData i, {bool isNumber = false, int maxLines = 1, bool required = true}) {
    return TextFormField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
          labelText: l,
          prefixIcon: Icon(i, size: 18, color: Colors.grey),
          filled: true, fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)
      ),
      validator: (v) => required && (v == null || v.isEmpty) ? "$l is required" : null,
    );
  }
}