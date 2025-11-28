import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/client/screen/premium_meal_entry_list.dart';
import 'package:nutricare_client_management/modules/master/service/master_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_category.dart';
import 'package:nutricare_client_management/modules/master/model/food_item.dart';
import 'package:nutricare_client_management/modules/master/model/meal_master_name.dart';
import 'package:nutricare_client_management/modules/master/service/diet_plan_category_service.dart';
import 'package:nutricare_client_management/modules/master/service/food_item_service.dart';
import 'package:nutricare_client_management/modules/master/service/master_meal_name_service.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_item_model.dart';

// Extension
extension IterableExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) { if (test(element)) return element; }
    return null;
  }
}

class MasterDietPlanEntryPage extends StatefulWidget {
  final String? planId;
  final MasterDietPlanModel? initialPlan;
  const MasterDietPlanEntryPage({super.key, this.planId, this.initialPlan});

  @override
  State<MasterDietPlanEntryPage> createState() => _MasterDietPlanEntryPageState();
}

class _MasterDietPlanEntryPageState extends State<MasterDietPlanEntryPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  TabController? _tabController;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DietPlanCategory? _selectedCategory;
  MasterDietPlanModel _currentPlan = const MasterDietPlanModel();

  Future<(List<FoodItem>, List<MasterMealName>, List<DietPlanCategory>)>? _initialDataFuture;
  List<FoodItem> _allFoodItems = [];
  List<MasterMealName> _allMealNames = [];
  List<DietPlanCategory> _allCategories = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialDataFuture = _loadData();
  }

  Future<(List<FoodItem>, List<MasterMealName>, List<DietPlanCategory>)> _loadData() async {
    final foods = await FoodItemService().fetchAllActiveFoodItems();
    final meals = await MasterMealNameService().fetchAllMealNames();
    final cats = await DietPlanCategoryService().fetchAllActiveCategories();
    meals.sort((a,b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));

    MasterDietPlanModel plan;
    if (widget.planId != null) {
      plan = await MasterDietPlanService().fetchPlanById(widget.planId!);
    } else if (widget.initialPlan != null) {
      plan = widget.initialPlan!;
    } else {
      final initialMeals = meals.map((m) => DietPlanMealModel(id: m.id, mealNameId: m.id, mealName: m.enName, items: [], order: m.order)).toList();
      plan = MasterDietPlanModel(days: [MasterDayPlanModel(id: 'd1', dayName: 'Fixed Day', meals: initialMeals)]);
    }

    // Sync Meals
    if (plan.days.isNotEmpty) {
      final currentDay = plan.days.first;
      final orderedMeals = <DietPlanMealModel>[];
      for (var m in meals) {
        final existing = IterableExt(currentDay.meals).firstWhereOrNull((cm) => cm.mealNameId == m.id);
        orderedMeals.add(existing ?? DietPlanMealModel(id: m.id, mealNameId: m.id, mealName: m.enName, items: [], order: m.order));
      }
      plan = plan.copyWith(days: [currentDay.copyWith(meals: orderedMeals)]);
    }

    _nameController.text = plan.name;
    _descriptionController.text = plan.description;
    if (plan.dietPlanCategoryIds.isNotEmpty) _selectedCategory = IterableExt(cats).firstWhereOrNull((c) => c.id == plan.dietPlanCategoryIds.first);

    if (mounted) {
      setState(() {
        _currentPlan = plan; _allFoodItems = foods; _allMealNames = meals; _allCategories = cats;
        if (plan.days.isNotEmpty) _tabController = TabController(length: plan.days.first.meals.length, vsync: this);
      });
    }
    return (foods, meals, cats);
  }

  void _updateMealItems(String mealId, List<DietPlanItemModel> items) {
    setState(() {
      final day = _currentPlan.days.first;
      final idx = day.meals.indexWhere((m) => m.id == mealId);
      final updatedMeals = List<DietPlanMealModel>.from(day.meals);
      updatedMeals[idx] = updatedMeals[idx].copyWith(items: items);
      _currentPlan = _currentPlan.copyWith(days: [day.copyWith(meals: updatedMeals)]);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Check form & category")));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await MasterDietPlanService().savePlan(_currentPlan.copyWith(
        id: widget.planId ?? _currentPlan.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        dietPlanCategoryIds: [_selectedCategory!.id],
      ));
      if (mounted) Navigator.pop(context);
    } catch(e) {
      // Handle error
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          Column(
            children: [
              _buildHeader(widget.planId == null ? "New Template" : "Edit Template", onSave: _save, isLoading: _isSaving),
              Expanded(
                child: FutureBuilder(
                  future: _initialDataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                    return Column(
                      children: [
                        // Details Card
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                          child: Form(
                            key: _formKey,
                            child: Column(children: [
                              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Template Name", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Req" : null),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<DietPlanCategory>(
                                value: _selectedCategory,
                                decoration: const InputDecoration(labelText: "Goal Category", border: OutlineInputBorder()),
                                items: _allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c.enName))).toList(),
                                onChanged: (v) => setState(() => _selectedCategory = v),
                              )
                            ]),
                          ),
                        ),

                        // Tabs
                        Container(
                          height: 40, margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: TabBar(
                            controller: _tabController, isScrollable: true, labelColor: Colors.white, unselectedLabelColor: Colors.grey,
                            indicator: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(20)),
                            tabs: _currentPlan.days.first.meals.map((m) => Tab(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(m.mealName)))).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Content
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: _currentPlan.days.first.meals.map((m) => PremiumMealEntryList(
                              meal: m, allFoodItems: _allFoodItems,
                              onUpdate: (items) => _updateMealItems(m.id, items),
                            )).toList(),
                          ),
                        )
                      ],
                    );
                  },
                ),
              )
            ],
          )
        ],
      ),
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
            IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.save, color: Colors.teal, size: 28))
          ]),
        ),
      ),
    );
  }
}