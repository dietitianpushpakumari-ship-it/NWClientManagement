import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutricare_client_management/modules/client/services/client_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/master/service/master_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_category.dart';
import 'package:nutricare_client_management/modules/master/service/diet_plan_category_service.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_item_model.dart';

class MasterPlanSelectionPage extends StatefulWidget {
  final ClientModel client;
  final VoidCallback onMasterPlanAssigned;

  const MasterPlanSelectionPage({
    super.key,
    required this.client,
    required this.onMasterPlanAssigned,
  });

  @override
  State<MasterPlanSelectionPage> createState() => _MasterPlanSelectionPageState();
}

class _MasterPlanSelectionPageState extends State<MasterPlanSelectionPage> {
  final MasterDietPlanService _masterService = MasterDietPlanService();
  final ClientDietPlanService _clientService = ClientDietPlanService();

  String? _selectedCategoryId;
  List<String>? _activeFilterIds;
  bool _isProcessing = false;

  // --- Logic: Assign/Unassign ---

  Future<void> _togglePlanAssignment(MasterDietPlanModel masterPlan, bool isCurrentlyAssigned) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      if (isCurrentlyAssigned) {
        await _clientService.unassignPlanFromClient(
          clientId: widget.client.id,
          masterPlanId: masterPlan.id,
        );
      } else {
        await _clientService.assignPlanToClient(
          clientId: widget.client.id,
          masterPlan: masterPlan,
        );
      }

      widget.onMasterPlanAssigned();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${masterPlan.name} successfully ${isCurrentlyAssigned ? 'unassigned' : 'assigned'}.'),
            backgroundColor: isCurrentlyAssigned ? Colors.orange : Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Close preview if open
        Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --- UI: Plan Preview Modal ---
  void _showPlanPreview(MasterDietPlanModel plan, bool isAssigned) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlanPreviewSheet(
        plan: plan,
        isAssigned: isAssigned,
        onAssign: () => _togglePlanAssignment(plan, isAssigned),
        isProcessing: _isProcessing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryService = Provider.of<DietPlanCategoryService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // 1. Ambient Background
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 80, spreadRadius: 20)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. Header
                _buildHeader(context),

                // 3. Filter
                _buildFilterDropdown(categoryService),

                const SizedBox(height: 16),

                // 4. Plan List
                Expanded(
                  child: StreamBuilder<List<MasterDietPlanModel>>(
                    stream: _masterService.streamAllPlansByCategoryIds(categoryIds: _activeFilterIds),
                    builder: (context, masterPlansSnapshot) {
                      if (masterPlansSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (masterPlansSnapshot.hasError) {
                        return Center(child: Text('Error: ${masterPlansSnapshot.error}'));
                      }

                      final allPlans = masterPlansSnapshot.data ?? [];

                      return StreamBuilder<List<String>>(
                        stream: _clientService.streamAssignedPlanIds(widget.client.id),
                        initialData: const [],
                        builder: (context, assignedIdsSnapshot) {
                          final assignedIds = assignedIdsSnapshot.data?.toSet() ?? {};

                          // Sort: Assigned first, then by Name
                          allPlans.sort((a, b) {
                            final aAssigned = assignedIds.contains(a.id) ? 1 : 0;
                            final bAssigned = assignedIds.contains(b.id) ? 1 : 0;
                            if (aAssigned != bAssigned) return bAssigned.compareTo(aAssigned);
                            return a.name.compareTo(b.name);
                          });

                          if (allPlans.isEmpty) {
                            return _buildEmptyState();
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                            itemCount: allPlans.length,
                            itemBuilder: (context, index) {
                              final plan = allPlans[index];
                              final isAssigned = assignedIds.contains(plan.id);
                              return _buildPremiumPlanCard(plan, isAssigned);
                            },
                          );
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Diet Templates", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
              Text("Assign to ${widget.client.name}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(DietPlanCategoryService categoryService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
            ),
            child: StreamBuilder<List<DietPlanCategory>>(
              stream: categoryService.streamAllActive(),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                return DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategoryId,
                    icon: Icon(Icons.filter_list_rounded, color: Theme.of(context).colorScheme.primary),
                    hint: const Text("Filter by Goal", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('All Categories')),
                      ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.enName))),
                    ],
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategoryId = newValue;
                        _activeFilterIds = newValue == null ? null : [newValue];
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No templates found.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // 🎯 PREMIUM CARD DESIGN
  Widget _buildPremiumPlanCard(MasterDietPlanModel plan, bool isAssigned) {
    int mealCount = plan.days.isNotEmpty ? plan.days.first.meals.length : 0;
    int itemsCount = plan.days.isNotEmpty ? plan.days.first.meals.fold(0, (prev, m) => prev + m.items.length) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: isAssigned ? Border.all(color: Colors.green.shade300, width: 1.5) : Border.all(color: Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Card Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isAssigned ? Colors.green.shade50 : Theme.of(context).colorScheme.primary.withOpacity(.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isAssigned ? Icons.check_circle_rounded : Icons.article_rounded,
                    color: isAssigned ? Colors.green.shade700 : Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2D3142)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.description.isNotEmpty ? plan.description : "No description available.",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Stats Row (Divider)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200), bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.restaurant, "$mealCount Meals"),
                _buildStatItem(Icons.list, "$itemsCount Items"),
                _buildStatItem(Icons.repeat, "Daily Cycle"),
              ],
            ),
          ),

