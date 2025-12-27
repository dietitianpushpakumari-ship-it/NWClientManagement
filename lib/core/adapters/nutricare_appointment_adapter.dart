import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/modules/appointment/interface/appointment_contract.dart';

class NutricareAppointmentAdapter implements AppointmentContract {
  final FirebaseFirestore _db;
  final String _currentUserId;

  NutricareAppointmentAdapter({
    required FirebaseFirestore db,
    required String currentUserId,
  })  : _db = db,
        _currentUserId = currentUserId;

  // --- 1. USER & STAFF INFO ---
  @override
  String getCurrentUserId() => _currentUserId;

  @override
  Future<bool> isStaff(String userId) async {
    try {
      final doc = await _db.collection('admins').doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, String>> getActiveStaff() async {
    try {
      final snap = await _db.collection('admins')
          .where('role', whereIn: ['dietitian', 'clinicAdmin'])
          .where('isActive', isEqualTo: true)
          .get();

      Map<String, String> staffMap = {};
      for (var doc in snap.docs) {
        staffMap[doc.id] = (doc.data()['name'] as String?) ?? "Dietitian";
      }
      return staffMap;
    } catch (e) {
      return {};
    }
  }

  // --- 2. DYNAMIC BALANCE CALCULATION ---

  /// 🧮 Calculates balance on the fly.
  /// Balance = (Sum of All Subscriptions) - (Count of Active Appointments)
  Future<int> _calculateLiveBalance(String clientId) async {
    // A. Get Total Credits (Income)
    // We sum up all 'patient_subscriptions' for this client
    final subsSnap = await _db.collection(MasterCollectionMapper.getPath(TransactionEntity.entity_patientSubscription))
        .where('clientId', isEqualTo: clientId)
    // Optional: .where('status', isEqualTo: 'active') // if you want expired packs to stop counting
        .get();

    int totalPurchased = 0;
    for (var doc in subsSnap.docs) {
      final data = doc.data();
      // Sum base sessions + free sessions + extra offers
      int sessions = (data['sessionsTotal'] as num?)?.toInt() ?? 0;
      int free = (data['freeSessionsTotal'] as num?)?.toInt() ?? 0;
      // Note: If your sessionsTotal already includes offerExtraDays, don't double count.
      // Based on your previous code, 'sessionsTotal' seemed to be the base.
      // Adjust this summing logic to match exactly how you save the data.
      totalPurchased += (sessions + free);
    }

    // B. Get Total Consumed (Expense)
    // We count all appointments that are NOT cancelled
    final apptsSnap = await _db.collection('appointments')
        .where('clientId', isEqualTo: clientId)
        .get(); // ⚠️ Optimization: Use .count() aggregation in future if appts > 100

    int totalUsed = 0;
    for (var doc in apptsSnap.docs) {
      final status = doc.data()['status'];
      if (status != 'cancelled') {
        totalUsed++;
      }
    }

    // C. Result
    return totalPurchased - totalUsed;
  }

  @override
  Future<bool> hasSufficientCredits(String userId, int cost) async {
    try {
      final int currentBalance = await _calculateLiveBalance(userId);
      print("DEBUG: Client Balance Calculated: $currentBalance (Cost: $cost)");
      return currentBalance >= cost;
    } catch (e) {
      print("Error calculating balance: $e");
      return false;
    }
  }

  // --- 3. AUDIT LOGGING ONLY (No Variable Updates) ---

  @override
  Future<void> reserveCredits(String userId, int cost, String reason, String referenceId) async {
    // 🎯 We DO NOT update any 'wallet.available' field.
    // We only create a Ledger Entry for audit history.
    // The "Reservation" is physically represented by the existence of the Appointment document itself.

    final ledgerRef = _db.collection('wallet_ledger').doc();

    await ledgerRef.set({
      'clientId': userId,
      'type': 'debit',
      'category': 'booking_hold',
      'amount': -cost,
      'description': reason,
      'referenceId': referenceId,
      'timestamp': FieldValue.serverTimestamp(),
      'performedBy': _currentUserId,
      'note': 'Calculated balance used. No stored variable updated.'
    });
  }

  @override
  Future<void> consumeReservedCredits(String userId, int cost, String referenceId) async {
    // 🎯 No Action Needed.
    // The appointment exists, so it is already "Consumed" in the calculation.
    // We just add an info log.

    await _db.collection('wallet_ledger').add({
      'clientId': userId,
      'type': 'info',
      'category': 'session_consumed',
      'description': 'Session Completed',
      'referenceId': referenceId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> releaseReservedCredits(String userId, int cost, String referenceId) async {
    // 🎯 No Action Needed for Balance.
    // When the appointment status changes to 'cancelled', the _calculateLiveBalance()
    // function will automatically stop counting it, returning the credit to the pool.

    await _db.collection('wallet_ledger').add({
      'clientId': userId,
      'type': 'info', // Just info, the math happens automatically via appointment status
      'category': 'booking_cancelled',
      'description': 'Credit returned to pool (Appointment Cancelled)',
      'referenceId': referenceId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  // --- 3. NOTIFICATIONS ---

  @override
  Future<void> sendNotification(String userId, String title, String body) async {
    try {
      // Log notification to tenant DB.
      // A Cloud Function usually listens to this collection to trigger FCM.
      await _db.collection('notifications').add({
        'recipientId': userId,
        'title': title,
        'body': body,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'appointment_alert',
      });
    } catch (e) {
      // Silent failure for notifications is acceptable in adapter layer
      // print("Notification failed: $e");
    }
  }
}