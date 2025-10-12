// lib/services/diet_plan_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diet_plan_assignment_model.dart';

class DietPlanService {
  // Mock Firebase collection reference
  final CollectionReference _assignmentsCollection = FirebaseFirestore.instance.collection('dietPlanAssignments');

  /// Fetches all active and inactive diet plan assignments for a specific client.
  Future<List<DietPlanAssignmentModel>> getClientAssignments(String clientId) async {
    // --- Mock Data Generation ---
    await Future.delayed(const Duration(milliseconds: 500));
    final mockAssignments = [
      DietPlanAssignmentModel(
        id: 'ass1',
        clientId: clientId,
        clientName: 'Client Name Placeholder',
        masterPlanId: 'mp1',
        masterPlanName: 'PCOS Weight Loss 1800KCal',
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        expiryDate: DateTime.now().add(const Duration(days: 50)),
        assignedByUserId: 'user1',
      ),
      DietPlanAssignmentModel(
        id: 'ass2',
        clientId: clientId,
        clientName: 'Client Name Placeholder',
        masterPlanId: 'mp2',
        masterPlanName: 'Maintenance Keto 1500KCal',
        startDate: DateTime.now().subtract(const Duration(days: 120)),
        expiryDate: DateTime.now().subtract(const Duration(days: 5)),
        assignedByUserId: 'user1',
      ),
      DietPlanAssignmentModel(
        id: 'ass3',
        clientId: clientId,
        clientName: 'Client Name Placeholder',
        masterPlanId: 'mp3',
        masterPlanName: 'Muscle Gain Plan',
        startDate: DateTime.now().subtract(const Duration(days: 300)),
        expiryDate: DateTime.now().subtract(const Duration(days: 200)),
        assignedByUserId: 'user2',
        isDeleted: true, // Example of a deleted/inactive one
      ),
    ];
    // Filter out soft-deleted ones for standard view, but keep others
    return mockAssignments.where((a) => !a.isDeleted).toList();
    // --- End Mock Data Generation ---

    // Real Firebase Query:
    /*
    final snapshot = await _assignmentsCollection
        .where('clientId', isEqualTo: clientId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('startDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => DietPlanAssignmentModel.fromFirestore(doc)).toList();
    */
  }

  /// Performs a soft delete (marks as deleted) for a plan assignment.
  Future<void> softDeleteAssignment(String assignmentId) async {
    // In a real app, you'd use Firestore:
    // await _assignmentsCollection.doc(assignmentId).update({'isDeleted': true, 'updatedAt': FieldValue.serverTimestamp()});

    await Future.delayed(const Duration(milliseconds: 300));
    // print('Soft Deleted Diet Plan Assignment: $assignmentId');
  }

  /// Navigation placeholder for editing an existing assignment
  void editAssignment(DietPlanAssignmentModel assignment) {
    // In a real app, this would navigate to the PackageAssignmentPage
    // print('Navigating to edit assignment: ${assignment.masterPlanName}');
  }
}