import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/screens/vitals_entry_form_screen.dart';

class VitalsHistoryPage extends StatefulWidget {
  final String clientId;
  final String clientName;

  const VitalsHistoryPage({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<VitalsHistoryPage> createState() => _VitalsHistoryPageState();
}

class _VitalsHistoryPageState extends State<VitalsHistoryPage> {
  late Future<List<VitalsModel>> _vitalsFuture;
  final VitalsService _service = VitalsService();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _vitalsFuture = _service.getClientVitals(widget.clientId);
    });
  }

  // --- ACTIONS ---
  Future<void> _deleteRecord(VitalsModel record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Delete vitals record from ${DateFormat.yMMMd().format(record.date)}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteVitals(widget.clientId, record.id);
        _refresh();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Record deleted.")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  void _editRecord(VitalsModel record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VitalsEntryPage(
          clientId: widget.clientId,
          clientName: widget.clientName,
          onVitalsSaved: _refresh,
          isFirstConsultation: record.isFirstConsultation,
          vitalsToEdit: record,
        ),
      ),
    );
  }

  // =================================================================
  // 🎨 PREMIUM UI
  // =================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Premium background
      body: Stack(
        children: [
          // 1. Ambient Glow (Top Right)
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.1),
                    blurRadius: 80,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. Custom Header (No AppBar)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            "Vitals History",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      // Optional: Filter icon or similar could go here
                    ],
                  ),
                ),

                // 3. History List
                Expanded(
                  child: FutureBuilder<List<VitalsModel>>(
                    future: _vitalsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final list = snapshot.data ?? [];
                      // Ensure sorted by date desc
                      list.sort((a, b) => b.date.compareTo(a.date));

                      if (list.isEmpty) return _buildEmptyState();

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 80), // Bottom padding for FAB
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) => _buildPremiumCard(list[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // 4. Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VitalsEntryPage(
              clientId: widget.clientId,
              clientName: widget.clientName,
              onVitalsSaved: _refresh,
              isFirstConsultation: false,
            ),
          ),
        ),
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Log Vitals", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_heart_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No vitals recorded yet", style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(VitalsModel record) {
    final dateStr = DateFormat('dd MMM yyyy').format(record.date);

    // Calculate BMI Status for Color Coding
    Color statusColor = Colors.green;
    String statusLabel = "Normal";
    if (record.bmi > 25) {
      statusColor = Colors.orange;
      statusLabel = "Overweight";
    } else if (record.bmi > 30) {
      statusColor = Colors.red;
      statusLabel = "Obese";
    } else if (record.bmi < 18.5 && record.bmi > 0) {
      statusColor = Colors.blue;
      statusLabel = "Underweight";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today, size: 16, color: Colors.indigo),
                  ),
                  const SizedBox(width: 12),
                  Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.grey),
                onSelected: (val) => val == 'edit' ? _editRecord(record) : _deleteRecord(record),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text("Edit Record")),
                  const PopupMenuItem(value: 'delete', child: Text("Delete Record", style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),

          // Metrics Grid
          Row(
            children: [
              _buildMetricColumn("Weight", "${record.weightKg} kg", Icons.monitor_weight_outlined, Colors.blue),
              const SizedBox(width: 20),
              _buildMetricColumn("BMI", record.bmi > 0 ? record.bmi.toStringAsFixed(1) : "-", Icons.calculate_outlined, statusColor),
              const SizedBox(width: 20),
              _buildMetricColumn("BP", record.bloodPressureSystolic != null ? "${record.bloodPressureSystolic}/${record.bloodPressureDiastolic}" : "-", Icons.favorite_outline, Colors.red),
            ],
          ),

          // Lab & Clinical Badges
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (record.labResults.isNotEmpty)
                _buildBadge("${record.labResults.length} Labs", Colors.teal),
              if (record.diagnosis.isNotEmpty)
                _buildBadge("${record.diagnosis.length} Conditions", Colors.purple),
              if (record.prescribedMedications.isNotEmpty)
                _buildBadge("${record.prescribedMedications.length} Meds", Colors.orange),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}