// lib/models/diet_plan_assignment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';


/// Represents a specific Master Diet Plan assigned to a client.
class DietPlanAssignmentModel {
  final String id;
  final String clientId;
  final String clientName; // Denormalized for easy viewing
  final String masterPlanId;
  final String masterPlanName; // Denormalized name
  final DateTime startDate;
  final DateTime expiryDate;
  final String assignedByUserId;
  final bool isDeleted; // Soft delete flag
  final DateTime? createdDate;

  const DietPlanAssignmentModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.masterPlanId,
    required this.masterPlanName,
    required this.startDate,
    required this.expiryDate,
    required this.assignedByUserId,
    this.isDeleted = false,
    this.createdDate,
  });

  // Check if the plan is currently active
  bool get isActive {
    final now = DateTime.now();
    // Check if the current date is between or equal to the start and expiry dates, and not deleted
    return !isDeleted && (startDate.isBefore(now) || startDate.isAtSameMomentAs(now)) && (expiryDate.isAfter(now) || expiryDate.isAtSameMomentAs(now));
  }

  // Factory constructor from Firestore
  factory DietPlanAssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DietPlanAssignmentModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? 'Unknown Client',
      masterPlanId: data['masterPlanId'] ?? '',
      masterPlanName: data['masterPlanName'] ?? 'Unknown Plan',
      startDate: (data['startDate'] as Timestamp).toDate(),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      assignedByUserId: data['assignedByUserId'] ?? '',
      isDeleted: data['isDeleted'] ?? false,
      createdDate: (data['createdDate'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'masterPlanId': masterPlanId,
      'masterPlanName': masterPlanName,
      'startDate': Timestamp.fromDate(startDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'assignedByUserId': assignedByUserId,
      'isDeleted': isDeleted,
      'createdDate': createdDate != null ? Timestamp.fromDate(createdDate!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // For equatable comparison
  @override
  List<Object?> get props => [
    id, clientId, masterPlanId, startDate, expiryDate, isDeleted
  ];
}