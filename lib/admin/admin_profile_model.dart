import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminRole {
  superAdmin,    // 👑 YOU (Global Access)
  clinicAdmin,   // 🏥 CLINIC OWNER (Full Access to ONE Clinic)
  dietitian,     // 🩺 STAFF
  receptionist,
  support,
  contentManager
}

class AdminProfileModel {
  // ... (Keep all existing fields like id, email, firstName etc.) ...
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String mobile;
  final String alternateMobile;
  final String photoUrl;
  final String gender;
  final DateTime? dob;
  final String? aadharNumber;
  final String? panNumber;
  final String? address;
  final String employeeId;
  final AdminRole role;
  final bool isActive;
  final DateTime? dateOfJoining;
  final List<String> permissions;
  final String designation;
  final String regdNo;
  final List<String> qualifications;
  final List<String> specializations;
  final String bio;
  final int experienceYears;
  final String companyName;
  final String companyEmail;
  final String website;
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
    this.permissions = const [],
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

      // 🎯 PARSE ROLE CORRECTLY
      role: _parseRole(data['role']),

      isActive: data['isActive'] ?? true,
      dateOfJoining: (data['dateOfJoining'] as Timestamp?)?.toDate(),
      permissions: List<String>.from(data['permissions'] ?? []),
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

  // 🎯 STRICT ROLE PARSING
  static AdminRole _parseRole(dynamic roleData) {
    if (roleData == null) return AdminRole.dietitian;
    final String roleString = roleData.toString().trim();

    // 1. Super Admin (Only explicitly 'superAdmin')
    if (roleString == 'superAdmin' || roleString == 'super_admin') {
      return AdminRole.superAdmin;
    }

    // 2. Clinic Admin (Previously 'owner', 'admin')
    if (roleString == 'owner' || roleString == 'admin' || roleString == 'clinicAdmin' || roleString == 'clinic_admin') {
      return AdminRole.clinicAdmin;
    }

    // 3. Default Mapping
    return AdminRole.values.firstWhere(
          (e) => e.name == roleString,
      orElse: () => AdminRole.dietitian,
    );
  }

  // 🎯 SMART PERMISSIONS
  bool hasAccess(String permission) {
    // Super Admin has infinite access
    if (role == AdminRole.superAdmin) return true;

    // Clinic Admin has access to almost everything EXCEPT global tenant management
    if (role == AdminRole.clinicAdmin) {
      // Deny specific Super Admin actions explicitly if checked via permission string
      if (permission == 'manage_tenants' || permission == 'db_migration') return false;
      return true;
    }

    // Others rely on specific permission flags
    return permissions.contains(permission);
  }

  // ... (Rest of toMap, copyWith, etc. - ensure role: role.name is used in toMap) ...
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
      'role': role.name, // 🎯 Saves 'clinicAdmin' or 'superAdmin'
      'isActive': isActive,
      'dateOfJoining': dateOfJoining != null ? Timestamp.fromDate(dateOfJoining!) : null,
      'permissions': permissions,
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

  // Add copyWith...
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
}