import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/plan_report_view_screen.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/master_diet_planner/generic_multi_select_dialogg.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/screen/assigned_diet_plan_list.dart';

// --- Master Data Service and Providers ---
final masterServiceProvider = masterDataServiceProvider;

// 🎯 Provider for fetching Master Plan Names
final masterDietPlansProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterDietPlanServiceProvider).fetchMasterPlanNamesMap();
});

class MasterPlanAssignmentSheet extends ConsumerStatefulWidget {
  final ClientModel client;
  final String? sessionId;

  const MasterPlanAssignmentSheet({super.key, required this.client, this.sessionId});

  static Future<bool?> showAssignmentSheet(BuildContext context, ClientModel client, String? sessionId) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Important for the rounded corners of the sheet
      builder: (ctx) => MasterPlanAssignmentSheet(client: client, sessionId: sessionId),
    );
  }

  @override
  ConsumerState<MasterPlanAssignmentSheet> createState() => _MasterPlanAssignmentSheetState();
}

class _MasterPlanAssignmentSheetState extends ConsumerState<MasterPlanAssignmentSheet> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPlanId;
  String? _selectedPlanName;

  bool _isLoading = false;

  // --- Master Data Handler (Refactored) ---

  void _openMasterPlanSelectorDialog(Map<String, String> allMasterPlans) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GenericMultiSelectDialog(
        title: "Select Master Diet Plan",
        items: allMasterPlans.keys.toList(),
        itemNameIdMap: allMasterPlans,
        initialSelectedItems: _selectedPlanName != null ? [_selectedPlanName!] : [],
        singleSelect: true,

        // 🎯 NEW: Enable Internal Add & Refresh
        collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_mealTemplates),
        providerToRefresh: masterDietPlansProvider,
      ),
    );

    if (result != null) {
      if (result.isNotEmpty) {
        final selectedName = result.first;
        setState(() {
          _selectedPlanName = selectedName;
          _selectedPlanId = allMasterPlans[selectedName];
        });
      } else {
        setState(() {
          _selectedPlanName = null;
          _selectedPlanId = null;
        });
      }
    }
  }

  // --- Logic: Preview ---
  Future<void> _previewSelectedPlan() async {
    if (_selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Master Diet Plan to preview.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final masterPlanService = ref.read(masterDietPlanServiceProvider);
      final masterPlan = await masterPlanService.fetchPlanById(_selectedPlanId!);

      // Convert to Client Plan for Preview
      final clientPlanForPreview = ClientDietPlanModel.fromMaster(
        masterPlan,
        widget.client.id,
        const [],
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlanReportViewScreen(
              plan: clientPlanForPreview,
              client: widget.client,
              isMasterPreview: true,
              vitals: null,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load plan details: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Logic: Assignment ---
  Future<void> _assignPlanAndInterventions() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlanId == null) return;

    final clientPlanService = ref.read(clientDietPlanServiceProvider);

    // 1. Check for existing draft
    final existingPlans = ref.read(dietPlanStreamProvider(widget.client.id)).value ?? [];
    final hasExistingDraft = existingPlans.any(
            (p) => p.sessionId == widget.sessionId && p.isProvisional == true
    );

    // 2. Confirm replacement if draft exists
    if (hasExistingDraft) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Replace Current Draft?"),
          content: Text("You already have a draft for this session. Assigning '$_selectedPlanName' will replace it."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text("REPLACE"),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    // 3. Assign
    setState(() => _isLoading = true);
    try {
      final masterPlan = await ref.read(masterDietPlanServiceProvider).fetchPlanById(_selectedPlanId!);

      await clientPlanService.assignPlanToClientAndReturnId(
        clientId: widget.client.id,
        masterPlan: masterPlan,
        sessionId: widget.sessionId,
      );

      if (mounted) {
        ref.invalidate(dietPlanStreamProvider(widget.client.id));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI Components ---

  Widget _buildSheetHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Assign Master Plan Template",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelectorField(Map<String, String> allMasterPlans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedPlanName ?? "No Plan Selected",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: _selectedPlanName != null ? FontWeight.w600 : FontWeight.normal,
                  color: _selectedPlanName != null ? Colors.black87 : Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_selectedPlanName != null)
              TextButton.icon(
                onPressed: _isLoading ? null : _previewSelectedPlan,
                icon: Icon(Icons.visibility, size: 20, color: Colors.blue.shade700),
                label: Text("Preview", style: TextStyle(color: Colors.blue.shade700)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _openMasterPlanSelectorDialog(allMasterPlans),
          icon: const Icon(Icons.search),
          label: Text(_selectedPlanName == null ? "SELECT MASTER PLAN" : "CHANGE MASTER PLAN"),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 45),
            backgroundColor: Colors.indigo.shade50,
            foregroundColor: Colors.indigo,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        if (_selectedPlanName == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Master plan selection is required.',
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(masterDietPlansProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildSheetHeader(context),
          Expanded(
            child: plansAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (allMasterPlans) => Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200)
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Select Plan Template', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                            const SizedBox(height: 4),
                            const Text("Choose a base template to customize for this client.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const Divider(height: 24),
                            _buildPlanSelectorField(allMasterPlans),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _assignPlanAndInterventions,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ASSIGN & CUSTOMIZE PLAN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}