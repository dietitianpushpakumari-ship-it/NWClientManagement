import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// 🎯 Project Imports
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/helper/lab_vitals_data.dart';

import 'global_service_provider.dart'; // Contains LabTestConfig definitions

// Assuming vitalsServiceProvider is defined in vitals_service.dart

class VitalsComparisonScreen extends ConsumerWidget {
  final String clientId;
  final String clientName;

  const VitalsComparisonScreen({
    super.key,
    required this.clientId,
    required this.clientName
  });

  // --- 1. CORE LOGIC: COLOR CODING ---

  /// Determines the color based on the value compared to the reference range.
  Color _getColorCode(double value, String labKey) {
    final LabTestConfig? config = LabVitalsData.allLabTests[labKey];
    if (config == null) return Colors.grey;

    final double? min = config.minRange;
    final double? max = config.maxRange;

    // Default to in range
    bool isWithinRange = true;

    if (min != null && value < min) isWithinRange = false;
    if (max != null && value > max) isWithinRange = false;

    // Apply color logic based on range check and reverse logic (e.g., HDL)
    if (isWithinRange) {
      return Colors.green; // In Range (Healthy)
    } else {
      // Out of Range
      // Check for 'Reverse Logic' tests (e.g., HDL, where high is good)
      if (config.isReverseLogic) {
        // If it's reverse logic and value is below MIN, it's unhealthy (Red)
        if (min != null && value < min) return Colors.red;
        // If it's above max (or simply outside) and reverse logic, treat as acceptable/healthy for visual simplicity
        return Colors.green;
      }

      // Standard logic: if out of range (High or Low), it's bad
      return Colors.red;
    }
  }

  // --- 2. WIDGET HELPERS ---

  /// Builds a color-coded chip for the numerical vital value.
  Widget _buildValueChip(double? value, String labKey) {
    if (value == null) {
      return const Text('-', style: TextStyle(fontSize: 14));
    }

    final Color color = _getColorCode(value, labKey);
    // Display value without decimals if it's a whole number
    final String displayValue = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);

    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5))
      ),
      child: Center(
        child: Text(
          displayValue,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  /// Builds the Data Table by pivoting the chronological list.
  Widget _buildComparisonView(BuildContext context, List<VitalsModel> vitalsList) {
    // 1. Collect all unique lab keys recorded across all entries
    final Set<String> allLabKeys = vitalsList
        .expand((v) => v.labResults.keys)
        .toSet();

    // 2. Filter keys to only include those defined in LabVitalsData (for stability)
    final List<String> orderedLabKeys = LabVitalsData.allLabTests.keys
        .where((key) => allLabKeys.contains(key))
        .toList();

    // 3. Create a list of dates for the table headers
    final List<String> dateHeaders = vitalsList.map((v) => DateFormat('MMM dd, yy').format(v.date)).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'Historical Progress Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 16),

          // Use a SingleChildScrollView horizontally for the comparison table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(Colors.indigo.shade50),
                columns: [
                  // Column 1: Vital Name (Fixed)
                  const DataColumn(label: Text('Vital / Lab Test', style: TextStyle(fontWeight: FontWeight.bold))),
                  // Columns for each recorded date
                  for (final header in dateHeaders)
                    DataColumn(label: SizedBox(width: 70, child: Center(child: Text(header, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 12))))),
                ],
                rows: orderedLabKeys.map((key) {
                  final LabTestConfig? config = LabVitalsData.allLabTests[key];
                  final String vitalName = config?.displayName ?? key;
                  final String vitalUnit = config?.unit ?? '';

                  // Display range for context
                  final String vitalRange = config?.referenceRangeDisplay ?? 'N/A';

                  return DataRow(
                    cells: [
                      // Cell 1: Vital Name, Range, and Unit
                      DataCell(SizedBox(width: 150, child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(vitalName, style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('Range: ${vitalRange} ${vitalUnit}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        ],
                      ))),

                      // Remaining Cells: Historical Values
                      ...vitalsList.map((vitals) {
                        final double? value = vitals.labResults[key];

                        return DataCell(
                            Center(child: _buildValueChip(value, key))
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. WIDGET BUILDER ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎯 Access the Riverpod service and stream the data
    final vitalsService = ref.watch(vitalsServiceProvider);

    final vitalsAsync = ref.watch(
        StreamProvider.autoDispose((ref) => vitalsService.streamAllVitalsForClient(clientId))
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('${clientName} - Vitals Comparison'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: vitalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading data: $err')),
        data: (vitalsList) {
          if (vitalsList!.isEmpty) {
            return const Center(child: Text('No historical vital records found for comparison.'));
          }

          return _buildComparisonView(context, vitalsList);
        },
      ),
    );
  }
}