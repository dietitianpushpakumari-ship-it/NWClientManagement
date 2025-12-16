import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/modules/master/service/diagonosis_master_service.dart';
import 'package:nutricare_client_management/master/model/diagonosis_master.dart';

class VitalsPickerSheet extends ConsumerStatefulWidget {
  final String clientId;
  final String? selectedId;

  const VitalsPickerSheet({
    super.key,
    required this.clientId,
    this.selectedId,
  });

  @override
  ConsumerState<VitalsPickerSheet> createState() => _VitalsPickerSheetState();
}

class _VitalsPickerSheetState extends ConsumerState<VitalsPickerSheet> {


  late Future<List<VitalsModel>> _vitalsFuture;
  Map<String, String> _diagnosisNames = {}; // Map ID -> Name
  bool _isLoadingNames = true;

  @override
  void initState() {
    super.initState();
    _fetchVitalsData();
    _loadDiagnosisNames();
  }

  void _fetchVitalsData() {
    // 🎯 FIX 1: Access VitalsService via Riverpod and use the correct method name
    final vitalsService = ref.read(vitalsServiceProvider);

    // Assuming getClientVitals was added back to the service definition
    _vitalsFuture = vitalsService.getClientVitals(widget.clientId);
  }

  // Fetch all diagnoses once to resolve IDs to Names
  Future<void> _loadDiagnosisNames() async {
    try {
      final diagnosisService = ref.watch(diagnosisMasterServiceProvider);
      final allDiagnoses = await diagnosisService.fetchAllDiagnosisMaster();
      if (mounted) {
        setState(() {
          _diagnosisNames = {for (var d in allDiagnoses) d.id: d.enName};
          _isLoadingNames = false;
        });
      }
    } catch (e) {
      // Fallback: just show IDs or empty if fails
      if (mounted) setState(() => _isLoadingNames = false);
    }
  }

  // Helper to get comma-separated names from a list of IDs
  String _getReadableConditions(List<String> ids) {
    if (ids.isEmpty) return "None";
    if (_isLoadingNames) return "Loading...";

    final names = ids.map((id) => _diagnosisNames[id] ?? id).toList();
    return names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 1. Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Select Vitals Record", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. List
          Expanded(
            child: FutureBuilder<List<VitalsModel>>(
              future: _vitalsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final list = snapshot.data ?? [];
                // Sort: Newest First
                list.sort((a, b) => b.date.compareTo(a.date));

                if (list.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.monitor_heart_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("No vitals recorded yet.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final vital = list[index];
                    final isSelected = vital.id == widget.selectedId;

                    return GestureDetector(
                      onTap: () => Navigator.pop(context, vital),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : Border.all(color: Colors.transparent),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Date & Selection
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat('EEE, dd MMM yyyy').format(vital.date),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                if (isSelected)
                                   Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20)
                                else
                                  const Icon(Icons.circle_outlined, color: Colors.grey, size: 20),
                              ],
                            ),
                            const Divider(height: 20),

                            // Metrics Preview
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetric("Weight", "${vital.weightKg} kg"),
                                _buildMetric("BMI", vital.bmi.toStringAsFixed(1)),
                                _buildMetric("BP", "${vital.bloodPressureSystolic ?? '-'}/${vital.bloodPressureDiastolic ?? '-'}"),
                                _buildMetric("Sugar (F)", vital.labResults['fbs'].toString() ?? '-'),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Conditions (Resolved Name)
                            if (vital.diagnosis.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Conditions: ${_getReadableConditions(vital.diagnosis)}",
                                  style: TextStyle(fontSize: 12, color: Colors.purple.shade900, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}