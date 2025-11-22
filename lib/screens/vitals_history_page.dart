import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';
import 'package:nutricare_client_management/helper/lab_vitals_data.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/screens/vitals_entry_form_screen.dart' hide LabVitalsData;


// Uses the new data

class VitalsHistoryPage extends StatefulWidget {
  final String clientId;
  final String clientName;

  const VitalsHistoryPage({
    super.key,
    required this.clientId,
    required this.clientName
  });

  @override
  State<VitalsHistoryPage> createState() => _VitalsHistoryPageState();
}

class _VitalsHistoryPageState extends State<VitalsHistoryPage> {
  late Future<List<VitalsModel>> _vitalsFuture;
  VitalsService vitalsService = VitalsService();

  @override
  void initState() {
    super.initState();
    _vitalsFuture = _loadVitals();
  }

  Future<List<VitalsModel>> _loadVitals() {
    return vitalsService.getClientVitals(widget.clientId);
  }

  void _navigateAndRefresh(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
    setState(() {
      _vitalsFuture = _loadVitals();
    });
  }

  void _deleteRecord(VitalsModel record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete the record from ${DateFormat.yMMMd().format(record.date)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      try {
        await vitalsService.deleteVitals(widget.clientId, record.id);
        setState(() {
          _vitalsFuture = _loadVitals();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record deleted.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete record: $e')),
          );
        }
      }
    }
  }

  // 🎯 CORE LOGIC FIX: Ensures correct parsing of all range types (X-Y, <X, >Y).
  Color _getLabValueColor(String key, String value, {bool isMale = true}) {
    final test = LabVitalsData.allLabTests[key];
    if (test == null || value.isEmpty || test.referenceRange.isEmpty) {
      return Colors.black87;
    }

    try {
      final numValue = num.tryParse(value);
      if (numValue == null) return Colors.black87;

      // 1. Clean the reference range string from gender specifics
      String reference = test.referenceRange;
      if (reference.contains('(M)') || reference.contains('(F)')) {
        // For male, take the part before (M)
        if (isMale) {
          reference = reference.split('(M)').first.trim();
        } else {
          // For female, find the part containing (F), and remove the (F) tag.
          // This is a slightly more robust way to handle the second part of a comma-separated range.
          final femalePart = reference.split(',').last.trim();
          reference = femalePart.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
        }
        // Final fallback to remove any lingering gender tag
        reference = reference.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
      }

      // 2. Check and compare based on the cleaned reference string format

      // Standard Range: X - Y (e.g., "70 - 100")
      if (reference.contains('-')) {
        final parts = reference.split('-').map((s) => s.trim()).toList();
        if (parts.length == 2) {
          final min = num.tryParse(parts[0]);
          final max = num.tryParse(parts[1]);

          if (min != null && max != null && (numValue < min || numValue > max)) {
            return Colors.red.shade700; // Out of range
          }
        }
      }
      // Maximum Limit: < X (e.g., "< 200")
      else if (reference.trim().startsWith('<')) {
        // Extract the number after the '<' symbol
        final maxStr = reference.substring(reference.indexOf('<') + 1).trim();
        final max = num.tryParse(maxStr);
        if (max != null && numValue >= max) {
          return Colors.red.shade700; // Too high
        }
      }
      // Minimum Limit: > Y (e.g., "> 40")
      else if (reference.trim().startsWith('>')) {
        // Extract the number after the '>' symbol
        final minStr = reference.substring(reference.indexOf('>') + 1).trim();
        final min = num.tryParse(minStr);
        if (min != null && numValue <= min) {
          return Colors.red.shade700; // Too low
        }
      }

      return Colors.green.shade700; // In range

    } catch (e) {
      return Colors.black87; // Parsing error
    }
  }

