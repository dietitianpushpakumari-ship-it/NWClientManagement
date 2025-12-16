import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart'; // Import to access firestoreProvider
import '../model/vitals_model.dart'; // Import your VitalsModel


class VitalsService {
  final Ref _ref; // 🎯 STEP 1: Add the Ref field

  // 🎯 STEP 2: Update the constructor to accept the Ref
  VitalsService(this._ref);

  // 🎯 STEP 3: Replace the old static/final Firebase instance with a DYNAMIC GETTER
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  CollectionReference get _vitalsCollection => _firestore.collection('vitals');


  // -----------------------------------------------------------
  // 2. FINAL VITALSSERVICE CODE
  // -----------------------------------------------------------

  // SAVE VITALS (Create or Update)
  Future<void> saveVitals(VitalsModel vitals) async {
    try {
      final data = vitals.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();

      if (vitals.id.isEmpty) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _vitalsCollection.add(data);
      } else {
        await _vitalsCollection.doc(vitals.id).update(data);
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
  Future<VitalsModel?> getLatestVitals(String clientId) async {
    try {
      final snapshot = await _vitalsCollection
          .where('clientId', isEqualTo: clientId)
          .orderBy('date', descending: true)
          .limit(1) // Only need the latest one
          .get();

      if (snapshot.docs.isNotEmpty) {
        return VitalsModel.fromFirestore(snapshot.docs.first);
      }
    } catch (e) {
      print("Error fetching latest vitals: $e");
    }
    return null;
  }
  // STREAM ALL VITALS FOR CLIENT (For History/Comparison UI)
  Stream<List<VitalsModel>> streamAllVitalsForClient(String clientId) {
    return _vitalsCollection
        .where('clientId', isEqualTo: clientId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => VitalsModel.fromFirestore(doc)).toList());
  }
    // 🎯 REINTRODUCED FUTURE METHOD (For existing FutureBuilders)
    // This method uses the stream to fetch a single list snapshot.
    Future<List<VitalsModel>> getClientVitals(String clientId) async {
      try {
        // Use .first to grab the first snapshot of the stream and return it as a Future.
        final list = await streamAllVitalsForClient(clientId).first;
        return list;
      } catch (e) {
        // Handle the case where the collection might be empty or the stream fails immediately.
        print("Error fetching client vitals list: $e");
        return [];
      }
    }

}