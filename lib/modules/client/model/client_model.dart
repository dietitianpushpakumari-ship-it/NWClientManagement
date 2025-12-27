import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/modules/package/model/package_assignment_model.dart';

class ClientModel {
  final String id;
  final String name;
  final String mobile;
  final String email;
  final String gender;
  final DateTime dob;
  final String? photoUrl;
  final String? tag;
  final int? age;

  final String? address;
  final String? altMobile;
  final String loginId;
  final String status; // 'Active', 'Inactive'
  final bool isSoftDeleted;
  final bool hasPasswordSet;
  final String? agreementUrl;
  final String? patientId;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String? createdBy;
  final String? lastModifiedBy;
  final bool isArchived;
  final String? whatsappNumber;

  // New Field: Client Type Classification
  final String clientType;

  // 🎯 NEW FIELDS ADDED:
  final String? source;
  final String? occupation;
  final String? emergencyContactName;
  final String? emergencyContactPhone;


  ClientModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.gender,
    required this.dob,
    this.age,
    this.photoUrl,
    required this.loginId,
    this.status = 'Inactive',
    this.isSoftDeleted = false,
    this.hasPasswordSet = false,
    this.tag,
    this.address,
    this.altMobile,
    this.agreementUrl,
    required this.patientId,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.lastModifiedBy,
    this.isArchived = false,
    this.whatsappNumber,
    this.clientType = 'new',
    // 🎯 NEW FIELDS INITIALIZED:
    this.source,
    this.occupation,
    this.emergencyContactName,
    this.emergencyContactPhone,
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
      age: data['age'] ?? 0,
      photoUrl: data['photoUrl'],
      tag: data['tag'] as String?,
      loginId: data['loginId'] ?? data['mobile'] ?? '',
      status: data['status'] ?? 'Inactive',
      isSoftDeleted: data['isSoftDeleted'] ?? false,
      hasPasswordSet: data['hasPasswordSet'] ?? false,
      address: data['address'] as String?,
      altMobile: data['altMobile'] as String?,
      agreementUrl: data['agreementUrl'] as String?,
      patientId: data['patientId'] as String?,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      createdBy: data['createdBy'] ?? 'unknown',
      lastModifiedBy: data['lastModifiedBy'] ?? 'unknown',
      isArchived: data['isArchived'] ?? false,
      whatsappNumber: data['whatsappNumber'] ?? '',
      clientType: data['clientType'] ?? 'new',
      // 🎯 NEW FIELDS LOADED:
      source: data['source'] as String?,
      occupation: data['occupation'] as String?,
      emergencyContactName: data['emergencyContactName'] as String?,
      emergencyContactPhone: data['emergencyContactPhone'] as String?,
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
      'loginId': loginId,
      'status': status,
      'isSoftDeleted': isSoftDeleted,
      'hasPasswordSet': hasPasswordSet,
      'address': address,
      'altMobile': altMobile,
      'agreementUrl': agreementUrl,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
      'patientId': patientId,
      'isArchived': isArchived,
      'whatsappNumber': whatsappNumber,
      'clientType': clientType,
      // 🎯 NEW FIELDS SAVED:
      'source': source,
      'occupation': occupation,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
    };
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    String? gender,
    String? loginId,
    String? status,
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
    String? clientType,
    // 🎯 NEW FIELDS COPIED:
    String? source,
    String? occupation,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      loginId: loginId ?? this.loginId,
      status: status ?? this.status,
      dob: dob ?? this.dob,
      age: age ?? this.age,
      address: address ?? this.address,
      altMobile: altMobile ?? this.altMobile,
      hasPasswordSet: hasPasswordSet ?? this.hasPasswordSet,
      agreementUrl: agreementUrl ?? this.agreementUrl,
      photoUrl: photoUrl ?? this.photoUrl,
      patientId: patientId ?? this.patientId,
      isArchived: isArchived ?? this.isArchived,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      clientType: clientType ?? this.clientType,
      // 🎯 NEW FIELDS COPIED:
      source: source ?? this.source,
      occupation: occupation ?? this.occupation,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
    );
  }
}