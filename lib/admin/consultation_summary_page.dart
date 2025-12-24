import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/screens/vitals_history_page.dart';

class ConsultationSummaryPage extends ConsumerWidget {
  final String clientId;
  final String clientName;

  const ConsultationSummaryPage({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(vitalsHistoryStreamProvider(clientId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text("$clientName - Full History"),
        elevation: 0,
      ),
      body: historyAsync.when(
        data: (records) {
          if (records.isEmpty) return const Center(child: Text("No history available"));

          // Sort by date descending
          final sortedRecords = List<VitalsModel>.from(records)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedRecords.length,
            itemBuilder: (context, index) => _buildSessionRecord(context, sortedRecords[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildSessionRecord(BuildContext context, VitalsModel record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        title: Text(
          DateFormat('dd MMM yyyy').format(record.date),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        subtitle: Text("Consultation ID: ${record.sessionId ?? 'General Record'}"),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHistorySection("Diet & Hydration", [
                  "Food Habit: ${record.foodHabit ?? '--'}",
                  "Water: ${record.waterIntake?.keys.join(', ') ?? '--'}",
                  "Allergies: ${record.foodAllergies.isEmpty ? 'None' : record.foodAllergies.join(', ')}",
                ], Colors.orange),
                _buildHistorySection("Medical & Medications", [
                  "Conditions: ${record.medicalHistory.keys.join(', ') ?? 'None'}",
                  "Prescribed: ${record.prescribedMedications.keys.join(', ') ?? 'None'}",
                  "GI Details: ${record.giDetails?.keys.join(', ') ?? 'Normal'}",
                ], Colors.blue),
                _buildHistorySection("Lifestyle & Habits", [
                  "Activity: ${record.activityType ?? '--'}",
                  "Sleep: ${record.sleepQuality ?? '--'}",
                  "Stress Level: ${record.stressLevel ?? '--'}/10",
                  "Habits: ${record.otherLifestyleHabits?.keys.join(', ') ?? 'None'}",
                ], Colors.purple),
                if (record.menstrualStatus != null)
                  _buildHistorySection("Women's Health", [
                    "Status: ${record.menstrualStatus}",
                  ], Colors.pink),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(String title, List<String> details, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, color: color),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        ...details.map((d) => Padding(
          padding: const EdgeInsets.only(left: 11, bottom: 4),
          child: Text(d, style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
        )),
        const Divider(height: 24),
      ],
    );
  }
}