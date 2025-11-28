import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

class AdminAnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =================================================================
  // 📊 SECTION 1: BUSINESS METRICS (Revenue & Growth)
  // =================================================================

  Future<Map<String, dynamic>> fetchBusinessSnapshot() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    try {
      // 1. Total Revenue (This Month)
      final paymentQuery = await _db.collection('payments')
          .where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      double revenue = 0;
      for (var doc in paymentQuery.docs) {
        revenue += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      }

      // 2. New Leads (Clients created this month)
      // Note: Assuming 'createdAt' exists on clients. If not, use AppUser collection.
      final leadsQuery = await _db.collection('clients')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .count()
          .get();

      int? newLeads = leadsQuery.count;

      // 3. Active Clients (Status = Active)
      final activeQuery = await _db.collection('clients')
          .where('status', isEqualTo: 'Active')
          .count()
          .get();

      return {
        'revenue': revenue,
        'leads': newLeads,
        'activeClients': activeQuery.count,
      };
    } catch (e) {
      print("Analytics Error (Business): $e");
      return {'revenue': 0.0, 'leads': 0, 'activeClients': 0};
    }
  }

  Future<List<FlSpot>> fetchRevenueTrend() async {
    // Fetches last 6 months of revenue
    // Returns List<FlSpot> for LineChart
    // X = Month Index (0 = 6 months ago, 5 = Today)
    // Y = Revenue amount

    List<FlSpot> spots = [];
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0);

      final query = await _db.collection('payments')
          .where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('paymentDate', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
          .get();

      double monthlyTotal = 0;
      for (var doc in query.docs) {
        monthlyTotal += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      }

      // Normalize for chart (e.g., divide by 1000 for 'k')
      spots.add(FlSpot((5 - i).toDouble(), monthlyTotal / 1000));
    }
    return spots;
  }

  Future<List<PieChartSectionData>> fetchPlanDistribution() async {
    // Fetches counts of active plans by Name/Category
    // Returns sections for PieChart

    try {
      final query = await _db.collection('clientDietPlans')
          .where('isActive', isEqualTo: true)
          .get();

      Map<String, int> counts = {};
      for (var doc in query.docs) {
        // Use plan name or category if available
        String name = (doc.data()['name'] as String?) ?? 'Other';
        // Simplify name for chart (e.g. "Weight Loss Pro" -> "Weight Loss")
        if (name.contains("Weight")) name = "Weight Loss";
        else if (name.contains("Diabetes")) name = "Diabetes";
        else if (name.contains("PCOS")) name = "PCOS";
        else name = "General";

        counts[name] = (counts[name] ?? 0) + 1;
      }

      // Convert to Sections
      List<Color> colors = [Colors.blue, Colors.purple, Colors.orange, Colors.teal, Colors.red];
      int colorIdx = 0;

      return counts.entries.map((e) {
        final section = PieChartSectionData(
          color: colors[colorIdx % colors.length],
          value: e.value.toDouble(),
          title: '${e.key}\n${e.value}',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        );
        colorIdx++;
        return section;
      }).toList();

    } catch (e) {
      return [];
    }
  }

  // =================================================================
  // ❤️ SECTION 2: QUALITY METRICS (Health & Adherence)
  // =================================================================

  Future<Map<String, dynamic>> fetchQualitySnapshot() async {
    // Calculates Avg Adherence & Happiness from last 7 days of logs
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    try {
      final logsQuery = await _db.collection('client_logs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .get();

      if (logsQuery.docs.isEmpty) return {'adherence': 0, 'happiness': 0.0};

      double totalScore = 0;
      double totalMood = 0;
      int moodCount = 0;

      for (var doc in logsQuery.docs) {
        final data = doc.data();
        totalScore += (data['activityScore'] as num?) ?? 0;

        final mood = (data['moodLevelRating'] as num?)?.toDouble();
        if (mood != null) {
          totalMood += mood;
          moodCount++;
        }
      }

      // Avg Score per log (out of 100)
      int avgAdherence = (totalScore / logsQuery.docs.length).round();
      double avgMood = moodCount > 0 ? (totalMood / moodCount) : 0.0;

      return {
        'adherence': avgAdherence, // e.g., 85
        'happiness': avgMood,     // e.g., 4.2
      };

    } catch (e) {
      return {'adherence': 0, 'happiness': 0.0};
    }
  }

  Future<List<BarChartGroupData>> fetchAdherenceTrend() async {
    // Returns Bar Groups for last 7 days
    // Y = Number of logs submitted that day

    List<BarChartGroupData> bars = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final dayStart = DateTime(now.year, now.month, now.day - i);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final query = await _db.collection('client_logs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('date', isLessThan: Timestamp.fromDate(dayEnd))
          .count()
          .get();

      int? count = query.count;

      bars.add(BarChartGroupData(
        x: 6 - i,
        barRods: [
          BarChartRodData(
            toY: count!.toDouble(),
            color: count > 10 ? Colors.teal : Colors.orange,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      ));
    }
    return bars;
  }

  // 🎯 CRITICAL: FIND AT-RISK CLIENTS
  // Logic: Clients active in last 30 days but NO logs in last 3 days
  Future<List<Map<String, dynamic>>> fetchAtRiskClients() async {
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));

    try {
      // 1. Get all active clients
      final clientsSnapshot = await _db.collection('clients')
          .where('status', isEqualTo: 'Active')
          .limit(50) // Limit scan size
          .get();

      List<Map<String, dynamic>> atRisk = [];

      for (var doc in clientsSnapshot.docs) {
        // Check last log date
        // Optimized: Assuming we maintain a 'lastLogDate' field on ClientModel.
        // If not, we have to query logs (Expensive).
        // Fallback: Query logs for this client > 3 days ago.

        final lastLogQuery = await _db.collection('client_logs')
            .where('clientId', isEqualTo: doc.id)
            .orderBy('date', descending: true)
            .limit(1)
            .get();

        if (lastLogQuery.docs.isEmpty) {
          // Never logged? At Risk.
          atRisk.add({
            'name': doc['name'] ?? 'Unknown',
            'reason': 'Never logged in',
            'riskLevel': 1.0 // High
          });
        } else {
          final lastDate = (lastLogQuery.docs.first['date'] as Timestamp).toDate();
          if (lastDate.isBefore(threeDaysAgo)) {
            final days = DateTime.now().difference(lastDate).inDays;
            atRisk.add({
              'name': doc['name'] ?? 'Unknown',
              'reason': 'Inactive for $days days',
              'riskLevel': (days / 10).clamp(0.0, 1.0) // 10 days = Max risk
            });
          }
        }
      }

      // Sort by Risk (Highest first)
      atRisk.sort((a, b) => b['riskLevel'].compareTo(a['riskLevel']));
      return atRisk.take(5).toList(); // Return top 5

    } catch (e) {
      return [];
    }
  }
  Future<Map<String, dynamic>> fetchWellnessStats() async {
    // Mock data for Wellness Heatmap
    return {
      'Breathing': 120,
      'Sleep': 85,
      'Hydration': 200,
      'Yoga': 45,
    };
  }
  Future<double> fetchAverageWeightVelocity() async {
    try {
      // Get all active clients
      final clientsSnap = await _db.collection('clients')
          .where('status', isEqualTo: 'Active')
          .get();

      double totalVelocity = 0;
      int validClients = 0;

      for (var doc in clientsSnap.docs) {
        final clientId = doc.id;

        // Get first and last weight record
        final vitalsSnap = await _db.collection('vitals')
            .where('clientId', isEqualTo: clientId)
            .orderBy('date', descending: false) // Oldest first
            .get();

        if (vitalsSnap.docs.length >= 2) {
          final first = vitalsSnap.docs.first.data();
          final last = vitalsSnap.docs.last.data();

          final double startWeight = (first['weightKg'] as num).toDouble();
          final double currentWeight = (last['weightKg'] as num).toDouble();

          final DateTime startDate = (first['date'] as Timestamp).toDate();
          final DateTime endDate = (last['date'] as Timestamp).toDate();

          final int weeks = endDate.difference(startDate).inDays ~/ 7;

          if (weeks > 0) {
            // Negative velocity = Weight Loss
            double velocity = (currentWeight - startWeight) / weeks;
            totalVelocity += velocity;
            validClients++;
          }
        }
      }

      return validClients == 0 ? 0.0 : (totalVelocity / validClients);
    } catch (e) {
      return 0.0;
    }
  }
}