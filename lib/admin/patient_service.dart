import 'package:cloud_firestore/cloud_firestore.dart';

class PatientIdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _counterCollection = 'counters';
  static const String _patientIdDoc = 'patientIdCounter';
  // Start at 10000. The first generated ID will be 10001, ensuring 5 digits.
  static const int _initialId = 10000;

  /// Generates the next sequential 5-digit patient ID using a Firestore Transaction.
  /// This prevents race conditions when multiple users create clients simultaneously.
  Future<String> getNextPatientId() async {
    final counterRef = _firestore.collection(_counterCollection).doc(_patientIdDoc);

    return _firestore.runTransaction<String>((transaction) async {
      // 1. Read the current counter value within the transaction
      final DocumentSnapshot snapshot = await transaction.get(counterRef);

      int nextId;

      if (!snapshot.exists || snapshot.data() == null) {
        // Initialize the counter if it doesn't exist
        nextId = _initialId + 1;
        transaction.set(counterRef, {'lastId': nextId});
      } else {
        // Read the last ID and increment it
        final data = snapshot.data() as Map<String, dynamic>;
        // Safely cast or default if data is missing or wrong type
        final currentLastId = data['lastId'] is int ? data['lastId'] as int : _initialId;
        nextId = currentLastId + 1;

        // 2. Write the new counter value within the transaction
        transaction.update(counterRef, {'lastId': nextId});
      }

      // Format the 5-digit ID (e.g., "10001")
      return nextId.toString();
    });
  }
}