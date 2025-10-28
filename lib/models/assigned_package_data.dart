import 'package:flutter/foundation.dart'; // For describeEnum
import 'package:cloud_firestore/cloud_firestore.dart'; // Only if needed by nested models
import 'package:nutricare_client_management/modules/package/model/package_assignment_model.dart'; // Import dependency

enum PaymentFilter { all, fullyPaid, pending, partiallyPaid, notPaid }

class AssignedPackageData {
  final String clientName;
  final PackageAssignmentModel assignment;
  final double collectedAmount;
  final double pendingAmount;
  final double discountAmount;
  final PaymentFilter status;

  AssignedPackageData({
    required this.clientName,
    required this.assignment,
    required this.collectedAmount,
  }) : pendingAmount = assignment.bookedAmount - collectedAmount,
        discountAmount = assignment.discount,
      status = _calculateStatus(assignment.bookedAmount, collectedAmount);

  static PaymentFilter _calculateStatus(double booked, double collected) {
    if (collected >= booked - 0.01) return PaymentFilter.fullyPaid;
    if (collected > 0) return PaymentFilter.partiallyPaid;
    return PaymentFilter.notPaid;
  }
}