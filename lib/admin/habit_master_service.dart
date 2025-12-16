import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/habit_master_model.dart';

class HabitMasterService {

  final Ref _ref; // Store Ref to access dynamic providers
  HabitMasterService(this._ref);

  // 🎯 DYNAMIC GETTERS (Switch based on Tenant)
  // These will now automatically point to 'Guest', 'Live', or 'Clinic A' DB
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  CollectionReference get _habitCollection => _firestore.collection('master_habits');

  // 1. Stream all active habits (List)
  Stream<List<HabitMasterModel>> streamActiveHabits() {
    return _habitCollection
        .where('isDeleted', isEqualTo: false)
        .orderBy('category')
        .orderBy('title')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => HabitMasterModel.fromFirestore(doc))
        .toList());
  }

  // 2. Unified Save Method (Add/Update)
  Future<void> save(HabitMasterModel habit) async {
    final data = habit.toMap();

    if (habit.id.isEmpty) {
      // Add (Create)
      final duplicateCheck = await _habitCollection
          .where('title', isEqualTo: habit.title)
          .where('isDeleted', isEqualTo: false)
          .limit(1)
          .get();

      if (duplicateCheck.docs.isNotEmpty) {
        throw Exception("Habit '${habit.title}' already exists.");
      }

      await _habitCollection.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
      });
    } else {
      // Update
      await _habitCollection.doc(habit.id).update(data);
    }
  }

  // 3. Soft Delete
  Future<void> delete(String habitId) async {
    await _habitCollection.doc(habitId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }
}