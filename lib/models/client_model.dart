// lib/models/client_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/models/package_assignment_model.dart';

class ClientModel {
  // Primary Firestore Document ID (Auto-generated UUID)
  final String id;
  final String name;
  final String mobile;
  final String email;
  final String gender;
  final DateTime dob;
  final String? photoUrl;
  final String? tag;

  // 🎯 NEW FIELD: Address
  final String? address;
  // 🎯 NEW FIELD: Alternative Mobile Number
  final String? altMobile;

  // Login ID, can be mobile or a 10-digit system ID
  final String loginId;

  // Status is strictly 'Active' or 'Inactive'
  final String status;
  final bool isSoftDeleted;

  // Tracks if the password has been set (Credential created)
  final bool hasPasswordSet;
  final Map<String, PackageAssignmentModel> packageAssignments;

  // 🎯 NEW FIELD: Agreement URL (for uploaded file)
  final String? agreementUrl;


  ClientModel( {
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.gender,
    required this.dob,
    this.photoUrl,
    required this.loginId, // Must be provided
    this.status = 'Inactive', // Default to Inactive
    this.isSoftDeleted = false,
    this.hasPasswordSet = false,
    this.packageAssignments = const {},
    this.tag,
    this.address, // 🎯 ADDED
    this.altMobile, // 🎯 ADDED
    this.agreementUrl, // 🎯 ADDED
  });

  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    final Map<String, dynamic>? rawPackages = data['packageAssignments'];
    final Map<String, PackageAssignmentModel> packages = {};
    if (rawPackages != null) {
      rawPackages.forEach((key, value) {
        packages[key] = PackageAssignmentModel.fromMap(value);
      });
    }

    return ClientModel(
      id: doc.id,
      name: data['name'] ?? '',
      mobile: data['mobile'] ?? '',
      email: data['email'] ?? '',
      gender: data['gender'] ?? '',
      dob: (data['dob'] as Timestamp).toDate(),
      photoUrl: data['photoUrl'],
      tag: data['tag'] as String?,

      loginId: data['loginId'] ?? data['mobile'] ?? '',
      status: data['status'] ?? 'Inactive',
      isSoftDeleted: data['isSoftDeleted'] ?? false,
      hasPasswordSet: data['hasPasswordSet'] ?? false,
      packageAssignments: packages,

      // 🎯 NEW FIELDS MAPPING
      address: data['address'] as String?,
      altMobile: data['altMobile'] as String?,
      agreementUrl: data['agreementUrl'] as String?,

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mobile': mobile,
      'email': email,
      'gender': gender,
      'dob': Timestamp.fromDate(dob),
      'photoUrl': photoUrl,
      'tag': tag,
      'loginId': loginId, // Save the chosen login ID
      'status': status,
      'isSoftDeleted': isSoftDeleted,
      'hasPasswordSet': hasPasswordSet,
      'activePackages': packageAssignments.map((key, value) => MapEntry(key, value.toMap())),

      // 🎯 NEW FIELDS TO MAP
      'address': address,
      'altMobile': altMobile,
      'agreementUrl': agreementUrl,
    };
  }
}