  // Helper widget to build detail rows with value, label, and reference
  Widget _buildDetailRow(String label, String value, String reference, {Color? highlightColor, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Label
          SizedBox(
            width: 130, // Increased width for longer lab test names
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.blueGrey)),
          ),
          // Value (Color-coded)
          SizedBox(
            width: 80,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor ?? highlightColor ?? Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
          // Reference Range
          Expanded(
            child: Text(
              'Ref: $reference',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordActions(VitalsModel record) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          _navigateAndRefresh(VitalsEntryPage(
            clientId: widget.clientId,
            clientName: widget.clientName,
            vitalsToEdit: record, onVitalsSaved: () {  }, isFirstConsultation: record.isFirstConsultation,
          ));
        } else if (value == 'delete') {
          _deleteRecord(record);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete'),
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }

  Color _getStatusColor(VitalsModel record, List<VitalsModel> history) {
    final recordIndex = history.indexOf(record);
    if (recordIndex + 1 < history.length) {
      final previousRecord = history[recordIndex + 1];
      // Positive trend (weight loss) is green
      if (record.weightKg < previousRecord.weightKg) {
        return Colors.green;
      }
      // Negative trend (weight gain) is red
      else if (record.weightKg > previousRecord.weightKg) {
        return Colors.red;
      }
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text('Vitals list'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<VitalsModel>>(
          future: _vitalsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading data: ${snapshot.error}'));
            }
            // Sort by date descending (most recent first)
            final vitalsHistory = snapshot.data ?? [];
            vitalsHistory.sort((a, b) => b.date.compareTo(a.date));

            if (vitalsHistory.isEmpty) {
              return const Center(child: Text('No vitals records found. Tap "+" to add one.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: vitalsHistory.length,
              itemBuilder: (context, index) {
                final record = vitalsHistory[index];
                final trendColor = _getStatusColor(record, vitalsHistory);

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: trendColor.withOpacity(0.5), width: 2),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    leading: CircleAvatar(
                      backgroundColor: trendColor,
                      child: Text(
                        '${record.weightKg.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    title: Text(
                      DateFormat.yMMMd().format(record.date),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      record.bodyFatPercentage > 0
                          ? 'Weight: ${record.weightKg} kg, BFP: ${record.bodyFatPercentage}%'
                          : 'Weight: ${record.weightKg} kg',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    trailing: _buildRecordActions(record),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- Physical Vitals (Simplified) ---
                            _buildDetailRow('Weight', '${record.weightKg} kg', 'Physical Measurement', highlightColor: Colors.teal),
                            if (record.bodyFatPercentage > 0)
                              _buildDetailRow('Body Fat %', '${record.bodyFatPercentage}%', 'Physical Measurement', highlightColor: Colors.teal),

                            // --- Lab Results Grouped by Profile ---
                            if (record.labResults.isNotEmpty) ...[
                              const Divider(height: 20),

                              // Dynamic grouping and display of all lab results
                              ...LabVitalsData.labTestGroups.entries.map((entry) {
                                final groupName = entry.key;
                                final testKeys = entry.value;

                                // Filter to only include tests with results in the current record
                                final testsWithResults = testKeys
                                    .where((key) => record.labResults.containsKey(key) && record.labResults[key]!.isNotEmpty)
                                    .toList();

                                if (testsWithResults.isEmpty) return const SizedBox.shrink();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10.0, bottom: 8.0),
                                      child: Text(
                                          '--- $groupName ---',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey.shade700)
                                      ),
                                    ),
                                    ...testsWithResults.map((key) {
                                      final test = LabVitalsData.allLabTests[key];
                                      final value = record.labResults[key]!;
                                      final reference = test?.referenceRange ?? 'N/A';
                                      final unit = test?.unit ?? '';

                                      return _buildDetailRow(
                                        test?.displayName ?? key,
                                        '$value $unit',
                                        '$reference $unit',
                                        // Color code based on range check
                                        valueColor: _getLabValueColor(key, value, isMale: true),
                                      );
                                    }).toList(),
                                  ],
                                );
                              }).toList(),
                            ],

                            // --- Notes ---
                            if (record.notes?.isNotEmpty == true) ...[
                              const Divider(height: 20),
                              _buildDetailRow('Notes', record.notes!, 'Comments'),
                            ],

                            if (record.labReportUrls.isNotEmpty)
                              _buildDetailRow('Reports', 'View ${record.labReportUrls.length} files', 'Files'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),

      // --- FLOATING ACTION BUTTON (Create) ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateAndRefresh(VitalsEntryPage(
            clientId: widget.clientId,
            clientName: widget.clientName, onVitalsSaved: () {  }, isFirstConsultation: false,
          ));
        },
        child: const Icon(Icons.add),
        backgroundColor: colorScheme.secondary,
        tooltip: 'Add New Vitals Record',
      ),
    );
  }
}