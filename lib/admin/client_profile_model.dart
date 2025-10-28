import 'package:cloud_firestore/cloud_firestore.dart';

class ClientProfileModel {
  final String id; // Firebase Auth UID OR temporary Firestore Document ID

  final String patientId; // 5-digit auto-generated ID

  // These are required fields in the model, but may be empty strings
  // until the client is authenticated (Steps 1-3 use empty strings)
  final String email;
  final String loginId;

  // Consultation data fields
  final String clientName;
  final int age; // Added Age field
  final String mobileNumber;
  final String gender; // Assuming it's tracked
  final String address; // Assuming it's tracked

  final Timestamp dateOfBirth; // Stub for compatibility, or calculated from age

  final bool isDeleted;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String createdBy;
  final String lastModifiedBy;

  const ClientProfileModel({
    required this.id,
    required this.patientId,
    this.email = '',
    this.loginId = '',
    required this.clientName,
    required this.age,
    required this.mobileNumber,
    required this.gender,
    required this.address,
    required this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.lastModifiedBy,
    this.isDeleted = false,
  });

  factory ClientProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ClientProfileModel(
      id: doc.id,
      patientId: data['patientId'] ?? 'N/A',
      email: data['email'] ?? '',
      loginId: data['loginId'] ?? '',
      clientName: data['clientName'] ?? '',
      age: data['age'] ?? 0,
      mobileNumber: data['mobileNumber'] ?? '',
      gender: data['gender'] ?? '',
      address: data['address'] ?? '',
      dateOfBirth: data['dateOfBirth'] ?? Timestamp.now(),
      isDeleted: data['isDeleted'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      createdBy: data['createdBy'] ?? 'unknown',
      lastModifiedBy: data['lastModifiedBy'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'email': email,
      'loginId': loginId,
      'clientName': clientName,
      'age': age,
      'mobileNumber': mobileNumber,
      'gender': gender,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'isDeleted': isDeleted,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
    };
  }
}