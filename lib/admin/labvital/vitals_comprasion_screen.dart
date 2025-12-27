import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/lab_test_config_model.dart';
import 'package:nutricare_client_management/admin/lab_test_config_service.dart';

// 🎯 Project Imports
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';


// Placeholder for global services provider if needed, though most logic is local now
import 'global_service_provider.dart';


// --- ENUMS FOR SMARTER ANALYSIS (RETAINED) ---
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

  // --- 1. CORE LOGIC: INTERPRETATION & COLOR CODING (RETAINED) ---

  /// Determines the clinical status based on the value and reference range.
  RangeStatus _getRangeStatus(double value, LabTestConfigModel config) {
    final double? min = config.minRange;
    final double? max = config.maxRange;
    const double thresholdFactor = 0.10; // 10% tolerance for 'Near Threshold' status

    if (min == null && max == null) return RangeStatus.notApplicable;

    // 1. Check for Out of Range (Red status)
    if (min != null && value < min) return RangeStatus.low;
    if (max != null && value > max) return RangeStatus.high;

    // 2. Check for Near Threshold (Yellow/Warning status)
    if (min != null && value <= min * (1 + thresholdFactor)) {
      if (!config.isReverseLogic) { // Standard: approaching low limit is bad
        return RangeStatus.nearThreshold;
      }
    }
    if (max != null && value >= max * (1 - thresholdFactor)) {
      if (!config.isReverseLogic) { // Standard: approaching high limit is bad
        return RangeStatus.nearThreshold;
      }
    }

    // 3. Optimal Range (Green status)
    return RangeStatus.optimal;
  }

  Color _getColorForStatus(RangeStatus status) {
    switch (status) {
      case RangeStatus.low:
      case RangeStatus.high:
        return Colors.red;
      case RangeStatus.nearThreshold:
        return Colors.orange;
      case RangeStatus.optimal:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // --- 2. CORE LOGIC: TREND ANALYSIS (RETAINED) ---

  /// Determines the trend direction between two consecutive vital entries.
  Trend _getTrend(double? current, double? previous) {
    if (current == null || previous == null) return Trend.stable;
    // Define a small tolerance margin to classify as 'stable'
    if ((current - previous).abs() < 0.001) return Trend.stable;

    if (current > previous) return Trend.up;
    if (current < previous) return Trend.down;
    return Trend.stable;
  }

  /// Gets the icon reflecting the trend and whether it's good/bad based on config.
  Widget _getTrendIcon(Trend trend, LabTestConfigModel config) {
    Color trendColor = Colors.grey.shade400;
    IconData icon = Icons.remove;

    if (trend == Trend.stable) {
      return Icon(icon, size: 14, color: trendColor);
    }

    // Is the trend clinically good or bad?
    final bool isPositiveTrend;
    if (config.isReverseLogic) {
      // Reverse Logic: UP is GOOD, DOWN is BAD.
      isPositiveTrend = (trend == Trend.up);
    } else {
      // Standard Logic: UP is BAD, DOWN is GOOD (usually means returning to baseline)
      isPositiveTrend = (trend == Trend.down);
    }

    if (trend == Trend.up) {
      icon = Icons.arrow_upward;
    } else { // trend == Trend.down
      icon = Icons.arrow_downward;
    }

    // We color trend based on clinical outcome
    if (isPositiveTrend) {
      trendColor = Colors.green.shade700;
    } else {
      trendColor = Colors.red.shade700;
    }

    return Icon(icon, size: 14, color: trendColor);
  }

  // --- 3. WIDGET HELPERS (RETAINED) ---

  /// Builds a smart chip for the numerical vital value with status.
  Widget _buildValueChip(double? value, String labKey, LabTestConfigModel? config, double? previousValue) {
    if (value == null || config == null) {
      return const Text('-', style: TextStyle(fontSize: 14));
    }

    final RangeStatus status = _getRangeStatus(value, config);
    final Color color = _getColorForStatus(status);
    final Trend trend = _getTrend(value, previousValue);

    String statusText;
    switch (status) {
      case RangeStatus.low: statusText = 'Low'; break;
      case RangeStatus.high: statusText = 'High'; break;
      case RangeStatus.nearThreshold: statusText = 'Warning'; break;
      case RangeStatus.optimal: statusText = 'Optimal'; break;
      default: statusText = ''; break;
    }

    final String displayValue = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);

    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5))
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Row 1: Value and Trend Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayValue,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(width: 4),
              // Trend indicator only on the current/latest column (which is index 0 in buildComparisonView)
              if (previousValue != null) _getTrendIcon(trend, config),
            ],
          ),
          // Row 2: Status Text
          Text(
            statusText,
            style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Builds a chip showing the percentage deviation from the previous record.
  Widget _buildDeviationChip(double? currentValue, double? previousValue, LabTestConfigModel? config) {
    if (currentValue == null || previousValue == null || config == null) {
      return const Center(child: Text('-', style: TextStyle(fontSize: 14, color: Colors.grey)));
    }

    // Avoid division by zero, show absolute change if previous is zero.
    if (previousValue == 0.0) {
      final double delta = currentValue;
      final Color deltaColor = delta > 0 ? Colors.red : (delta < 0 ? Colors.green : Colors.grey);
      return Center(
        child: Text(
          delta.toStringAsFixed(1),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: deltaColor),
        ),
      );
    }

    final double percentageChange = ((currentValue - previousValue) / previousValue) * 100;

    // Determine color based on clinical goal
    final bool isPositiveChange;
    if (config.isReverseLogic) {
      // Reverse Logic (e.g., HDL): Increase (positive %) is good.
      isPositiveChange = percentageChange >= 0;
    } else {
      // Standard Logic (e.g., LDL): Decrease (negative %) is good.
      isPositiveChange = percentageChange <= 0;
    }

    final Color chipColor = (percentageChange.abs() < 1.0)
        ? Colors.grey // Stable change (less than 1%)
        : (isPositiveChange ? Colors.green : Colors.red);

    final String sign = percentageChange > 0 ? '+' : '';
    final String displayValue = percentageChange.toStringAsFixed(1);

    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
          color: chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: chipColor.withOpacity(0.5))
      ),
      child: Center(
        child: Text(
          '$sign$displayValue%',
          style: TextStyle(color: chipColor, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }


  // 🎯 CENTRALIZED GROUPING AND SORTING LOGIC (RETAINED)
  static ({
  List<String> orderedCategories,
  Map<String, List<String>> categorizedLabKeys
  }) _getGroupedAndSortedCategories(
      Map<String, LabTestConfigModel> configMap,
      Set<String> allLabKeys
      ) {
    final Map<String, List<String>> categorizedLabKeys = {};
    final Set<String> uniqueCategories = {};

    configMap.entries
        .where((entry) => allLabKeys.contains(entry.key)) // Only show recorded tests
        .forEach((entry) {
      final key = entry.key;
      final category = entry.value.category;

      if (!categorizedLabKeys.containsKey(category)) {
        categorizedLabKeys[category] = [];
        uniqueCategories.add(category);
      }
      categorizedLabKeys[category]!.add(key);
    });

    final List<String> orderedCategories = uniqueCategories.toList();
    orderedCategories.sort(); // Centralized Alphabetical Category Sorting

    // Sort tests within each category by display name
    orderedCategories.forEach((cat) {
      categorizedLabKeys[cat]!.sort((a, b) => configMap[a]!.displayName.compareTo(configMap[b]!.displayName));
    });

    return (
    orderedCategories: orderedCategories,
    categorizedLabKeys: categorizedLabKeys
    );
  }

  /// Builds the Data Table by pivoting the chronological list.
  Widget _buildComparisonView(
      BuildContext context,
      List<VitalsModel> vitalsList,
      Map<String, LabTestConfigModel> configMap) {

    final groupingResult = _getGroupedAndSortedCategories(configMap, vitalsList.expand((v) => v.labResults.keys).toSet());
    final List<String> dateHeaders = vitalsList.map((v) => DateFormat('MMM dd, yy').format(v.date)).toList();
    List<DataRow> allRows = [];


    // 🎯 1. ADD WEIGHT ROW (With Change %)
    final double? weightChange = (vitalsList.length > 1)
        ? ((vitalsList.first.weightKg - vitalsList[1].weightKg) / vitalsList[1].weightKg) * 100
        : null;

    allRows.add(DataRow(cells: [
      const DataCell(Text("Body Weight (kg)", style: TextStyle(fontWeight: FontWeight.bold))),
      DataCell(_buildSimpleChangeChip(weightChange, isLowerBetter: true)), // 🎯 Fix: Change % logic
      ...vitalsList.map((v) => DataCell(
          Center(child: Text("${v.weightKg}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)))
      )).toList(),
    ]));

    final double? waistChange = (vitalsList.length > 1 && vitalsList[1].waistCm != null && vitalsList.first.waistCm != null)
        ? ((vitalsList.first.waistCm! - vitalsList[1].waistCm!) / vitalsList[1].waistCm!) * 100
        : null;

    allRows.add(DataRow(cells: [
      const DataCell(Text("Waist (cm)", style: TextStyle(fontWeight: FontWeight.bold))),
      DataCell(_buildSimpleChangeChip(waistChange, isLowerBetter: true)), // 🎯 Now showing percentage change
      ...vitalsList.map((v) => DataCell(
          Center(child: Text("${v.waistCm ?? '--'}", style: const TextStyle(fontWeight: FontWeight.w500)))
      )).toList(),
    ]));

    final double? hipChange = (vitalsList.length > 1 && vitalsList[1].hipCm != null && vitalsList.first.hipCm != null)
        ? ((vitalsList.first.hipCm! - vitalsList[1].hipCm!) / vitalsList[1].hipCm!) * 100
        : null;

    allRows.add(DataRow(cells: [
      const DataCell(Text("Hip (cm)", style: TextStyle(fontWeight: FontWeight.bold))),
      DataCell(_buildSimpleChangeChip(hipChange, isLowerBetter: true)), // 🎯 Now showing percentage change
      ...vitalsList.map((v) => DataCell(
          Center(child: Text("${v.hipCm ?? '--'}", style: const TextStyle(fontWeight: FontWeight.w500)))
      )).toList(),
    ]));

// 🎯 3. ADD BLOOD PRESSURE ROW (With Change % based on Systolic)
    final double? bpChange = (vitalsList.length > 1 && vitalsList[1].bloodPressureSystolic != null && vitalsList.first.bloodPressureSystolic != null)
        ? ((vitalsList.first.bloodPressureSystolic! - vitalsList[1].bloodPressureSystolic!) / vitalsList[1].bloodPressureSystolic!) * 100
        : null;

    allRows.add(DataRow(cells: [
      const DataCell(Text("BP (Systolic/Diastolic)", style: TextStyle(fontWeight: FontWeight.bold))),
      DataCell(_buildSimpleChangeChip(bpChange, isLowerBetter: true)), // 🎯 Fix: Change % logic
      ...vitalsList.map((v) => DataCell(
          Center(child: Text(
            v.bloodPressureSystolic != null && v.bloodPressureDiastolic != null
                ? "${v.bloodPressureSystolic}/${v.bloodPressureDiastolic}"
                : "N/A",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
          ))
      )).toList(),
    ]));

    // 3. Category & Lab Test Rows (Existing Logic)
    for (final category in groupingResult.orderedCategories) {
      allRows.add(DataRow(
        color: MaterialStateProperty.all(Colors.blueGrey.shade100.withOpacity(0.8)),
        cells: [
          DataCell(Text(category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800))),
          const DataCell(SizedBox.shrink()),
          ...List.generate(dateHeaders.length, (index) => const DataCell(SizedBox.shrink())),
        ],
      ));

      for (final key in groupingResult.categorizedLabKeys[category]!) {
        final config = configMap[key];
        final currentValue = vitalsList.first.labResults[key];
        final previousValue = vitalsList.length > 1 ? vitalsList[1].labResults[key] : null;

        allRows.add(DataRow(cells: [
          DataCell(Text(config?.displayName ?? key)),
          DataCell(_buildDeviationChip(currentValue, previousValue, config)),
          ...vitalsList.asMap().entries.map((entry) => DataCell(
              Center(child: _buildValueChip(entry.value.labResults[key], key, config,
                  entry.key + 1 < vitalsList.length ? vitalsList[entry.key + 1].labResults[key] : null))
          )).toList(),
        ]));
      }
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Vital / Lab Test', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('Change (%)', style: TextStyle(fontWeight: FontWeight.bold))),
                for (final header in dateHeaders)
                  DataColumn(label: Center(child: Text(header, style: const TextStyle(fontWeight: FontWeight.bold)))),
              ],
              rows: allRows,
            ),
          ),
        ],
      ),
    );
  }
  // 🎯 Custom Header Widget (Replaced SliverAppBar for clean layout)
  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.indigo),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Client: $clientName',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Vitals Comparison',
                  style: TextStyle(
                    color: Colors.indigo.shade900,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. WIDGET BUILDER (REPLACED CustomScrollView with static layout) ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the Lab Test Configuration stream
    final labConfigAsync = ref.watch(allLabTestsStreamProvider);
    final vitalsService = ref.watch(vitalsServiceProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),

        body: Column(
          children: [
            // 1. Custom Header (Non-collapsible, guaranteed not to overlap)
            _buildCustomAppBar(context),

            // 2. Expanded Body Content
            Expanded(
              child: labConfigAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error loading lab configuration: $err')),
                data: (labConfigList) {
                  final Map<String, LabTestConfigModel> labConfigMap = {
                    for (var config in labConfigList) config.id: config
                  };

                  final vitalsStream = vitalsService.streamAllVitalsForClient(clientId);

                  return StreamBuilder<List<VitalsModel>>(
                    stream: vitalsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading vital data: ${snapshot.error}'));
                      }

                      final vitalsList = snapshot.data ?? [];

                      if (vitalsList.isEmpty) {
                        return const Center(child: Text('No historical vital records found for comparison.'));
                      }

                      vitalsList.sort((a, b) => b.date.compareTo(a.date));

                      // Return the fully built scrollable comparison view
                      return _buildComparisonView(context, vitalsList, labConfigMap);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSimpleChangeChip(double? percentageChange, {bool isLowerBetter = true}) {
    if (percentageChange == null || percentageChange.isNaN) {
      return const Center(child: Text('-', style: TextStyle(color: Colors.grey)));
    }

    // Determine color: If lower is better (Weight/BP), negative change is green.
    final bool isGood = isLowerBetter ? percentageChange <= 0 : percentageChange >= 0;
    final Color chipColor = (percentageChange.abs() < 0.5) ? Colors.grey : (isGood ? Colors.green : Colors.red);

    final String sign = percentageChange > 0 ? '+' : '';

    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
          color: chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: chipColor.withOpacity(0.5))
      ),
      child: Center(
        child: Text(
          '$sign${percentageChange.toStringAsFixed(1)}%',
          style: TextStyle(color: chipColor, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
    );
  }
}