import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/screens/vitals_entry_form_screen.dart';
import 'package:nutricare_client_management/admin/labvital/vitals_comprasion_screen.dart';

final vitalsHistoryStreamProvider = StreamProvider.family<List<VitalsModel>, String>((ref, clientId) {
  final service = ref.watch(vitalsServiceProvider);
  return service.streamAllVitalsForClient(clientId);
});

class VitalsHistoryPage extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final String? activeSessionId;

  const VitalsHistoryPage({
    super.key,
    required this.clientId,
    required this.clientName,
    this.activeSessionId,
  });

  @override
  ConsumerState<VitalsHistoryPage> createState() => _VitalsHistoryPageState();
}

class _VitalsHistoryPageState extends ConsumerState<VitalsHistoryPage> {

  // 識 MODIFIED: Replaced showModalBottomSheet with Navigator.push for Full Screen
  void _openVitalForm(BuildContext context, {VitalsModel? existingVital, VitalsModel? previousVital}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VitalsEntryScreen(
          clientId: widget.clientId,
          clientName: widget.clientName,
          sessionId: widget.activeSessionId,
          vitalToEdit: existingVital,
          previousVital: previousVital,
          isReadOnly: false,
          onVitalsSaved: () {
            Navigator.pop(context); // Close the full screen page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Vitals updated successfully"),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vitalsAsync = ref.watch(vitalsHistoryStreamProvider(widget.clientId));

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: vitalsAsync.when(
          data: (vitalsList) {
            final currentSessionVital = vitalsList.firstWhereOrNull(
                    (v) => v.sessionId == widget.activeSessionId && widget.activeSessionId != null
            );

            final archivedVitals = vitalsList.where(
                    (v) => v.sessionId != widget.activeSessionId
            ).toList();

            final lastHistoryVital = archivedVitals.firstOrNull;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          shadowColor: Colors.black12,
                          elevation: 2,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          "Vitals History",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => VitalsComparisonScreen(
                                      clientId: widget.clientId,
                                      clientName: widget.clientName
                                  )
                              )
                          );
                        },
                        icon: const Icon(Icons.analytics_outlined, size: 18),
                        label: const Text("Compare"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                    ],
                  ),
                ),
                _buildSectionHeader("CURRENT CONSULTATION"),

                if (currentSessionVital != null)
                  _buildVitalCard(
                      context,
                      currentSessionVital,
                      isArchived: false,
                      previous: lastHistoryVital
                  )
                else if (widget.activeSessionId != null)
                  _buildAddVitalButton(context, lastHistoryVital)
                else
                  _buildNoActiveSessionWarning(),

                const SizedBox(height: 24),

                if (archivedVitals.isNotEmpty) ...[
                  _buildSectionHeader("ARCHIVED RECORDS"),
                  ...archivedVitals.map((v) => _buildVitalCard(context, v, isArchived: true)),
                ] else if (currentSessionVital == null)
                  _buildEmptyState(),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text("Error: $e")),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.indigo.shade900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildVitalCard(BuildContext context, VitalsModel vital, {required bool isArchived, VitalsModel? previous}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isArchived ? Colors.white.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isArchived ? Colors.grey.shade200 : Colors.indigo.shade100,
          width: 1.5,
        ),
        boxShadow: isArchived ? [] : [BoxShadow(color: Colors.indigo.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isArchived ? Colors.grey.shade100 : Colors.indigo.shade50,
          child: Icon(
            isArchived ? Icons.archive_outlined : Icons.monitor_weight_outlined,
            color: isArchived ? Colors.grey : Colors.indigo,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              isArchived ? "Session Archive" : "Active Consultation",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isArchived ? Colors.grey.shade600 : Colors.black87,
              ),
            ),
            if (!isArchived)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text("EDITABLE", style: TextStyle(color: Colors.green.shade700, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd MMM yyyy • hh:mm a').format(vital.date),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              "Weight: ${vital.weightKg}kg | BMI: ${vital.bmi?.toStringAsFixed(1) ?? 'N/A'}",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
          ],
        ),
        trailing: isArchived
            ? _buildLockedBadge()
            : IconButton(
          icon: const Icon(Icons.edit_note, color: Colors.indigo),
          onPressed: () => _openVitalForm(context, existingVital: vital, previousVital: previous),
        ),
      ),
    );
  }

  Widget _buildAddVitalButton(BuildContext context, VitalsModel? previous) {
    return InkWell(
      onTap: () => _openVitalForm(context, previousVital: previous),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.indigo.withOpacity(0.1), style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            const Icon(Icons.add_chart_rounded, color: Colors.indigo, size: 32),
            const SizedBox(height: 12),
            const Text("Record Session Vitals", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 4),
            Text("No data recorded for this consultation yet", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
      child: const Text("ARCHIVED", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildNoActiveSessionWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_clock_outlined, color: Colors.amber.shade900, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "New entries are only allowed during an active consultation session.",
              style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Text("No historical records found.", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
      ),
    );
  }
}