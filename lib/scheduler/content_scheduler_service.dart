// lib/services/content_scheduler_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/scheduler/content_scheduler_model.dart';

class ContentSchedulerService {
  final Ref _ref; // Store Ref to access dynamic providers
  ContentSchedulerService(this._ref);
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  CollectionReference  get _schedulerCollection =>
  _firestore.collection('content_schedulers');

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