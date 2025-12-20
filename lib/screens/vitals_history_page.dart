// lib/screens/vitals_history_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/screens/vitals_entry_form_screen.dart';

import '../master/model/diet_plan_item_model.dart';
final vitalsHistoryStreamProvider = StreamProvider.family<List<VitalsModel>, String>((ref, clientId) {
  final service = ref.watch(vitalsServiceProvider);
  return service.streamAllVitalsForClient(clientId);
});
class VitalsHistoryPage extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final String? sessionId; // 🎯 Added to link to the active consultation session

  const VitalsHistoryPage({
    super.key,
    required this.clientId,
    required this.clientName,
    this.sessionId, // 🎯 Received from Consultation Checklist
  });

  @override
  ConsumerState<VitalsHistoryPage> createState() => _VitalsHistoryPageState();
}

class _VitalsHistoryPageState extends ConsumerState<VitalsHistoryPage> {
  @override
  Widget build(BuildContext context) {
    final vitalsAsync = ref.watch(vitalsHistoryStreamProvider(widget.clientId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Consultation History"),
        actions: [
          // 🎯 Comparison Button: Shows history comparison
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            onPressed: () {
              vitalsAsync.whenData((history) {
                if (history.length < 2) return;
                // Navigate to VitalsComparisonScreen with full history
              });
            },
          ),
        ],
      ),
      body: vitalsAsync.when(
        data: (vitals) {
          if (vitals.isEmpty) return _buildEmptyState();

          final sortedVitals = List<VitalsModel>.from(vitals)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedVitals.length,
            itemBuilder: (context, index) {
              final vital = sortedVitals[index];
              // 🎯 Logic: Only the record matching the current session is editable
              final bool isCurrentSession = widget.sessionId != null &&
                  vital.sessionId == widget.sessionId;

              return _buildVitalsCard(vital, isCurrentSession: isCurrentSession);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleAddNew(context, ref.read(vitalsHistoryStreamProvider(widget.clientId)).value ?? []),
        label: const Text("New Consultation"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // 🎯 New unified card method with Edit/View logic
  Widget _buildVitalsCard(VitalsModel vital, {required bool isCurrentSession}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentSession ? Colors.deepPurple.withOpacity(0.5) : Colors.grey.shade200,
          width: isCurrentSession ? 2 : 1,
        ),
      ),
      child: ListTile(
        title: Text(DateFormat('dd MMM yyyy').format(vital.date)),
        subtitle: Text("Weight: ${vital.weightKg}kg • BMI: ${vital.bmi}"),
        // 🎯 If not the current session, it's read-only
        trailing: Icon(
          isCurrentSession ? Icons.edit : Icons.visibility,
          color: isCurrentSession ? Colors.deepPurple : Colors.grey,
        ),
        onTap: () => _navigateToEntry(vital, isReadOnly: !isCurrentSession),
      ),
    );
  }

  // 🎯 Single Entry Logic: Prevents multiple vitals in one session
  void _handleAddNew(BuildContext context, List<VitalsModel> history) {
    if (widget.sessionId == null) return;

    // Check if a record already exists for this active session
    final sessionRecord = history.firstWhereOrNull((v) => v.sessionId == widget.sessionId);

    if (sessionRecord != null) {
      // If exists, route to Edit mode instead of New
      _navigateToEntry(sessionRecord, isReadOnly: false);
    } else {
      _navigateToEntry(null, isReadOnly: false);
    }
  }

  void _navigateToEntry(VitalsModel? vital, {required bool isReadOnly}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VitalsEntryScreen(
          clientId: widget.clientId,
          clientName: widget.clientName,
          vitalToEdit: vital,
          sessionId: widget.sessionId, // 🎯 Pass session ID to link data
          isReadOnly: isReadOnly,      // 🎯 Pass read-only constraint
          onVitalsSaved: () => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
              Icons.monitor_weight_outlined,
              size: 80,
              color: Colors.grey.shade300
          ),
          const SizedBox(height: 20),
          const Text(
              "No Consultation History",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey
              )
          ),
          const SizedBox(height: 8),
          const Text(
              "Add your first vitals to start the plan.",
              style: TextStyle(color: Colors.grey)
          ),
        ],
      ),
    );
  }
}