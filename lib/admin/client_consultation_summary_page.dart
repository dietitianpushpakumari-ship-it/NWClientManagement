import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// MODELS
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/medical/models/prescription_model.dart';

// SCREENS & SERVICES
import 'package:nutricare_client_management/screens/vitals_history_page.dart';
import 'package:nutricare_client_management/admin/clinical_prescription_printer.dart';

class ClinicalConsultationSummaryPage extends ConsumerWidget {
  final ClientModel client;

  const ClinicalConsultationSummaryPage({
    super.key,
    required this.client,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(vitalsHistoryStreamProvider(client.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Clinical Timeline", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black)),
            Text(client.name, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_alt, color: Colors.indigo),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Filter functionality coming soon")));
            },
          ),
        ],
      ),
      body: historyAsync.when(
        data: (records) {
          if (records.isEmpty) return _buildEmptyState();

          // 1. Sort Records: Newest First
          final sortedRecords = List<VitalsModel>.from(records)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: sortedRecords.length,
            itemBuilder: (context, index) {
              final current = sortedRecords[index];
              // Previous record is the one *after* current in a descending list
              final previous = (index + 1 < sortedRecords.length) ? sortedRecords[index + 1] : null;
              final isLast = index == sortedRecords.length - 1;

              return _buildTimelineItem(context, current, previous, isLast);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error loading history: $e")),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.history_edu, size: 48, color: Colors.indigo.withOpacity(0.3)),
          ),
          const SizedBox(height: 16),
          Text("No clinical records found.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- TIMELINE STRUCTURE ---
  Widget _buildTimelineItem(BuildContext context, VitalsModel record, VitalsModel? previous, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Timeline Indicator
          Column(
            children: [
              Container(
                width: 44,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.indigo.withOpacity(0.1)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
                ),
                child: Column(
                  children: [
                    Text(DateFormat('dd').format(record.date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                    Text(DateFormat('MMM').format(record.date).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(1)))),
            ],
          ),
          const SizedBox(width: 16),

          // 2. Card Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildClinicalCard(context, record, previous),
            ),
          ),
        ],
      ),
    );
  }

  // --- PREMIUM CARD ---
  Widget _buildClinicalCard(BuildContext context, VitalsModel current, VitalsModel? previous) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(DateFormat('hh:mm a').format(current.date), style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                Row(
                  children: [
                    if (current.isFirstConsultation) ...[
                      _buildTag("INITIAL VISIT", Colors.purple),
                      const SizedBox(width: 8),
                    ],
                    // 🎯 REPRINT BUTTON
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ClinicalPrescriptionPrinter(client: client, vitals: current)
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.print, size: 16, color: Colors.indigo),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),

          // B. Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Smart Vitals
                _buildVitalsRow(current, previous),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // 2. Diagnosis & Complaints (Grouped)
                if ((current.nutritionDiagnoses?.isNotEmpty ?? false) || (current.clinicalComplaints?.isNotEmpty ?? false)) ...[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (current.clinicalComplaints?.isNotEmpty ?? false)
                      Expanded(child: _buildDataColumn("Complaints", current.clinicalComplaints!, Colors.deepOrange, Icons.sick_outlined)),
                    if ((current.clinicalComplaints?.isNotEmpty ?? false) && (current.nutritionDiagnoses?.isNotEmpty ?? false))
                      const SizedBox(width: 16),
                    if (current.nutritionDiagnoses?.isNotEmpty ?? false)
                      Expanded(child: _buildDataColumn("Diagnosis", current.nutritionDiagnoses!, Colors.indigo, Icons.assignment_outlined)),
                  ]),
                  const SizedBox(height: 20),
                ],

                // 3. Rx (Prescriptions)
                if (current.medications.isNotEmpty) ...[
                  _buildSectionLabel("Prescriptions (Rx)", Icons.medication_outlined, Colors.blue),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: current.medications.map((m) => _buildMedicineChip(m)).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // 4. Lab Orders
                if (current.labTestOrders.isNotEmpty) ...[
                  _buildSectionLabel("Lab Orders", Icons.science_outlined, Colors.teal),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: current.labTestOrders.map((l) => Chip(
                      label: Text(l, style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w600)),
                      backgroundColor: Colors.teal.shade50,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // 5. Notes
                if (current.clinicalNotes?.isNotEmpty ?? false) ...[
                  _buildSectionLabel("Clinical Notes", Icons.notes, Colors.blueGrey),
                  const SizedBox(height: 8),
                  ...current.clinicalNotes!.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                        children: [
                          TextSpan(text: "${e.key}: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: e.value, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 📊 SMART VITALS ROW ---
  Widget _buildVitalsRow(VitalsModel current, VitalsModel? previous) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildVitalTrend("Weight", current.weightKg, previous?.weightKg, "kg"),
        _buildVerticalDivider(),
        _buildVitalTrend("BMI", current.bmi ?? 0, previous?.bmi, ""),
        _buildVerticalDivider(),
        _buildVitalTrend("Body Fat", current.bodyFatPercentage, previous?.bodyFatPercentage, "%"),
        _buildVerticalDivider(),
        _buildVitalStatic("BP", "${current.bloodPressureSystolic ?? '--'}/${current.bloodPressureDiastolic ?? '--'}"),
      ],
    );
  }

  Widget _buildVerticalDivider() => Container(width: 1, height: 24, color: Colors.grey.shade200);

  Widget _buildVitalTrend(String label, double val, double? prev, String unit) {
    if (val == 0) return _buildVitalStatic(label, "--");

    double diff = prev != null ? val - prev : 0;
    Color color = Colors.black87;
    IconData? icon;
    String diffText = "";

    if (prev != null && diff.abs() > 0.1) {
      if (diff > 0) {
        color = Colors.redAccent;
        icon = Icons.arrow_upward;
        diffText = "+${diff.abs().toStringAsFixed(1)}";
      } else {
        color = Colors.green;
        icon = Icons.arrow_downward;
        diffText = "-${diff.abs().toStringAsFixed(1)}";
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("${val.toStringAsFixed(1)}$unit", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(icon, size: 10, color: color),
                    Text(diffText, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ]
          ],
        ),
      ],
    );
  }

  Widget _buildVitalStatic(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
      ],
    );
  }

  // --- SECTIONS ---
  Widget _buildDataColumn(String title, Map<String, String> data, Color color, IconData icon) {
    if (data.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 3, height: 12, color: color, margin: const EdgeInsets.only(right: 6)),
          Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 8),
        ...data.entries.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.1))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              if (e.value != 'Not specified')
                Text(e.value, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.2)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildMedicineChip(PrescribedMedicine med) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade100),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(med.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blue.shade900)),
          const SizedBox(height: 2),
          Text("${med.dosage}  •  ${med.frequency}  •  ${med.duration}", style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
          if(med.instruction.isNotEmpty)
            Text(med.instruction, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
    ]);
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}