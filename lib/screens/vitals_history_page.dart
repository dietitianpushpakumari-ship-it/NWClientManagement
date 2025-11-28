import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/screens/vitals_entry_form_screen.dart';

class VitalsHistoryPage extends StatefulWidget {
  final String clientId;
  final String clientName;

  const VitalsHistoryPage({super.key, required this.clientId, required this.clientName});

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
    setState(() => _vitalsFuture = _service.getClientVitals(widget.clientId));
  }

  Future<void> _deleteRecord(VitalsModel record) async {
    // ... (Same logic as before) ...
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Deletion"),
        content: Text("Delete vitals from ${DateFormat.yMMMd().format(record.date)}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteVitals(widget.clientId, record.id);
      _refresh();
    }
  }

  void _editRecord(VitalsModel record) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => VitalsEntryPage(clientId: widget.clientId, clientName: widget.clientName, onVitalsSaved: _refresh, isFirstConsultation: record.isFirstConsultation, vitalsToEdit: record)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VitalsEntryPage(clientId: widget.clientId, clientName: widget.clientName, onVitalsSaved: _refresh, isFirstConsultation: false))),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Log Vitals", style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -80, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: FutureBuilder<List<VitalsModel>>(
                    future: _vitalsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final list = snapshot.data ?? [];
                      if (list.isEmpty) return const Center(child: Text("No records found."));

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
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
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
            const SizedBox(width: 16),
            const Text("Vitals History", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }

  Widget _buildPremiumCard(VitalsModel record) {
    final dateStr = DateFormat('dd MMM yyyy').format(record.date);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            PopupMenuButton<String>(onSelected: (v) => v == 'edit' ? _editRecord(record) : _deleteRecord(record), itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text("Edit")), const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red)))])
          ]),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildMetric("Weight", "${record.weightKg} kg"),
            _buildMetric("BMI", record.bmi.toStringAsFixed(1)),
            _buildMetric("BP", "${record.bloodPressureSystolic ?? '-'}/${record.bloodPressureDiastolic ?? '-'}"),
          ])
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String val) {
    return Column(children: [Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary)), Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))]);
  }
}