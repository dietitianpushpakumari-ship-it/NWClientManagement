import 'package:cloud_firestore/cloud_firestore.dart';

import 'habit_master_model.dart';

class HabitMasterService {
  final CollectionReference _collection =
  FirebaseFirestore.instance.collection('habit_master');

  // --- READ: Stream all active habits ---
  Stream<List<HabitMasterModel>> streamAllHabits() {
    return _collection
        .where('isActive', isEqualTo: true)
        .orderBy('title')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => HabitMasterModel.fromFirestore(doc))
        .toList());
  }

  // --- WRITE: Create or Update ---
  Future<void> saveHabit(HabitMasterModel habit) async {
    if (habit.id.isEmpty) {
      await _collection.add(habit.toMap());
    } else {
      await _collection.doc(habit.id).update(habit.toMap());
    }
  }

  // --- DELETE: Soft Delete ---
  Future<void> deleteHabit(String id) async {
    await _collection.doc(id).update({'isActive': false});
  }
}