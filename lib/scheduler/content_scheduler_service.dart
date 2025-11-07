// lib/services/content_scheduler_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/scheduler/content_scheduler_model.dart';

class ContentSchedulerService {
  final CollectionReference _schedulerCollection =
  FirebaseFirestore.instance.collection('content_schedulers');

  // --- SAVE / UPDATE ---
  Future<void> saveScheduler(ContentSchedulerModel scheduler) async {
    final data = scheduler.toMap();
    if (scheduler.id.isEmpty) {
      // Create (Set doc ID if possible, otherwise use add)
      await _schedulerCollection.add(data);
    } else {
      // Update
      await _schedulerCollection.doc(scheduler.id).update(data);
    }
  }

  // --- READ (Stream for a specific client) ---
  Stream<List<ContentSchedulerModel>> streamClientSchedulers(String clientId) {
    return _schedulerCollection
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ContentSchedulerModel.fromFirestore(doc))
          .toList();
    });
  }

  // --- DELETE ---
  Future<void> deleteScheduler(String id) {
    return _schedulerCollection.doc(id).delete();
  }
}