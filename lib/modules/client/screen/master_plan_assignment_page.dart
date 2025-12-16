import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/master_diet_planner/generic_multi_select_dialogg.dart';
import 'package:nutricare_client_management/admin/generic_clinical_master_entry_screen.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';

// --- Master Data Service and Mapper Setup ---
final masterServiceProvider = masterDataServiceProvider;
final mapper = MasterCollectionMapper.getPath;

// Providers for fetching required master lists (Map<Name, ID>)
final masterDietPlansProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  // Assuming a service method exists to get {Plan Name: Plan ID}
  return ref.watch(masterDietPlanServiceProvider).fetchMasterPlanNamesMap();
});

final guidelineMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_Guidelines));
});

final investigationMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_Investigation));
});

// NEW PROVIDER: Lifestyle Habit Master Data
final lifeStyleHabitMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_LifestyleHabit));
});


class MasterPlanAssignmentPage extends ConsumerStatefulWidget {
  final ClientModel client;

  const MasterPlanAssignmentPage({super.key, required this.client});

  @override
  ConsumerState<MasterPlanAssignmentPage> createState() => _MasterPlanAssignmentPageState();
}

class _MasterPlanAssignmentPageState extends ConsumerState<MasterPlanAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _followUpController = TextEditingController();

  String? _selectedPlanId;
  String? _selectedPlanName;

  List<String> _selectedGuidelines = [];
  List<String> _selectedInvestigations = [];

  // NEW STATE: Lifestyle Goals (selected from multi-select dialog)
  List<String> _selectedLifestyleGoals = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if a previous draft exists (not implemented here for brevity)
  }

  @override
  void dispose() {
    _followUpController.dispose();
    super.dispose();
  }

  // --- Custom Header Widget (Replaces AppBar) ---
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FE),
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Plan & Intervention for ${widget.client.name}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- Master Data Handlers ---

  // Opens the multi-select dialog for simple masters (Guidelines/Investigations/Goals)
  void _openMultiSelectDialog({
    required Map<String, String> masterDataMap,
    required List<String> currentKeys,
    required String title,
    required Function(List<String>) onResult,
    required String entityName,
  }) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => GenericMultiSelectDialog(
        title: title,
        items: masterDataMap.keys.toList(),
        itemNameIdMap: masterDataMap,
        initialSelectedItems: currentKeys,
        // Navigation to add a new master item from the dialog
        onAddMaster: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GenericClinicalMasterEntryScreen(
              entityName: entityName,
            ),
          )).then((_) {
            // Invalidate the relevant provider to refresh the list
            if (entityName == MasterEntity.entity_Guidelines) ref.invalidate(guidelineMasterProvider);
            if (entityName == MasterEntity.entity_Investigation) ref.invalidate(investigationMasterProvider);
            if (entityName == MasterEntity.entity_LifestyleHabit) ref.invalidate(lifeStyleHabitMasterProvider);
          });
        },
      ),
    );
    if (result != null) onResult(result);
  }

  void _openGuidelinesDialog(Map<String, String> allGuidelines) {
    _openMultiSelectDialog(
      masterDataMap: allGuidelines,
      currentKeys: _selectedGuidelines,
      title: "Select Guidelines",
      onResult: (r) => setState(() => _selectedGuidelines = r),
      entityName: MasterEntity.entity_Guidelines,
    );
  }

  void _openInvestigationDialog(Map<String, String> allInvestigations) {
    _openMultiSelectDialog(
      masterDataMap: allInvestigations,
      currentKeys: _selectedInvestigations,
      title: "Order Investigations",
      onResult: (r) => setState(() => _selectedInvestigations = r),
      entityName: MasterEntity.entity_Investigation,
    );
  }

  void _openLifestyleGoalsDialog(Map<String, String> allHabits) {
    _openMultiSelectDialog(
      masterDataMap: allHabits,
      currentKeys: _selectedLifestyleGoals,
      title: "Select Lifestyle Goals",
      onResult: (r) => setState(() => _selectedLifestyleGoals = r),
      entityName: MasterEntity.entity_LifestyleHabit,
    );
  }

  // --- Plan Assignment Logic ---

  Future<void> _assignPlanAndInterventions() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Master Diet Plan first.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final clientPlanService = ref.read(clientDietPlanServiceProvider);

      // Create a simple map for lifestyle goals (GoalName: 'Selected')
      final Map<String, String> finalLifestyleGoals = _selectedLifestyleGoals.asMap().map((_, key) => MapEntry(key, 'Selected'));


      // 1. Assign the Master Plan to the client
      final assignmentData = {
        'masterPlanId': _selectedPlanId!,
        'masterPlanName': _selectedPlanName!,
        'clientId': widget.client.id,
        'assignedGuidelines': _selectedGuidelines,
        'assignedInvestigations': _selectedInvestigations,
        'followUpDays': int.tryParse(_followUpController.text.trim()),
        'lifestyleGoals': finalLifestyleGoals,
        'assignedDate': DateTime.now(),
      };

      // Assuming a service method handles copying the master plan and updating client records
      await clientPlanService.assignMasterPlan(assignmentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Plan and Interventions assigned successfully to ${widget.client.name}!")));
        Navigator.pop(context, true); // Close the sheet/screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Assignment failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    // Watch all necessary providers
    final plansAsync = ref.watch(masterDietPlansProvider);
    final guidelinesAsync = ref.watch(guidelineMasterProvider);
    final investigationsAsync = ref.watch(investigationMasterProvider);
    final habitsAsync = ref.watch(lifeStyleHabitMasterProvider);

    // Consolidated Loading and Error Check
    if (plansAsync.isLoading || guidelinesAsync.isLoading || investigationsAsync.isLoading || habitsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (plansAsync.hasError || guidelinesAsync.hasError || investigationsAsync.hasError || habitsAsync.hasError) {
      return Scaffold(body: Center(child: Text('Error loading masters: ${plansAsync.error ?? guidelinesAsync.error ?? investigationsAsync.error ?? habitsAsync.error}')));
    }

    // Extract Map values
    final allMasterPlans = plansAsync.value!;
    final allGuidelines = guidelinesAsync.value!;
    final allInvestigations = investigationsAsync.value!;
    final allHabits = habitsAsync.value!;
    final masterPlanNames = allMasterPlans.keys.toList();


    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Column( // Use Column to stack custom header and scrollable content
        children: [
          _buildCustomHeader(context), // 🎯 Custom Header replacing AppBar
          Expanded(
            child: Form(
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
                          const Text('1. Diet Plan Selection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                          const Divider(),
                          DropdownButtonFormField<String>(
                            value: _selectedPlanName,
                            decoration: const InputDecoration(labelText: 'Select Master Plan Template'),
                            items: masterPlanNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                            onChanged: (name) {
                              setState(() {
                                _selectedPlanName = name;
                                _selectedPlanId = allMasterPlans[name];
                              });
                            },
                            validator: (v) => v == null ? 'Master plan selection is required.' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 2. Lifestyle Goals ---
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('2. Lifestyle Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                          const Divider(),
                          Text("Selected Goals (${_selectedLifestyleGoals.length}):", style: const TextStyle(fontWeight: FontWeight.w600)),
                          Wrap(spacing: 8.0, children: _selectedLifestyleGoals.map((name) => Chip(
                              label: Text(name),
                              onDeleted: () => setState(() => _selectedLifestyleGoals.remove(name)),
                              deleteIcon: const Icon(Icons.close, size: 18)
                          )).toList()),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _openLifestyleGoalsDialog(allHabits),
                            icon: const Icon(Icons.fitness_center),
                            label: const Text("Select Lifestyle Goals"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),


                  // --- 3. Monitoring & Follow-up ---
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('3. Monitoring & Follow-up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                          const Divider(),
                          TextFormField(
                            controller: _followUpController,
                            decoration: const InputDecoration(labelText: 'Next Follow-up in Days (e.g., 7 or 14)', hintText: '14'),
                            keyboardType: TextInputType.number,
                            validator: (v) => (v == null || v.isEmpty) ? 'Follow-up days required' : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 4. Guidelines & Instructions ---
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('4. Guidelines & Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                          const Divider(),
                          Text("Selected Guidelines (${_selectedGuidelines.length}):", style: const TextStyle(fontWeight: FontWeight.w600)),
                          Wrap(spacing: 8.0, children: _selectedGuidelines.map((name) => Chip(
                            label: Text(name),
                            // 🎯 FIX: Added onDeleted for Guidelines
                            onDeleted: () => setState(() => _selectedGuidelines.remove(name)),
                            deleteIcon: const Icon(Icons.close, size: 18),
                          )).toList()),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _openGuidelinesDialog(allGuidelines),
                            icon: const Icon(Icons.description),
                            label: const Text("Select Guidelines"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 5. Investigations/Lab Orders ---
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('5. Investigations/Lab Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                          const Divider(),
                          Text("Investigations Ordered (${_selectedInvestigations.length}):", style: const TextStyle(fontWeight: FontWeight.w600)),
                          Wrap(spacing: 8.0, children: _selectedInvestigations.map((name) => Chip(
                            label: Text(name),
                            backgroundColor: Colors.red.shade50,
                            // 🎯 FIX: Added onDeleted for Investigations
                            onDeleted: () => setState(() => _selectedInvestigations.remove(name)),
                            deleteIcon: const Icon(Icons.close, size: 18),
                          )).toList()),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _openInvestigationDialog(allInvestigations),
                            icon: const Icon(Icons.science),
                            label: const Text("Order Investigations"),
                          ),
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
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ASSIGN PLAN & INTERVENTIONS"),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}