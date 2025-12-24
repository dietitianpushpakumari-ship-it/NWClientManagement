import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import '../model/vitals_model.dart';

class VitalsService {
  final Ref _ref;

  VitalsService(this._ref);

  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  CollectionReference get _vitalsCollection => _firestore.collection(MasterCollectionMapper.getPath(TransactionEntity.entity_patientVitals));

  // SAVE VITALS (Create or Update)
  Future<String> saveVitals(VitalsModel vitals) async {
    try {
      final data = vitals.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();

      if (vitals.id.isEmpty) {
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _vitalsCollection.add(data);
        return docRef.id;
      } else {
        await _vitalsCollection.doc(vitals.id).update(data);
        return vitals.id;
      }
    } catch (e) {
      throw Exception("Failed to save vitals: $e");
    }
  }

  // DELETE VITALS
  Future<void> deleteVitals(String recordId) async {
    try {
      await _vitalsCollection.doc(recordId).delete();
    } catch (e) {
      throw Exception("Failed to delete vitals record: $e");
    }
  }

  // GET SINGLE VITALS RECORD BY ID
  Future<VitalsModel?> getVitalsById(String recordId) async {
    try {
      final doc = await _vitalsCollection.doc(recordId).get();
      if (doc.exists) {
        return VitalsModel.fromFirestore(doc);
      }
    } catch (e) {
      throw Exception("Failed to fetch vitals record: $e");
    }
    return null;
  }

  // GET LATEST VITALS RECORD FOR A CLIENT
  Future<VitalsModel?> getLatestVitals(String clientId) async {
    try {
      final snapshot = await _vitalsCollection
          .where('clientId', isEqualTo: clientId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return VitalsModel.fromFirestore(snapshot.docs.first);
      }
    } catch (e) {
      print("Error fetching latest vitals: $e");
    }
    return null;
  }

  // STREAM ALL VITALS FOR CLIENT
  Stream<List<VitalsModel>> streamAllVitalsForClient(String clientId) {
    return _vitalsCollection
        .where('clientId', isEqualTo: clientId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => VitalsModel.fromFirestore(doc)).toList());
  }

  Future<List<VitalsModel>> getClientVitals(String clientId) async {
    try {
      final list = await streamAllVitalsForClient(clientId).first;
      return list;
    } catch (e) {
      print("Error fetching client vitals list: $e");
      return [];
    }
  }

  // 🎯 CORRECTED METHOD: Prevents overwriting history on new sessions
  Future<void> updateHistoryData({
    required String clientId,
    required Map<String, dynamic> updateData,
    VitalsModel? existingVitals,
  }) async {
    try {
      VitalsModel? vitalsToUpdate = existingVitals;

      // 1. If explicit record not provided, try fetching latest
      if (vitalsToUpdate == null || vitalsToUpdate.id.isEmpty) {
        vitalsToUpdate = await getLatestVitals(clientId);

        // 🎯 CRITICAL FIX: If we fetched the latest record, check Session ID match.
        // If the 'updateData' has a sessionId (e.g. "Session B") but the fetched
        // latest record belongs to "Session A", DO NOT UPDATE "Session A".
        // Instead, allow creation of a NEW record for "Session B".
        if (vitalsToUpdate != null &&
            updateData.containsKey('sessionId') &&
            updateData['sessionId'] != null &&
            vitalsToUpdate.sessionId != updateData['sessionId']) {

          // Mismatch detected: We are starting a NEW session but fetched an OLD one.
          // Discard the old one so we fall into the "Create New" block below.
          vitalsToUpdate = null;
        }
      }

      // Clean up nulls
      updateData.removeWhere((key, value) => value == null);

      if (vitalsToUpdate != null && vitalsToUpdate.id.isNotEmpty) {
        // Update the existing document (Same Session)
        await _vitalsCollection.doc(vitalsToUpdate.id).update(updateData);
      } else {
        // Create a brand new document (New Session)
        final Map<String, dynamic> newVitalsMap = {
          'clientId': clientId,
          'date': DateTime.now(),
          'isFirstConsultation': false,
          ...updateData,
        };

        final VitalsModel newVitals = VitalsModel.fromMap('', newVitalsMap);
        await saveVitals(newVitals);
      }
    } catch (e) {
      throw Exception("Failed to update history data: $e");
    }
  }
}