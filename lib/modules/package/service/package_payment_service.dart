import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:nutricare_client_management/admin/appointment_model.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import '../../../models/assigned_package_data.dart';
import '../../client/model/client_model.dart';
import '../model/package_assignment_model.dart';
import '../model/payment_model.dart';

final Logger _logger = Logger();

class PackagePaymentService {

  final Ref _ref;
  PackagePaymentService(this._ref);

  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  // 🎯 FIX 1: Point to 'subscriptions' (matches your Assignment Page)
  CollectionReference _assignmentCollection() => _firestore.collection(MasterCollectionMapper.getPath(TransactionEntity.entity_patientSubscription));

  CollectionReference get _paymentCollectionv2 => _firestore.collection(MasterCollectionMapper.getPath(TransactionEntity.entity_patientPayment));
  CollectionReference get _clientCollection => _firestore.collection('clients');

  // --- PAYMENT CRUD ---

  Future<String> assignPackage(PackageAssignmentModel assignment) async {
    try {
      final docRef = await _assignmentCollection().add(assignment.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception("Failed to assign package: $e");
    }
  }

  Future<void> addPayment(PaymentModel payment) async {
    try {
      await _paymentCollectionv2.add(payment.toMap());
    } catch (e) {
      throw Exception('Failed to record payment.');
    }
  }

  Stream<List<PaymentModel>> streamPaymentsForAssignment(String assignmentId) {
    return _paymentCollectionv2
        .where('packageAssignmentId', isEqualTo: assignmentId)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => PaymentModel.fromFirestore(doc)).toList());
  }

  Future<void> deletePayment(String paymentId, {required String deletionReason}) async {
    final paymentRef = _paymentCollectionv2.doc(paymentId);
    final deletedPaymentsRef = _firestore.collection('deletedPaymentsAudit').doc();

    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot paymentSnapshot = await transaction.get(paymentRef);
      if (!paymentSnapshot.exists) throw Exception("Payment record not found");

      final paymentData = paymentSnapshot.data() as Map<String, dynamic>;
      final auditData = {
        ...paymentData,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': FirebaseAuth.instance.currentUser?.email ?? 'SystemAdmin',
        'deletionReason': deletionReason,
        'originalId': paymentId,
      };

      transaction.set(deletedPaymentsRef, auditData);
      transaction.delete(paymentRef);
    });
  }

  // --- REPORTING & TOTALS ---

  Future<List<AssignedPackageData>> getAllAssignmentsWithCollectedAmounts() async {
    final List<AssignedPackageData> ledgerData = [];

    // 1. Fetch ALL payments once
    final allPaymentsSnapshot = await _paymentCollectionv2.get();

    // Group by assignmentId for O(1) lookup
    final Map<String, List<DocumentSnapshot>> paymentsByAssignment = {};
    for (var doc in allPaymentsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final currentAssignmentId = data['packageAssignmentId'] as String?;
      if (currentAssignmentId != null) {
        paymentsByAssignment.putIfAbsent(currentAssignmentId, () => []).add(doc);
      }
    }

    // 2. Fetch clients
    final clientSnapshot = await _clientCollection.get();

    for (var clientDoc in clientSnapshot.docs) {
      final clientId = clientDoc.id;
      final clientName = ClientModel.fromFirestore(clientDoc).name;

      // 🎯 FIX 2: Filter assignments by Client ID
      final assignmentSnapshot = await _assignmentCollection()
          .where('clientId', isEqualTo: clientId)
          .get();

      for (var assignmentDoc in assignmentSnapshot.docs) {
        // 🎯 FIX 3: Safety Try-Catch for Model Parsing
        // (Prevents crash if 'bookedAmount' is missing in legacy data)
        try {
          final assignment = PackageAssignmentModel.fromFirestore(assignmentDoc);

          // Calculate Total
          final relevantPayments = paymentsByAssignment[assignmentDoc.id] ?? [];
          final collectedAmount = relevantPayments.fold<double>(0.0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            return sum + amount;
          });

          ledgerData.add(
            AssignedPackageData(
              clientName: clientName,
              assignment: assignment,
              collectedAmount: collectedAmount,
            ),
          );
        } catch (e) {
          _logger.w("Skipping invalid assignment ${assignmentDoc.id}: $e");
        }
      }
    }

    ledgerData.sort((a, b) => a.clientName.compareTo(b.clientName));
    return ledgerData;
  }

  // Helper: Get total directly for a specific assignment ID
  Future<double> getCollectedAmountForAssignment(String assignmentId) async {
    try {
      final QuerySnapshot snapshot = await _paymentCollectionv2
          .where('packageAssignmentId', isEqualTo: assignmentId)
          .get();

      double totalCollected = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalCollected += (data['amount'] as num?)?.toDouble() ?? 0.0;
      }
      return totalCollected;
    } catch (e) {
      print('Error fetching total for assignment $assignmentId: $e');
      return 0.0;
    }
  }

  // --- APPOINTMENT SETTLEMENT ---

  Stream<List<AppointmentModel>> streamUnsettledAppointments() {
    return _firestore.collection('appointments')
        .where('status', whereIn: ['confirmed', 'completed'])
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) => AppointmentModel.fromFirestore(d))
          .where((appt) => !appt.isSettled && (appt.amountPaid ?? 0) > 0)
          .toList();
    });
  }

  Future<void> postSettlement({
    required AppointmentModel appointment,
    required double finalAmount,
    required String paymentMode,
    required String paymentRef,
    required String narration,
  }) async {
    if (appointment.clientId == null) throw Exception("Client ID missing.");

    final batch = _firestore.batch();

    // 🎯 FIX 4: Use correct collection 'subscriptions' for virtual assignments too
    final virtualAssignmentId = "appt_${appointment.id}";
    final assignmentRef = _assignmentCollection().doc(virtualAssignmentId);

    final virtualAssignment = PackageAssignmentModel(
      id: virtualAssignmentId,
      packageId: 'single_session',
      packageName: "Session: ${appointment.topic}",
      purchaseDate: DateTime.now(),
      expiryDate: appointment.endTime,
      isActive: false,
      isLocked: true,
      clientId: appointment.clientId!,
      diagnosis: 'One-off Consultation',
      bookedAmount: finalAmount,
      category: 'Consultation',
      discount: 0,
    );

    final paymentDoc = _paymentCollectionv2.doc();
    final payment = PaymentModel(
      id: paymentDoc.id,
      packageAssignmentId: virtualAssignmentId,
      amount: finalAmount,
      paymentDate: DateTime.now(),
      receivedBy: FirebaseAuth.instance.currentUser?.email ?? 'Admin',
      paymentMethod: paymentMode,
      narration: "$narration (Appt Ref: ${appointment.id})",
    );

    final apptRef = _firestore.collection('appointments').doc(appointment.id);

    batch.set(assignmentRef, virtualAssignment.toMap());
    batch.set(paymentDoc, payment.toMap());
    batch.update(apptRef, {
      'isSettled': true,
      'amount': finalAmount,
      'paymentRef': paymentRef,
      'paymentMethod': paymentMode
    });

    await batch.commit();
  }

  Future<void> cancelPackageAndRevokeCredits(String clientId, String subscriptionId) async {
    final clientRef = _firestore.collection('clients').doc(clientId);
    final subRef = _firestore.collection('patient_subscriptions').doc(subscriptionId); // Adjust collection path
    final ledgerRef = _firestore.collection('wallet_ledger').doc();

    await _firestore.runTransaction((t) async {
      final clientSnap = await t.get(clientRef);
      if (!clientSnap.exists) throw Exception("Client not found");

      final wallet = clientSnap.data()!['wallet'] as Map<String, dynamic>;
      final batches = wallet['batches'] as Map<String, dynamic>? ?? {};

      // 1. Check if batch exists
      if (!batches.containsKey(subscriptionId)) {
        throw Exception("No active credits found for this package subscription.");
      }

      final batch = batches[subscriptionId] as Map<String, dynamic>;
      final int creditsToRevoke = (batch['balance'] as num).toInt();

      if (creditsToRevoke <= 0) {
        // Package has 0 balance, just marking subscription as cancelled is enough
      }

      // 2. Update Client Wallet
      t.update(clientRef, {
        // Reduce global available count
        'wallet.available': FieldValue.increment(-creditsToRevoke),
        // Remove the specific batch entirely
        'wallet.batches.$subscriptionId': FieldValue.delete(),
      });

      // 3. Update Subscription Status
      t.update(subRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // 4. Ledger Entry
      t.set(ledgerRef, {
        'clientId': clientId,
        'type': 'debit', // Reducing balance
        'category': 'package_cancellation',
        'amount': -creditsToRevoke,
        'description': 'Revoked remaining credits from cancelled package',
        'referenceId': subscriptionId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }
}