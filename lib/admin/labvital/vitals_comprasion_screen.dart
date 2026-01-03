import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/lab_test_config_model.dart';
import 'package:nutricare_client_management/admin/lab_test_config_service.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';

// --- ENUMS ---
enum Trend { up, down, stable }
enum RangeStatus { optimal, nearThreshold, low, high, notApplicable }

class VitalsComparisonScreen extends ConsumerWidget {
  final String clientId;
  final String clientName;

  const VitalsComparisonScreen({
    super.key,
    required this.clientId,
    required this.clientName
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labConfigAsync = ref.watch(allLabTestsStreamProvider);
    final vitalsService = ref.watch(vitalsServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Vitals Progress", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(clientName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: labConfigAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (labConfigList) {
          final Map<String, LabTestConfigModel> labConfigMap = {
            for (var config in labConfigList) config.id: config
          };

          return StreamBuilder<List<VitalsModel>>(
            stream: vitalsService.streamAllVitalsForClient(clientId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final vitalsList = snapshot.data ?? [];
              if (vitalsList.isEmpty) {
                return const Center(child: Text('No vital records found.'));
              }

              // Sort: Newest First
              vitalsList.sort((a, b) => b.date.compareTo(a.date));

              return _buildBeautifulTable(context, vitalsList, labConfigMap);
            },
          );
        },
      ),
    );
  }

  // --- 1. BEAUTIFUL DATA TABLE BUILDER ---
  Widget _buildBeautifulTable(
      BuildContext context,
      List<VitalsModel> vitalsList,
      Map<String, LabTestConfigModel> configMap) {

    final groupingResult = _getGroupedAndSortedCategories(configMap, vitalsList.expand((v) => v.labResults.keys).toSet());
    final List<String> dateHeaders = vitalsList.map((v) => DateFormat('dd MMM\n''yy').format(v.date)).toList();

    // Prepare Rows
    final List<DataRow> rows = _prepareDataRows(vitalsList, groupingResult, configMap);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.indigo.shade50),
              dataRowMinHeight: 60,
              dataRowMaxHeight: 70,
              columnSpacing: 24,
              horizontalMargin: 20,
              columns: [
                const DataColumn(label: Text("TEST & RANGE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                const DataColumn(label: Text("CHANGE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                ...dateHeaders.map((d) => DataColumn(label: Text(d, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
              ],
              rows: rows,
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. ROW PREPARATION LOGIC ---

  List<DataRow> _prepareDataRows(
      List<VitalsModel> vitalsList,
      ({List<String> orderedCategories, Map<String, List<String>> categorizedLabKeys}) grouping,
      Map<String, LabTestConfigModel> configMap
      ) {
    List<DataRow> rows = [];

    // Helper: Header Row for Categories
    DataRow categoryRow(String title) {
      return DataRow(
        color: MaterialStateProperty.all(Colors.blueGrey.shade50),
        cells: [
          DataCell(Text(title.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey.shade800, fontSize: 11))),
          const DataCell(SizedBox()), // Change Placeholder
          ...List.generate(vitalsList.length, (index) => const DataCell(SizedBox())),
        ],
      );
    }

    // A. Anthropometry
    if (vitalsList.isNotEmpty) {
      rows.add(categoryRow("Anthropometry"));
      rows.add(_createVitalRow("Body Weight", "kg", vitalsList, (v) => v.weightKg));
      rows.add(_createVitalRow("BMI", "", vitalsList, (v) => v.bmi));
      rows.add(_createVitalRow("Waist", "cm", vitalsList, (v) => v.waistCm));

      // BP Special Case
      final bpVals = vitalsList.map((v) => (v.bloodPressureSystolic as num?)?.toDouble()).toList();
      double? bpChange;
      if (bpVals.length >= 2 && bpVals[0] != null && bpVals[1] != null && bpVals[1] != 0) {
        bpChange = ((bpVals[0]! - bpVals[1]!) / bpVals[1]!) * 100;
      }
      rows.add(DataRow(cells: [
        _buildNameCell("Blood Pressure", "< 120/80 mmHg"),
        DataCell(_buildDeviationChip(bpChange, false)),
        ...vitalsList.map((v) => DataCell(
            Center(child: Text((v.bloodPressureSystolic != null) ? "${v.bloodPressureSystolic}/${v.bloodPressureDiastolic}" : "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))
        )),
      ]));
    }

    // B. Lab Tests
    for (final category in grouping.orderedCategories) {
      rows.add(categoryRow(category));

      for (final key in grouping.categorizedLabKeys[category]!) {
        final config = configMap[key];

        // Explicitly cast to double?
        final List<double?> vals = vitalsList.map((v) => (v.labResults[key] as num?)?.toDouble()).toList();

        // Calculate Change
        double? changePct;
        if (vals.length >= 2) {
          final current = vals[0];
          final prev = vals[1];
          if (current != null && prev != null && prev != 0) {
            changePct = ((current - prev) / prev) * 100;
          }
        }

        // Format Range String
        String range = "-";
        if (config != null) {
          if (config.minRange != null && config.maxRange != null) range = "${config.minRange} - ${config.maxRange}";
          else if (config.minRange != null) range = "> ${config.minRange}";
          else if (config.maxRange != null) range = "< ${config.maxRange}";
        }
        if (config?.unit != null) range += " ${config!.unit}";

        rows.add(DataRow(cells: [
          _buildNameCell(config?.displayName ?? key, range),
          DataCell(_buildDeviationChip(changePct, config?.isReverseLogic ?? false)),
          ...List.generate(vals.length, (index) {
            final val = vals[index];
            final prev = (index + 1 < vals.length) ? vals[index+1] : null;
            return DataCell(Center(child: _buildValueChip(val, prev, config)));
          }),
        ]));
      }
    }
    return rows;
  }

  DataRow _createVitalRow(String label, String unit, List<VitalsModel> list, double? Function(VitalsModel) extractor) {
    final vals = list.map(extractor).toList();
    double? change;
    if (vals.length >= 2 && vals[0] != null && vals[1] != null && vals[1] != 0) {
      change = ((vals[0]! - vals[1]!) / vals[1]!) * 100;
    }

    return DataRow(cells: [
      _buildNameCell(label, "- $unit"),
      DataCell(_buildDeviationChip(change, false)),
      ...vals.map((v) => DataCell(Center(child: Text(v?.toStringAsFixed(1) ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))))),
    ]);
  }

  // --- 3. WIDGET HELPERS (Cells & Chips) ---

  DataCell _buildNameCell(String name, String range) {
    return DataCell(
      SizedBox(
        width: 160, // Fixed width for alignment
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(range, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildValueChip(double? value, double? prevValue, LabTestConfigModel? config) {
    if (value == null) return const Text("-", style: TextStyle(color: Colors.grey));

    Color textColor = Colors.black87;
    Color bgColor = Colors.transparent;

    // Risk Analysis
    if (config != null) {
      final status = _getRangeStatus(value, config);
      final statusColor = _getColorForStatus(status);

      if (status != RangeStatus.optimal && status != RangeStatus.notApplicable) {
        textColor = statusColor;
        bgColor = statusColor.withOpacity(0.1);
      }
    }

    final trend = _getTrend(value, prevValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: bgColor != Colors.transparent ? Border.all(color: textColor.withOpacity(0.3)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
          if (trend != Trend.stable) ...[
            const SizedBox(width: 4),
            _getTrendIcon(trend, config?.isReverseLogic ?? false),
          ]
        ],
      ),
    );
  }

  Widget _buildDeviationChip(double? change, bool isReverse) {
    if (change == null) return const Center(child: Text("-", style: TextStyle(color: Colors.grey, fontSize: 12)));

    bool isGood = isReverse ? change > 0 : change < 0;
    Color color = (change.abs() < 1) ? Colors.grey : (isGood ? Colors.green : Colors.red);
    String sign = change > 0 ? "+" : "";

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
        child: Text("$sign${change.toStringAsFixed(1)}%", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }

  // --- 4. ANALYTIC HELPERS ---

  RangeStatus _getRangeStatus(double value, LabTestConfigModel config) {
    final double? min = config.minRange;
    final double? max = config.maxRange;
    const double thresholdFactor = 0.10;

    if (min == null && max == null) return RangeStatus.notApplicable;
    if (min != null && value < min) return RangeStatus.low;
    if (max != null && value > max) return RangeStatus.high;

    if (min != null && value <= min * (1 + thresholdFactor) && !config.isReverseLogic) return RangeStatus.nearThreshold;
    if (max != null && value >= max * (1 - thresholdFactor) && !config.isReverseLogic) return RangeStatus.nearThreshold;

    return RangeStatus.optimal;
  }

  Color _getColorForStatus(RangeStatus status) {
    switch (status) {
      case RangeStatus.low: return Colors.red.shade700;
      case RangeStatus.high: return Colors.red.shade700;
      case RangeStatus.nearThreshold: return Colors.orange.shade800;
      case RangeStatus.optimal: return Colors.green.shade700;
      default: return Colors.grey.shade800;
    }
  }

  Trend _getTrend(double? current, double? previous) {
    if (current == null || previous == null) return Trend.stable;
    if ((current - previous).abs() < 0.001) return Trend.stable;
    return current > previous ? Trend.up : Trend.down;
  }

  Widget _getTrendIcon(Trend trend, bool isReverseLogic) {
    if (trend == Trend.stable) return const SizedBox.shrink();
    bool isPositiveOutcome = isReverseLogic ? (trend == Trend.up) : (trend == Trend.down);

    return Icon(
      trend == Trend.up ? Icons.arrow_upward : Icons.arrow_downward,
      size: 10,
      color: isPositiveOutcome ? Colors.green : Colors.red,
    );
  }

  // --- 5. GROUPING LOGIC ---

  ({List<String> orderedCategories, Map<String, List<String>> categorizedLabKeys}) _getGroupedAndSortedCategories(
      Map<String, LabTestConfigModel> configMap, Set<String> allLabKeys) {
    final Map<String, List<String>> categorizedLabKeys = {};
    final Set<String> uniqueCategories = {};

    configMap.entries.where((entry) => allLabKeys.contains(entry.key)).forEach((entry) {
      final key = entry.key;
      final category = entry.value.category;
      if (!categorizedLabKeys.containsKey(category)) {
        categorizedLabKeys[category] = [];
        uniqueCategories.add(category);
      }
      categorizedLabKeys[category]!.add(key);
    });

    final List<String> orderedCategories = uniqueCategories.toList()..sort();
    for (final cat in orderedCategories) {
      categorizedLabKeys[cat]!.sort((a, b) => (configMap[a]?.displayName ?? a).compareTo(configMap[b]?.displayName ?? b));
    }
    return (orderedCategories: orderedCategories, categorizedLabKeys: categorizedLabKeys);
  }
}