import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/master/model/diet_plan_category.dart';
import 'package:nutricare_client_management/master_diet_planner/diet_plan_cycle_selector_screen.dart';
import 'package:nutricare_client_management/modules/master/screen/master_diet_plan_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/master_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/master/service/diet_plan_category_service.dart';


// NEW ENUM for segregation
enum PlanType { all, oneTime, weekly }

class MasterDietPlanListScreen extends ConsumerStatefulWidget {
  const MasterDietPlanListScreen({super.key});

  @override
  ConsumerState<MasterDietPlanListScreen> createState() => _MasterDietPlanListScreenState();
}

class _MasterDietPlanListScreenState extends ConsumerState<MasterDietPlanListScreen> {

  List<String> _selectedCategoryIds = [];
  String? _selectedCategoryName;

  late Future<List<DietPlanCategory>> _categoriesFuture;

  PlanType _selectedPlanType = PlanType.all;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ref.read(dietPlanCategoryServiceProvider).fetchAllActiveCategories();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Custom Header for Ultra Premium Look
  Widget _buildCustomHeader(BuildContext context, String title) {
    return Container(
      // Padding handles system status bar
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // BACK BUTTON
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A1A), size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 10),
          // Title
          Expanded(
            child: Text(
                title,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A)
                )
            ),
          ),
          // Icon for visual flair
          const Icon(Icons.playlist_add_check, color: Colors.teal, size: 30),
        ],
      ),
    );
  }

  // 🎯 FIX: Logic to open Category Filter Bottom Sheet with stable Set management
  void _openCategoryFilterSheet(List<DietPlanCategory> categories) async {
    // 🎯 FIX 1: Initialize the local set from the current global state (List to Set)
    // This variable must be final and not part of the modal's internal state.
    final Set<String> initialSelectedSet = Set.from(_selectedCategoryIds);

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) {

            // 🎯 FIX 2: Define and manage local state for search query and selected set
            final localSearchController = TextEditingController();
            String localSearchQuery = "";
            Set<String> currentLocalSelectedSet = initialSelectedSet; // Use the initialized Set

            void updateSelection(String id, bool selected) {
              setModalState(() {
                if (selected) {
                  currentLocalSelectedSet.add(id);
                } else {
                  currentLocalSelectedSet.remove(id);
                }
              });
            }

            // Search filtering logic
            final filteredCategories = categories.where((c) {
              return localSearchQuery.isEmpty ||
                  c.name.toLowerCase().contains(localSearchQuery.toLowerCase());
            }).toList();

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text("Filter by Goal Category"),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(60),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: localSearchController,
                          onChanged: (value) => setModalState(() {
                            localSearchQuery = value; // Update local query state
                          }),
                          decoration: InputDecoration(
                            hintText: "Search categories...",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  body: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            ...filteredCategories.map((c) {
                              // Check against the current local Set
                              final isSelected = currentLocalSelectedSet.contains(c.id);
                              return CheckboxListTile(
                                title: Text(c.name),
                                value: isSelected,
                                // 🎯 Fix: onChanged now calls updateSelection which correctly modifies the Set
                                onChanged: (bool? value) => updateSelection(c.id, value ?? false),
                              );
                            }).toList(),
                            if (categories.isEmpty)
                              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No categories available."))),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                // Clear the global state by popping with an empty list
                                Navigator.pop(context, []);
                              },
                              child: const Text("Clear Filter", style: TextStyle(color: Colors.red)),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () {
                                // Pop with the final selected list from the Set
                                Navigator.pop(context, currentLocalSelectedSet.toList());
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                              child: const Text("Apply Filter", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          }
      ),
    ).then((result) {
      if (result is List<String>) {
        // Only update the main state if a list (from Apply or Clear) was returned
        setState(() {
          _selectedCategoryIds = result;
          if (result.isEmpty) {
            _selectedCategoryName = null;
          } else {
            // Find the name of the first selected category for display
            final categoryMap = { for (var c in categories) c.id: c.name };
            _selectedCategoryName = categoryMap[result.first];
          }
        });
      }
    });
  }

  // --- DELETE LOGIC (Retained) ---
  Future<void> _confirmDelete(MasterDietPlanModel plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to permanently delete the template: '${plan.name}'? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(masterDietPlanServiceProvider).deletePlan(plan.id);
                if (mounted) Navigator.pop(ctx, true);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Template Deleted."), backgroundColor: Colors.green));
              } catch (e) {
                if (mounted) Navigator.pop(ctx, false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deletion Failed: $e'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete Permanently"),
          )
        ],
      ),
    );
  }

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final masterPlanService = ref.watch(masterDietPlanServiceProvider);

    // Use dynamic stream based on category filter
    final stream = masterPlanService.streamAllPlansByCategoryIds(
        categoryIds: _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DietPlanCycleSelectorScreen())),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Template", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      // MODIFIED BODY STRUCTURE
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          SafeArea(
            top: false, // Handle top padding in custom header
            child: Column(
              children: [
                _buildCustomHeader(context, "Diet Templates"), // USE CUSTOM HEADER

                // Wrap remaining content in Expanded
                Expanded(
                  child: Column(
                    children: [
                      _buildSearchBar(),

                      // Filter Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: _buildFilterSection(),
                      ),

                      Expanded(
                        child: StreamBuilder<List<MasterDietPlanModel>>(
                          stream: stream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                            final allPlans = snapshot.data ?? [];

                            // CLIENT-SIDE FILTERING (Text Search + Plan Type)
                            final filteredList = allPlans.where((plan) {
                              final matchesSearch = _searchQuery.isEmpty ||
                                  plan.name.toLowerCase().contains(_searchQuery) ||
                                  plan.description.toLowerCase().contains(_searchQuery);

                              final matchesType = _selectedPlanType == PlanType.all ||
                                  (_selectedPlanType == PlanType.weekly && plan.days.length > 1) ||
                                  (_selectedPlanType == PlanType.oneTime && plan.days.length <= 1);

                              return matchesSearch && matchesType;
                            }).toList();

                            if (filteredList.isEmpty) return const Center(child: Text("No templates found matching filters."));

                            return ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: filteredList.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final plan = filteredList[index];
                                return _buildPlanCard(context, plan);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Search Bar UI (Retained)
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search by Template Name or Description...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ),
    );
  }


  // MODIFIED: Filter Section -> Now buttons/segmented control
  Widget _buildFilterSection() {
    return FutureBuilder<List<DietPlanCategory>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];
        final selectedCount = _selectedCategoryIds.length;

        return Column(
          children: [
            // 1. Category Filter Button (Opens Bottom Sheet)
            GestureDetector(
              onTap: () => _openCategoryFilterSheet(categories),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
                    border: Border.all(color: Colors.grey.shade200)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedCount == 0
                          ? 'Filter by Goal Category (All)'
                          : (selectedCount == 1 ? 'Category: $_selectedCategoryName' : 'Categories selected: $selectedCount'),
                      style: TextStyle(
                        color: selectedCount > 0 ? Colors.teal : Colors.grey.shade600,
                        fontWeight: selectedCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.teal),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 2. Plan Type Segregation (Segmented Control style)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: PlanType.values.map((type) {
                final isSelected = type == _selectedPlanType;
                final label = type == PlanType.all ? 'All' : (type == PlanType.oneTime ? 'One-Time' : 'Weekly');
                final color = isSelected ? Colors.teal : Colors.grey.shade600;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: type == PlanType.all ? 0 : 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPlanType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.teal.shade100.withOpacity(0.7) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? Colors.teal : Colors.grey.shade300),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  // Plan Card (Retained)
  Widget _buildPlanCard(BuildContext context, MasterDietPlanModel plan) {
    final isWeekly = plan.days.length > 1;
    final cycleLabel = isWeekly ? 'Weekly Cycle' : 'Single Day';

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(isWeekly ? Icons.calendar_view_week : Icons.today, color: Colors.teal)),
        title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$cycleLabel - ${plan.description}", maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => MasterDietPlanEntryPage(initialPlan: plan)));
            } else if (value == 'delete') {
              _confirmDelete(plan);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text("Edit")])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text("Delete", style: TextStyle(color: Colors.red))])),
          ],
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MasterDietPlanEntryPage(initialPlan: plan))),
      ),
    );
  }
}