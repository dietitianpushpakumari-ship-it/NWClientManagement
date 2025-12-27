import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/plan_report_view_screen.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/master_diet_planner/generic_multi_select_dialogg.dart';
import 'package:nutricare_client_management/admin/generic_clinical_master_entry_screen.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
// 🎯 ADDED REQUIRED IMPORTS
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/screen/assigned_diet_plan_list.dart';
// Note: MasterDietPlanModel is assumed to be imported via global_service_provider.dart or similar.


// --- Master Data Service and Providers ---
final masterServiceProvider = masterDataServiceProvider;
final mapper = MasterCollectionMapper.getPath;

// Providers for fetching required master lists (Map<Name, ID>)
final masterDietPlansProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  // Assuming a services method exists to get {Plan Name: Plan ID}
  return ref.watch(masterDietPlanServiceProvider).fetchMasterPlanNamesMap();
});


class MasterPlanAssignmentSheet extends ConsumerStatefulWidget {
  final ClientModel client;
  final String? sessionId;

  const MasterPlanAssignmentSheet({super.key, required this.client,this.sessionId});

  // 🎯 FIX: Correctly define the static method for external calling
  static Future<bool?> showAssignmentSheet(BuildContext context, ClientModel client,String? sessionId) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => MasterPlanAssignmentSheet(client: client, sessionId: sessionId,),
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // --- Custom Header Widget (Simplified for Sheet/Dialog) ---
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
          Text(
            "Assign Master Plan Template",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // --- Master Data Handlers ---

  void _openMultiSelectDialog({
    required Map<String, String> masterDataMap,
    required List<String> currentKeys,
    required String title,
    required Function(List<String>) onResult,
    required String entityName,
    bool singleSelect = false,
  }) async {
    // 🎯 Use showModalBottomSheet for consistent UI/UX for selection
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => GenericMultiSelectDialog(
        title: title,
        items: masterDataMap.keys.toList(),
        itemNameIdMap: masterDataMap,
        initialSelectedItems: currentKeys,
        singleSelect: singleSelect,
        onAddMaster: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GenericClinicalMasterEntryScreen(
              entityName: entityName,
            ),
          )).then((_) {
            if (entityName == MasterEntity.entity_mealTemplates) ref.invalidate(masterDietPlansProvider);
          });
        },
      ),
    );
    if (result != null) onResult(result);
  }

  void _openMasterPlanSelectorDialog(Map<String, String> allMasterPlans) {
    _openMultiSelectDialog(
      masterDataMap: allMasterPlans,
      currentKeys: _selectedPlanName != null ? [_selectedPlanName!] : [],
      title: "Select Master Diet Plan",
      singleSelect: true,
      onResult: (r) {
        if (r.isNotEmpty) {
          final selectedName = r.first;
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
      },
      entityName: MasterEntity.entity_mealTemplates,
    );
  }

  // Retained preview logic (using currently selected master plan and temporary defaults)
  Future<void> _previewSelectedPlan() async {
    if (_selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Master Diet Plan to preview.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final masterPlanService = ref.read(masterDietPlanServiceProvider);

      // Fetch the full MasterDietPlanModel
      final masterPlan = await masterPlanService.fetchPlanById(_selectedPlanId!);

      // Convert MasterDietPlanModel to ClientDietPlanModel for the PlanReportViewScreen
      final clientPlanForPreview = ClientDietPlanModel.fromMaster(
        masterPlan,
        widget.client.id,
        const [],
      );

      // The sheet must be closed before opening a full page preview
      if (mounted) {
       // Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlanReportViewScreen(
              plan: clientPlanForPreview,
              client: widget.client,
              isMasterPreview: true, vitals: null,
            ),
          ),
        );//.then((_) {
          // Re-open the selector sheet when preview is dismissed
       //   MasterPlanAssignmentSheet.showAssignmentSheet(context, widget.client);
     //   });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load plan details for preview: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Plan Assignment Logic (FINALIZED) ---

// lib/modules/client/screen/master_plan_assignment_page.dart

// lib/modules/client/screen/master_plan_assignment_page.dart

  Future<void> _assignPlanAndInterventions() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlanId == null) return;

    final clientPlanService = ref.read(clientDietPlanServiceProvider);

    // 1. 🎯 Check if a draft already exists for this session
    final existingPlans = ref.read(dietPlanStreamProvider(widget.client.id)).value ?? [];
    final hasExistingDraft = existingPlans.any(
            (p) => p.sessionId == widget.sessionId && p.isProvisional == true
    );

    // 2. 🎯 Only show confirmation if it's NOT the first time (i.e., a draft exists)
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

    // 3. Proceed with assignment (Dialog skipped if hasExistingDraft is false)
    setState(() => _isLoading = true);
    try {
      final masterPlan = await ref.read(masterDietPlanServiceProvider).fetchPlanById(_selectedPlanId!);

      await clientPlanService.assignPlanToClientAndReturnId(
        clientId: widget.client.id,
        masterPlan: masterPlan,
        sessionId: widget.sessionId,
      );

      if (mounted) {
        // Invalidate to ensure the list updates immediately
        ref.invalidate(dietPlanStreamProvider(widget.client.id));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // --- UI Widgets ---

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
            minimumSize: const Size(double.infinity, 40),
            backgroundColor: Colors.indigo.shade100,
            foregroundColor: Colors.indigo,
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

    return Container( // Use Container to manage sheet height and styling
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
              error: (err, stack) => Center(child: Text('Error loading master plans: $err')),
              data: (allMasterPlans) => Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // --- 1. Master Plan Selection ---
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Select Plan Template', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                            const Divider(),
                            _buildPlanSelectorField(allMasterPlans),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- Final Action Button ---
                    ElevatedButton(
                      onPressed: _isLoading ? null : _assignPlanAndInterventions,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ASSIGN PLAN"),
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