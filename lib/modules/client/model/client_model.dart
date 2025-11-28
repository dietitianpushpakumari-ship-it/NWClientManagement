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
  final Map<String, PackageAssignmentModel> packageAssignments;
  final String? agreementUrl;
  final String? patientId;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String? createdBy;
  final String? lastModifiedBy;
  final bool isArchived;
  final String? whatsappNumber;

  // New Field: Client Type Classification
  // Values: 'new', 'one_time', 'active', 'expired'
  final String clientType;

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
    this.status = 'Inactive', // Default status
    this.isSoftDeleted = false,
    this.hasPasswordSet = false,
    this.packageAssignments = const {},
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
    this.clientType = 'new', // Default type
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
      status: data['status'] ?? 'Inactive', // Load Status
      isSoftDeleted: data['isSoftDeleted'] ?? false,
      hasPasswordSet: data['hasPasswordSet'] ?? false,
      packageAssignments: packages,
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
      'status': status, // Save Status
      'isSoftDeleted': isSoftDeleted,
      'hasPasswordSet': hasPasswordSet,
      'activePackages': packageAssignments.map((key, value) => MapEntry(key, value.toMap())),
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
    };
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    String? gender,
    String? loginId,
    String? status, // 🎯 Added Status here
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
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      loginId: loginId ?? this.loginId,
      status: status ?? this.status, // 🎯 Copy Status
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
    );
  }
}