          // 3. Action Buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Preview Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPlanPreview(plan, isAssigned),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text("Preview"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(.15)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Assign Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _togglePlanAssignment(plan, isAssigned),
                    icon: Icon(isAssigned ? Icons.remove_circle_outline : Icons.add_circle_outline, size: 18),
                    label: Text(isAssigned ? "Unassign" : "Assign"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAssigned ? Colors.red.shade50 : Theme.of(context).colorScheme.primary,
                      foregroundColor: isAssigned ? Colors.red : Colors.white,
                      elevation: isAssigned ? 0 : 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
      ],
    );
  }
}

// --- 🎯 PREMIUM PREVIEW SHEET ---
class _PlanPreviewSheet extends StatelessWidget {
  final MasterDietPlanModel plan;
  final bool isAssigned;
  final VoidCallback onAssign;
  final bool isProcessing;

  const _PlanPreviewSheet({
    required this.plan,
    required this.isAssigned,
    required this.onAssign,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    // Using a single day view for template preview (assuming day[0])
    final dayPlan = plan.days.isNotEmpty ? plan.days.first : null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // Tall sheet
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 1. Handle & Title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text(plan.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text("Template Preview", style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Scrollable Content
          Expanded(
            child: dayPlan == null
                ? const Center(child: Text("No meals defined in this template."))
                : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: dayPlan.meals.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final meal = dayPlan.meals[index];
                return _buildMealPreviewCard(meal,context);
              },
            ),
          ),

          // 3. Bottom Action Bar (Split Actions for Safety)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30), // Extra bottom padding for safe area
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Cancel/Close Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("CANCEL", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Primary Action Button
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isProcessing ? null : onAssign,
                        icon: isProcessing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(isAssigned ? Icons.remove_circle_outline : Icons.check_circle_outline),
                        label: Text(isAssigned ? "UNASSIGN" : "CONFIRM"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAssigned ? Colors.red.shade600 : Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMealPreviewCard(DietPlanMealModel meal, BuildContext context) {
    if (meal.items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.restaurant_menu_rounded, size: 18, color: Colors.orange),
            const SizedBox(width: 8),
            Text(meal.mealName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: meal.items.map((item) {
              return ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Text(item.foodItemName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: Text(
                  "${item.quantity} ${item.unit}",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
                subtitle: item.alternatives.isNotEmpty
                    ? Text("Or: ${item.alternatives.map((a) => a.foodItemName).join(', ')}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic))
                    : null,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}