import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/labvital/vitals_comprasion_screen.dart';

// 🎯 Project Imports
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/screens/vitals_entry_form_screen.dart';

// ------------------------------------------------------------------
// 1. RIVERPOD STREAM PROVIDER (Specific to this page's need)
// ------------------------------------------------------------------

// Creates a stream provider that takes clientId and returns the list of vitals.
final vitalsHistoryStreamProvider = StreamProvider.family<List<VitalsModel>, String>((ref, clientId) {
  final service = ref.watch(vitalsServiceProvider);
  return service.streamAllVitalsForClient(clientId);
});


// ------------------------------------------------------------------
// 2. VITALS HISTORY PAGE (ConsumerWidget)
// ------------------------------------------------------------------

class VitalsHistoryPage extends ConsumerWidget {
  final String clientId;
  final String clientName;

  const VitalsHistoryPage({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  void _navigateToEntry(BuildContext context, VitalsModel? vital) {
    // Navigate to a form to add new or edit existing vital record
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VitalsEntryScreen(
          clientId: clientId,
          clientName: clientName,
          vitalToEdit: vital,
          onVitalsSaved: () {
            // Callback logic handles state sync in the calling screen
            // (e.g., ClientConsultationChecklistScreen)
          },
          isFirstConsultation: false,
        ),
      ),
    );
  }


  void _confirmDelete(BuildContext context, VitalsService service, VitalsModel vital) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete the record from ${DateFormat('MMM dd, yyyy').format(vital.date)}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await service.deleteVitals(vital.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // 🎯 NEW: Custom Header Widget
  Widget _buildCustomHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Back Button and Title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
              Text(
                '${clientName}\'s Vitals History',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),

          // Right: Action Buttons
          IconButton(
            icon: const Icon(Icons.show_chart_outlined, color: Colors.blue),
            tooltip: 'Progress Analysis',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VitalsComparisonScreen(
                    clientId: clientId,
                    clientName: clientName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the stream provider, which automatically rebuilds on new data/tenant switch
    final vitalsAsync = ref.watch(vitalsHistoryStreamProvider(clientId));
    final vitalsService = ref.read(vitalsServiceProvider); // Read service for CRUD actions

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),

      // 🎯 REMOVED AppBar and replaced with custom Body content
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎯 FIX: Inject Custom Header here
          _buildCustomHeader(context, ref),

          // 🎯 FIX: Use Expanded to make the ListView fill the remaining space
          Expanded(
            child: vitalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading history: $err')),
              data: (vitalsList) {
                if (vitalsList.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.monitor_heart_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("No vitals recorded yet.", style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 50),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vitalsList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final vital = vitalsList[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                        // Leading: Quick Metrics
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("${vital.weightKg.toStringAsFixed(1)} kg", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                            Text("Weight", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                          ],
                        ),

                        // Title: Date
                        title: Text(
                          DateFormat('EEE, dd MMM yyyy').format(vital.date),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        // Subtitle: Core Vitals Summary
                        subtitle: Text(
                          "BMI: ${vital.bmi.toStringAsFixed(1)} | BP: ${vital.bloodPressureSystolic ?? '-'}/${vital.bloodPressureDiastolic ?? '-'}",
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),

                        // Trailing: Actions
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _navigateToEntry(context, vital),
                              tooltip: 'Edit Record',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(context, vitalsService, vital),
                              tooltip: 'Delete Record',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add),
        label: const Text("Add New Record"),
        onPressed: () => _navigateToEntry(context, null),
      ),
    );
  }
}