import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/screens/vitals_history_page.dart';

class ClinicalConsultationSummaryPage extends ConsumerWidget {
  final String clientId;
  final String clientName;

  const ClinicalConsultationSummaryPage({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reusing the existing vitals stream which contains the clinical maps
    final historyAsync = ref.watch(vitalsHistoryStreamProvider(clientId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text("Clinical History: $clientName"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: historyAsync.when(
        data: (records) {
          if (records.isEmpty) return const Center(child: Text("No clinical records found"));

          final sortedRecords = List<VitalsModel>.from(records)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedRecords.length,
            itemBuilder: (context, index) => _buildClinicalEntry(sortedRecords[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildClinicalEntry(VitalsModel record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('dd MMM yyyy').format(record.date),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              const Icon(Icons.history_edu, size: 16, color: Colors.grey),
            ],
          ),
          const Divider(height: 24),
          _buildDetailList("Complaints", record.clinicalComplaints, Colors.deepOrange),
          _buildDetailList("Diagnoses", record.nutritionDiagnoses, Colors.indigo),
          _buildDetailList("Clinical Notes", record.clinicalNotes, Colors.blueGrey),
        ],
      ),
    );
  }

  Widget _buildDetailList(String title, Map<String, String>? data, Color color) {
    if (data == null || data.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          ...data.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text("• ${e.key}: ${e.value}", style: const TextStyle(fontSize: 13)),
          )),
        ],
      ),
    );
  }
}