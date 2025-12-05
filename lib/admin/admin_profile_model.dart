import 'package:cloud_firestore/cloud_firestore.dart';

// 🎯 FIX: Added 'contentManager' to the Enum
enum AdminRole {
  superAdmin,
  dietitian,
  receptionist,
  support,
  contentManager
}

class AdminProfileModel {
  final String id;
  final String email;

  // --- Identity ---
  final String firstName;
  final String lastName;
  final String mobile;
  final String alternateMobile;
  final String photoUrl;
  final String gender;
  final DateTime? dob;

  // --- KYC & Legal ---
  final String? aadharNumber;
  final String? panNumber;
  final String? address;

  // --- Employment ---
  final String employeeId;
  final AdminRole role;
  final bool isActive;
  final DateTime? dateOfJoining;

  // 🎯 NEW: Permissions List for granular access
  final List<String> permissions;

  // --- Professional ---
  final String designation;
  final String regdNo;
  final List<String> qualifications;
  final List<String> specializations;
  final String bio;
  final int experienceYears;

  // --- Company ---
  final String companyName;
  final String companyEmail;
  final String website;

  // --- Auditing ---
  final bool isDeleted;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String createdBy;
  final String lastModifiedBy;

  const AdminProfileModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    this.alternateMobile = '',
    this.photoUrl = '',
    this.gender = 'Female',
    this.dob,

    this.aadharNumber,
    this.panNumber,
    this.address,

    required this.employeeId,
    required this.role,
    this.isActive = true,
    this.dateOfJoining,
    this.permissions = const [], // 🎯 Default empty

    required this.designation,
    this.regdNo = '',
    this.qualifications = const [],
    this.specializations = const [],
    this.bio = '',
    this.experienceYears = 0,

