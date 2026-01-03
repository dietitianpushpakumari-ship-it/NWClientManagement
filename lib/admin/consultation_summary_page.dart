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
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Lifestyle & History Timeline", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(clientName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Future: Add date filter or type filter
            },
          )
        ],
      ),
      body: historyAsync.when(
        data: (records) {
          if (records.isEmpty) return _buildEmptyState();

          // 1. Sort Newest First
          final sortedRecords = List<VitalsModel>.from(records)
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedRecords.length,
            itemBuilder: (context, index) {
              final current = sortedRecords[index];
              final previous = (index + 1 < sortedRecords.length) ? sortedRecords[index + 1] : null;

              return _buildPremiumHistoryCard(current, previous);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No history records found.", style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // 🎯 ULTRA PREMIUM CARD
  Widget _buildPremiumHistoryCard(VitalsModel current, VitalsModel? previous) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.calendar_today, size: 16, color: Colors.indigo),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('dd MMM yyyy').format(current.date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(DateFormat('hh:mm a').format(current.date), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                if (current.isFirstConsultation)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                    child: const Text("FIRST VISIT", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📊 1. VITALS TREND (Context)
                _buildVitalsTrendRow(current, previous),
                const Divider(height: 32),

                // 🧠 2. LIFESTYLE METRICS (Visual)
                _buildVisualLifestyleSection(current),
                const SizedBox(height: 24),

                // 🥗 3. DIET & HABITS
                _buildDetailSection(
                    "Dietary Profile",
                    Icons.restaurant,
                    Colors.orange,
                    [
                      _buildInfoRow("Food Habit", current.foodHabit ?? '--'),
                      _buildInfoRow("Water Intake", current.waterIntake?.values.join(', ') ?? '--'),
                      if (current.restrictedDiet != null && current.restrictedDiet!.isNotEmpty)
                        _buildInfoRow("Restricted", current.restrictedDiet!),
                    ],
                    tags: current.foodAllergies,
                    tagColor: Colors.red.shade50,
                    tagTextColor: Colors.red.shade700
                ),

                // 🏥 4. MEDICAL HISTORY
                _buildDetailSection(
                    "Medical History",
                    Icons.local_hospital,
                    Colors.redAccent,
                    [
                      if (current.giDetails?.isNotEmpty ?? false)
                        _buildInfoRow("GI Health", current.giDetails!.entries.map((e) => "${e.key} (${e.value})").join(", ")),
                      if (current.menstrualStatus != null)
                        _buildInfoRow("Menstrual", current.menstrualStatus!),
                    ],
                    tags: current.medicalHistory.keys.toList(),
                    tagColor: Colors.redAccent.withOpacity(0.1),
                    tagTextColor: Colors.redAccent
                ),

                // 💊 5. MEDICATIONS (Existing)
                if (current.prescribedMedications.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionHeader("Existing Medications", Icons.medication, Colors.blue),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: current.prescribedMedications.entries.map((e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade100)),
                      child: Text("${e.key}: ${e.value}", style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w600)),
                    )).toList(),
                  )
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 📊 TREND ROW ---
  Widget _buildVitalsTrendRow(VitalsModel current, VitalsModel? previous) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildTrendItem("Weight", current.weightKg, previous?.weightKg, "kg"),
        _buildTrendItem("BMI", current.bmi, previous?.bmi, ""),
        if(current.bodyFatPercentage > 0)
          _buildTrendItem("Body Fat", current.bodyFatPercentage, previous?.bodyFatPercentage, "%"),
      ],
    );
  }

  Widget _buildTrendItem(String label, double val, double? prev, String unit) {
    if (val == 0) return const SizedBox.shrink();

    double diff = prev != null ? val - prev : 0;
    Color color = Colors.grey.shade700;
    IconData? icon;

    if (diff.abs() > 0.1) {
      if (diff > 0) {
        color = Colors.redAccent;
        icon = Icons.arrow_upward;
      } else {
        color = Colors.green;
        icon = Icons.arrow_downward;
      }
    }

    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("${val.toStringAsFixed(1)}$unit", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 12, color: color),
              Text(diff.abs().toStringAsFixed(1), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold))
            ]
          ],
        )
      ],
    );
  }

  // --- 🧠 VISUAL LIFESTYLE ---
  Widget _buildVisualLifestyleSection(VitalsModel record) {
    // Stress Level Logic
    int stress = record.stressLevel ?? 0;
    Color stressColor = stress < 4 ? Colors.green : (stress < 8 ? Colors.orange : Colors.red);
    double stressPercent = stress / 10.0;

    return Column(
      children: [
        // Stress Bar
        Row(
          children: [
            const Icon(Icons.psychology, size: 16, color: Colors.purple),
            const SizedBox(width: 8),
            const Text("Stress", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: stressPercent, backgroundColor: Colors.purple.shade50, color: stressColor, minHeight: 6),
              ),
            ),
            const SizedBox(width: 8),
            Text("$stress/10", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: stressColor)),
          ],
        ),
        const SizedBox(height: 12),
        // Grid for Sleep & Activity
        Row(
          children: [
            Expanded(child: _buildIconMetric(Icons.bedtime, "Sleep", record.sleepQuality ?? '--', Colors.deepPurple)),
            const SizedBox(width: 12),
            Expanded(child: _buildIconMetric(Icons.directions_run, "Activity", record.activityType ?? '--', Colors.teal)),
          ],
        )
      ],
    );
  }

  Widget _buildIconMetric(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- 📝 GENERIC DETAIL SECTION ---
  Widget _buildDetailSection(String title, IconData icon, Color color, List<Widget> rows, {List<String>? tags, Color? tagColor, Color? tagTextColor}) {
    // If no data, skip
    if (rows.isEmpty && (tags == null || tags.isEmpty)) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, icon, color),
        const SizedBox(height: 10),
        ...rows,
        if (tags != null && tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: tags.map((t) => Chip(
              label: Text(t, style: TextStyle(fontSize: 11, color: tagTextColor, fontWeight: FontWeight.w600)),
              backgroundColor: tagColor,
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide.none),
            )).toList(),
          )
        ]
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _buildInfoRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$key: ", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }
}