import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/consultation_session_model.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';

final consultationServiceProvider = Provider((ref) => ConsultationSessionService(ref));

class ConsultationSessionService {
  final Ref _ref;
  ConsultationSessionService(this._ref);

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  CollectionReference<ConsultationSessionModel> get _collection =>
      _db.collection('consultation_sessions').withConverter(
        fromFirestore: (snapshot, _) => ConsultationSessionModel.fromFirestore(snapshot),
        toFirestore: (session, _) => session.toFirestore(),
      );

  // 🎯 UPDATED: Start Session with optional Parent Link
  Future<String> startSession(
      String clientId,
      String dietitianId, {
        String? parentId,
        bool isFollowup = false,
      }) async {
    final newSession = ConsultationSessionModel(
      clientId: clientId,
      dietitianId: dietitianId,
      startTime: Timestamp.now(),
      status: 'Ongoing',
      sessionDate: Timestamp.now(),
      steps: {},
      // 🎯 Set Type and Link
      consultationType: isFollowup ? 'Followup' : 'Initial',
      parentId: parentId,
    );

    final doc = await _collection.add(newSession);
    return doc.id;
  }

  Future<ConsultationSessionModel> getSessionById(String sessionId) async {
    try {
      final doc = await _collection.doc(sessionId).get();
      if (doc.exists) {
        return doc.data()!;
      } else {
        throw Exception("Session not found");
      }
    } catch (e) {
      throw Exception("Error fetching session: $e");
    }
  }

  Future<ConsultationSessionModel?> getActiveSession(String clientId) async {
    final query = await _collection
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: 'Ongoing')
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.data();
  }

  Future<ConsultationSessionModel?> getLatestSession(String clientId) async {
    try {
      final query = await _collection
          .where('clientId', isEqualTo: clientId)
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return query.docs.first.data();
    } catch (e) {
      print("Error fetching latest session: $e");
      return null;
    }
  }

  Future<void> updateSessionLinks(String sessionId, {String? vitalsId, String? dietPlanId}) async {
    try {
      final Map<String, dynamic> updates = {};
      if (vitalsId != null) updates['linkedVitalsId'] = vitalsId;
      if (dietPlanId != null) updates['linkedDietPlanId'] = dietPlanId;

      if (updates.isNotEmpty) {
        await _collection.doc(sessionId).update(updates);
      }
    } catch (e) {
      throw Exception("Failed to update session links: $e");
    }
  }

  Future<void> closeSession(String sessionId) async {
    await _collection.doc(sessionId).update({
      'status': 'complete',
      'endTime': Timestamp.now(),
    });
  }

  Future<void> deleteSession(String sessionId) async {
    await _collection.doc(sessionId).delete();
  }

  Stream<List<ConsultationSessionModel>> streamSessionHistory(String clientId) {
    return _collection
        .where('clientId', isEqualTo: clientId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}