    this.companyName = '',
    this.companyEmail = '',
    this.website = '',

    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.lastModifiedBy,
  });

  factory AdminProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminProfileModel(
      id: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      mobile: data['mobile'] ?? '',
      alternateMobile: data['alternateMobile'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      gender: data['gender'] ?? 'Female',
      dob: (data['dob'] as Timestamp?)?.toDate(),

      aadharNumber: data['aadharNumber'],
      panNumber: data['panNumber'],
      address: data['address'],

      employeeId: data['employeeId'] ?? '',
      // 🎯 Robust Enum Parsing
      role: AdminRole.values.firstWhere(
              (e) => e.name == (data['role'] ?? 'dietitian'),
          orElse: () => AdminRole.dietitian
      ),
      isActive: data['isActive'] ?? true,
      dateOfJoining: (data['dateOfJoining'] as Timestamp?)?.toDate(),
      permissions: List<String>.from(data['permissions'] ?? []), // 🎯 Load Permissions

      designation: data['designation'] ?? '',
      regdNo: data['regdNo'] ?? '',
      qualifications: List<String>.from(data['qualifications'] ?? []),
      specializations: List<String>.from(data['specializations'] ?? []),
      bio: data['bio'] ?? '',
      experienceYears: (data['experienceYears'] as num?)?.toInt() ?? 0,

      companyName: data['companyName'] ?? '',
      companyEmail: data['companyEmail'] ?? '',
      website: data['website'] ?? '',

      isDeleted: data['isDeleted'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      createdBy: data['createdBy'] ?? 'system',
      lastModifiedBy: data['lastModifiedBy'] ?? 'system',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'mobile': mobile,
      'alternateMobile': alternateMobile,
      'photoUrl': photoUrl,
      'gender': gender,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,

      'aadharNumber': aadharNumber,
      'panNumber': panNumber,
      'address': address,

      'employeeId': employeeId,
      'role': role.name, // 🎯 Save Enum as String
      'isActive': isActive,
      'dateOfJoining': dateOfJoining != null ? Timestamp.fromDate(dateOfJoining!) : null,
      'permissions': permissions, // 🎯 Save Permissions

      'designation': designation,
      'regdNo': regdNo,
      'qualifications': qualifications,
      'specializations': specializations,
      'bio': bio,
      'experienceYears': experienceYears,

      'companyName': companyName,
      'companyEmail': companyEmail,
      'website': website,

      'isDeleted': isDeleted,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
    };
  }

  factory AdminProfileModel.fromMap(Map<String, dynamic> data) {
    return AdminProfileModel(
      id: data['id'] ?? '',
      email: data['email'] ?? '',

      role: AdminRole.values.firstWhere(
              (e) => e.name == (data['role'] ?? 'dietitian'),
          orElse: () => AdminRole.dietitian
      ),

      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      mobile: data['mobile'] ?? '',
      alternateMobile: data['alternateMobile'] ?? '',
      photoUrl: data['photoUrl'] ?? '',

      designation: data['designation'] ?? '',
      qualifications: List<String>.from(data['qualifications'] ?? []) ,
      regdNo: data['regdNo'] ?? '',
      specializations: List<String>.from(data['specializations'] ?? []),
      permissions:List<String>.from(data['permissions'] ?? []),
      bio: data['bio'] ?? '',
      experienceYears: (data['experienceYears'] as num?)?.toInt() ?? 0,

      companyName: data['companyName'] ?? '',
      companyEmail: data['companyEmail'] ?? '',
      website: data['website'] ?? '',
      address: data['address'] ?? '',

      employeeId: data['employeeId'] ?? '',
      dateOfJoining: (data['dateOfJoining'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,

      isDeleted: data['isDeleted'] ?? false,
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] : Timestamp.now(),
      updatedAt: data['updatedAt'] is Timestamp ? data['updatedAt'] : Timestamp.now(),
      createdBy: data['createdBy'] ?? 'system',
      lastModifiedBy: data['lastModifiedBy'] ?? 'system',
    );
  }
  AdminProfileModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? mobile,
    String? alternateMobile,
    String? photoUrl,
    String? gender,
    DateTime? dob,
    String? aadharNumber,
    String? panNumber,
    String? address,
    String? employeeId,
    AdminRole? role,
    bool? isActive,
    DateTime? dateOfJoining,
    List<String>? permissions,
    String? designation,
    String? regdNo,
    List<String>? qualifications,
    List<String>? specializations,
    String? bio,
    int? experienceYears,
    String? companyName,
    String? companyEmail,
    String? website,
    bool? isDeleted,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? createdBy,
    String? lastModifiedBy,
  }) {
    return AdminProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mobile: mobile ?? this.mobile,
      alternateMobile: alternateMobile ?? this.alternateMobile,
      photoUrl: photoUrl ?? this.photoUrl,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      panNumber: panNumber ?? this.panNumber,
      address: address ?? this.address,
      employeeId: employeeId ?? this.employeeId,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      dateOfJoining: dateOfJoining ?? this.dateOfJoining,
      permissions: permissions ?? this.permissions,
      designation: designation ?? this.designation,
      regdNo: regdNo ?? this.regdNo,
      qualifications: qualifications ?? this.qualifications,
      specializations: specializations ?? this.specializations,
      bio: bio ?? this.bio,
      experienceYears: experienceYears ?? this.experienceYears,
      companyName: companyName ?? this.companyName,
      companyEmail: companyEmail ?? this.companyEmail,
      website: website ?? this.website,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }

  String get fullName => "$firstName $lastName";

  // 🎯 Access Helper
  bool hasAccess(String permission) {
    if (role == AdminRole.superAdmin) return true;
    // Check role-specific defaults
    if (role == AdminRole.contentManager && permission == 'manage_content') return true;
    // Check specific assigned permissions
    return permissions.contains(permission);
  }

  factory AdminProfileModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AdminProfileModel(
      id: doc.id, // <--- FIX: Gets the actual document ID (e.g., 'admin_xyz')
      email: data['email'] ?? '',

      role: AdminRole.values.firstWhere(
              (e) => e.name == (data['role'] ?? 'dietitian'),
          orElse: () => AdminRole.dietitian
      ),

      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      mobile: data['mobile'] ?? '',
      alternateMobile: data['alternateMobile'] ?? '',
      photoUrl: data['photoUrl'] ?? '',

      designation: data['designation'] ?? '',
      qualifications: List<String>.from(data['qualifications'] ?? []) ,
      regdNo: data['regdNo'] ?? '',
      specializations: List<String>.from(data['specializations'] ?? []),
      permissions:List<String>.from(data['permissions'] ?? []),
      bio: data['bio'] ?? '',
      experienceYears: (data['experienceYears'] as num?)?.toInt() ?? 0,

      companyName: data['companyName'] ?? '',
      companyEmail: data['companyEmail'] ?? '',
      website: data['website'] ?? '',
      address: data['address'] ?? '',

      employeeId: data['employeeId'] ?? '',
      dateOfJoining: (data['dateOfJoining'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,

      isDeleted: data['isDeleted'] ?? false,
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] : Timestamp.now(),
      updatedAt: data['updatedAt'] is Timestamp ? data['updatedAt'] : Timestamp.now(),
      createdBy: data['createdBy'] ?? 'system',
      lastModifiedBy: data['lastModifiedBy'] ?? 'system',
    );
  }
}