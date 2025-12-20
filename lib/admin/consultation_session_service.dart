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

  // 🎯 CREATE: Start a new session
  Future<String> startSession(String clientId, String dietitianId) async {
    final newSession = ConsultationSessionModel(
      clientId: clientId,
      dietitianId: dietitianId,
      startTime: Timestamp.now(),
      status: 'Ongoing', sessionDate: Timestamp.now()
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

  // 🎯 READ: Get current active session for a client
  Future<ConsultationSessionModel?> getActiveSession(String clientId) async {
    final query = await _collection
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: 'Ongoing')
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.data();
  }

  // 🎯 UPDATE: Link Vitals or Diet Plan to Session
  Future<void> updateSessionLinks(String sessionId, {String? vitalsId, String? dietPlanId}) async {
    final updates = <String, dynamic>{};
    if (vitalsId != null) updates['linkedVitalsId'] = vitalsId;
    if (dietPlanId != null) updates['linkedDietPlanId'] = dietPlanId;

    await _collection.doc(sessionId).update(updates);
  }

  // 🎯 CLOSE: Finalize session and lock data
  Future<void> closeSession(String sessionId) async {
    await _collection.doc(sessionId).update({
      'status': 'Closed',
      'endTime': Timestamp.now(),
    });
  }

  // 🎯 DELETE: Soft delete (if needed)
  Future<void> deleteSession(String sessionId) async {
    await _collection.doc(sessionId).delete();
  }

  // STREAM: Get session history for a client
  Stream<List<ConsultationSessionModel>> streamSessionHistory(String clientId) {
    return _collection
        .where('clientId', isEqualTo: clientId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}