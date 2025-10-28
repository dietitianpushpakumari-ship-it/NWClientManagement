// lib/widgets/LabVitalsHistoryWidget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 🎯 ADJUST THESE IMPORTS TO YOUR PROJECT STRUCTURE
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/screens/vitals_entry_form_screen.dart'; // To get LabTest definition

// Placeholder for LabTest definitions (must exist in your project)
class LabTest {
  final String displayName;
  final String unit;
  final String referenceRange;
  const LabTest(this.displayName, this.unit, this.referenceRange);
}
// Placeholder for the static data source
class LabVitalsData {
  static const Map<String, LabTest> allLabTests = {
    'hba1c': LabTest('HbA1c', '%', '4.0 - 5.6'),
    'fasting_glucose': LabTest('Fasting Glucose', 'mg/dL', '70 - 99'),
    // ... add your actual lab tests here
  };
}


class LabVitalsHistoryWidget extends StatelessWidget {
  final List<VitalsModel> clientVitals;

  final Map<String, LabTest> allLabTests = LabVitalsData.allLabTests;

  const LabVitalsHistoryWidget({
    super.key,
    required this.clientVitals,
  });

  Widget _buildClinicalDetailRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter out entries that don't have any lab results, or keep all entries for clinical history display
    // We will show all entries that have notes or lab results
    final vitalsWithData = clientVitals.where(
            (v) => v.labResults.isNotEmpty || (v.notes != null && v.notes!.isNotEmpty)
    ).toList();

    if (vitalsWithData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No historical data found for this client.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vitalsWithData.length,
      itemBuilder: (context, index) {
        final vital = vitalsWithData[index];
        final formattedDate = DateFormat.yMMMd().format(vital.date);

        // --- Clinical Summary Extraction ---
        // Assuming chronic medical history, complaint, and medication/allergies
        // are stored in the notes or otherLifestyleHabits map.
        final medication = vital.otherLifestyleHabits?['medication'];
        final allergies = vital.otherLifestyleHabits?['allergies'];
        // Using 'notes' for general medical history/complaint
        final clinicalNotes = vital.notes;

        // Convert lab results into a list of [TestName, Result, Unit, ReferenceRange]
        final labRows = vital.labResults.entries.map((entry) {
          final testKey = entry.key;
          final resultValue = entry.value;
          final testDetails = allLabTests[testKey];

          return [
            testDetails?.displayName ?? testKey.toUpperCase(),
            resultValue,
            testDetails?.unit ?? '',
            testDetails?.referenceRange ?? 'N/A',
          ];
        }).toList();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ExpansionTile(
            title: Text(
              'Vitals Record - $formattedDate',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Weight: ${vital.weightKg} kg | Labs: ${labRows.length}'),
            children: [
              // 🎯 NEW SECTION: Clinical Summary
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clinical Summary',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const Divider(height: 10),
                    _buildClinicalDetailRow('Med. History/Notes', clinicalNotes),
                    _buildClinicalDetailRow('Existing Medication', medication),
                    _buildClinicalDetailRow('Allergies', allergies),

                    if (labRows.isNotEmpty) const SizedBox(height: 16),
                    if (labRows.isNotEmpty)
                      const Text(
                        'Lab Results',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),

                    // --- Lab Results Table ---
                    if (labRows.isNotEmpty)
                      Table(
                        border: TableBorder.all(color: Colors.grey.shade300),
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(1.5),
                          3: FlexColumnWidth(3),
                        },
                        children: [
                          // Header Row
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade100),
                            children: const [
                              Padding(padding: EdgeInsets.all(8.0), child: Text('Test', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text('Result', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text('Ref. Range', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                          // Data Rows
                          ...labRows.map((row) => TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(8.0), child: Text(row[0], style: const TextStyle(fontSize: 13))),
                              Padding(padding: const EdgeInsets.all(8.0), child: Text(row[1], style: const TextStyle(fontSize: 13))),
                              Padding(padding: const EdgeInsets.all(8.0), child: Text(row[2], style: const TextStyle(fontSize: 13))),
                              Padding(padding: const EdgeInsets.all(8.0), child: Text(row[3], style: const TextStyle(fontSize: 13))),
                            ],
                          )).toList(),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}