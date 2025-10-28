// lib/models/client_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/modules/package/model/package_assignment_model.dart';

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
  final int? age; //

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


  final String? patientId; // 5-digit auto-generated ID

  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String? createdBy;
  final String? lastModifiedBy;
  final bool isArchived;
  final String? whatsappNumber;


  ClientModel( {
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.gender,
    required this.dob,
    this.age,
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
    required this.patientId,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.lastModifiedBy,
    this.isArchived = false,
    this.whatsappNumber

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
      dob: (data['dob'] as Timestamp?)?.toDate() ?? DateTime.now(),
     // dob: (data['dob'] as Timestamp).toDate(),
      age: data['age'] ?? 0,
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
        patientId:data['patientId'] as String?,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      createdBy: data['createdBy'] ?? 'unknown',
      lastModifiedBy: data['lastModifiedBy'] ?? 'unknown',
      isArchived: data['isArchived'] ?? false,
      whatsappNumber: data['whatsappNumber'] ?? '',

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mobile': mobile,
      'email': email,
      'gender': gender,
      'dob': Timestamp.fromDate(dob),
      'age': age,
      'photoUrl': photoUrl,
      'tag': tag,
      'loginId': loginId, // Save the chosen login ID
      'status': status,
      'isSoftDeleted': isSoftDeleted,
      'hasPasswordSet': hasPasswordSet,
      'activePackages': packageAssignments.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),

      // 🎯 NEW FIELDS TO MAP
      'address': address,
      'altMobile': altMobile,
      'agreementUrl': agreementUrl,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
      'patientId': patientId,
      'isArchived': isArchived,
      'whatsappNumber' : whatsappNumber,
    };
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    String? gender,
    String? loginId,
    DateTime? dob,
    int? age,
    String? address,
    String? altMobile,
    bool? hasPasswordSet,
    String? agreementUrl,
    String? photoUrl,
    String? patientId,
    bool? isArchived,
    String? whatsappNumber,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      loginId: loginId ?? this.loginId,
      dob: dob ?? this.dob,
      age: age ?? this.age,
      address: address ?? this.address,
      altMobile: altMobile ?? this.altMobile,
      hasPasswordSet: hasPasswordSet ?? this.hasPasswordSet,
      agreementUrl: agreementUrl ?? this.agreementUrl,
      photoUrl: photoUrl ?? this.photoUrl,
      patientId: this.patientId,
      isArchived: this.isArchived,
      whatsappNumber: this.whatsappNumber

    );
  }
}


