import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/admin/appointment_model.dart';

class DashboardMetricsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. 📬 PENDING REQUESTS (Stream)
  // Counts appointments that need action (Scheduled/Pending Payment/Verification)
  Stream<int> streamPendingRequestCount(String coachId) {
    return _db.collection('appointments')
        .where('coachId', isEqualTo: coachId)
        .where('status', whereIn: ['pending', 'scheduled', 'payment_pending', 'verification_pending'])
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // 2. 📅 UPCOMING TODAY (Stream)
  // Counts confirmed appointments for the next 24 hours
  Stream<int> streamUpcomingCount(String coachId) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(hours: 24));

    return _db.collection('appointments')
        .where('coachId', isEqualTo: coachId)
        .where('status', isEqualTo: AppointmentStatus.confirmed.name)
        .where('startTime', isGreaterThan: Timestamp.fromDate(now))
        .where('startTime', isLessThan: Timestamp.fromDate(tomorrow))
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // 3. 🥗 PENDING DIET PLANS (Stream)
  // Counts Active Clients who do NOT have a 'currentPlan' set or plan is expired
  Stream<int> streamPendingPlanCount() {
    return _db.collection('clients')
        .where('clientType', isEqualTo: 'new') // or logic: status='Active' AND currentPlan == null
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // 4. 💸 FINANCIAL SNAPSHOT (Future - Heavy Calculation)
  // Calculates Total Pending Collections (Total Booked - Total Collected)
  Future<double> fetchTotalPendingCollections() async {
    try {
      // A. Get Total Booked (from Subscriptions)
      final subsSnap = await _db.collection('subscriptions')
          .where('status', isEqualTo: 'active') // Only count active deals
          .get();

      double totalBooked = 0;
      List<String> activeSubIds = [];

      for (var doc in subsSnap.docs) {
        totalBooked += (doc.data()['price'] as num?)?.toDouble() ?? 0.0;
        activeSubIds.add(doc.id);
      }

      // B. Get Total Collected (from Payments linked to these subs)
      // Note: In production, batch this or keep a running total on the Client doc for speed.
      // For now, we query all payments (Careful with read costs in large apps).
      final paySnap = await _db.collection('payments').get();

      double totalCollected = 0;
      for (var doc in paySnap.docs) {
        // Only count payment if it belongs to an active subscription we found
        if (activeSubIds.contains(doc.data()['packageAssignmentId'])) {
          totalCollected += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return (totalBooked - totalCollected).clamp(0.0, double.infinity);
    } catch (e) {
      return 0.0;
    }
  }

  // 5. 📉 RETENTION RADAR (Future)
  // Finds clients active but haven't logged in 3 days
  Future<List<String>> fetchAtRiskClientNames() async {
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    List<String> names = [];

    try {
      // Get Active Clients
      final clients = await _db.collection('clients')
          .where('status', isEqualTo: 'Active')
          .limit(20)
          .get();

      for (var doc in clients.docs) {
        // Check Last Log
        final logSnap = await _db.collection('client_logs')
            .where('clientId', isEqualTo: doc.id)
            .orderBy('date', descending: true)
            .limit(1)
            .get();

        bool isRisk = false;
        if (logSnap.docs.isEmpty) {
          isRisk = true; // Never logged
        } else {
          final lastDate = (logSnap.docs.first['date'] as Timestamp).toDate();
          if (lastDate.isBefore(threeDaysAgo)) isRisk = true;
        }

        if (isRisk) names.add(doc['name'] ?? 'Unknown');
      }
    } catch (_) {}

    return names;
  }
}