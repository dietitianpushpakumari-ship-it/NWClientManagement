import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';

class VitalsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🎯 1. SAVE VITALS (Create or Update)
  Future<void> saveVitals(VitalsModel vitals) async {
    try {
      final data = vitals.toMap();
      // Ensure timestamp is set correctly
      data['updatedAt'] = FieldValue.serverTimestamp();

      if (vitals.id.isEmpty) {
        // New Record
        data['createdAt'] = FieldValue.serverTimestamp();
        await _db.collection('vitals').add(data);
      } else {
        // Update Existing
        await _db.collection('vitals').doc(vitals.id).update(data);
      }
    } catch (e) {
      throw Exception("Failed to save vitals: $e");
    }
  }

  // 🎯 2. DELETE VITALS
  Future<void> deleteVitals(String clientId, String recordId) async {
    try {
      await _db.collection('vitals').doc(recordId).delete();
    } catch (e) {
      throw Exception("Failed to delete vitals: $e");
    }
  }

  // 🎯 3. GET VITALS (History)
  Future<List<VitalsModel>> getClientVitals(String clientId) async {
    try {
      final snapshot = await _db.collection('vitals')
          .where('clientId', isEqualTo: clientId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => VitalsModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception("Failed to fetch vitals: $e");
    }
  }
}