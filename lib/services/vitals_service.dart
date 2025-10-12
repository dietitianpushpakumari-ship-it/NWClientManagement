// lib/services/vitals_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/vitals_model.dart'; // Ensure this models exists

// Assuming you have a logger instance initialized globally or in your services file
final Logger _logger = Logger(/* ... */);

class VitalsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getVitalsCollection(String clientId) {
    // Stores vitals in clients/{clientId}/vitals
    return _firestore.collection('clients').doc(clientId).collection('vitals');
  }

  // --- CREATE/ADD NEW VITALS RECORD ---

  Future<void> addVitals(VitalsModel vitals) async {
    _logger.i('Adding new vitals record for client: ${vitals.clientId}');
    try {
      await _getVitalsCollection(vitals.clientId).add(vitals.toMap());
    } catch (e, stack) {
      _logger.e('Error adding vitals: ${e.toString()}', error: e, stackTrace: stack);
      throw Exception('Failed to add vitals record.');
    }
  }

  // --- READ/RETRIEVAL: GET ALL VITALS FOR HISTORY ---

  Future<List<VitalsModel>> getClientVitals(String clientId) async {
    try {
      final snapshot = await _getVitalsCollection(clientId)
          .orderBy('date', descending: true) // Sort by most recent first
          .get();

      return snapshot.docs.map((doc) => VitalsModel.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.e('Error fetching vitals: ${e.toString()}');
      return [];
    }
  }

  // --- UPDATE EXISTING VITALS RECORD ---

  Future<void> updateVitals(VitalsModel vitals) async {
    if (vitals.id.isEmpty) {
      throw Exception('Vitals ID is required for update.');
    }
    _logger.i('Updating vitals record ${vitals.id} for client: ${vitals.clientId}');
    try {
      await _getVitalsCollection(vitals.clientId).doc(vitals.id).update(vitals.toMap());
    } catch (e, stack) {
      _logger.e('Error updating vitals: ${e.toString()}', error: e, stackTrace: stack);
      throw Exception('Failed to update vitals record.');
    }
  }

  // --- DELETE VITALS RECORD ---

  Future<void> deleteVitals(String clientId, String recordId) async {
    _logger.i('Deleting vitals record $recordId for client: $clientId');
    try {
      await _getVitalsCollection(clientId).doc(recordId).delete();
    } catch (e, stack) {
      _logger.e('Error deleting vitals: ${e.toString()}', error: e, stackTrace: stack);
      throw Exception('Failed to delete vitals record.');
    }
  }
}