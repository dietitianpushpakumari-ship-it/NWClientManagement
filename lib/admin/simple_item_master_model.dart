// lib/master/model/simple_master_item_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SimpleMasterItemModel {
  final String id;
  final String name; // The primary display name
  final bool isDeleted;

  SimpleMasterItemModel({
    required this.id,
    required this.name,
    this.isDeleted = false,
  });

  factory SimpleMasterItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return SimpleMasterItemModel(
      id: doc.id,
      name: data?['name'] as String? ?? 'N/A',
      isDeleted: data?['isDeleted'] as bool? ?? false,
    );
  }

  bool get isValid => !isDeleted && name.isNotEmpty;
}