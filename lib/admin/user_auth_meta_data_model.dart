import 'package:cloud_firestore/cloud_firestore.dart';

class UserAuthMetadataModel {
  final String id; // The Firebase Auth UID (Document ID)

  // --- Profile Mapping ---
  // The collection where this user's full profile is stored ('admins' or 'clients').
  final String profileCollection;

  // --- Login Status & History ---
  final Timestamp? lastLoginDetails;
  final bool isLoginDisabled; // Your 'inactive login'

  // --- Security & Audit ---
  final int failedLoginAttempts;
  final Timestamp? lockedUntil;
  final String? disabledBy; // UID of the Admin/Super Admin who disabled the login
  final String? disabledReason;
  final Timestamp? lastPasswordChange;

  const UserAuthMetadataModel({
    required this.id,
    required this.profileCollection,
    this.lastLoginDetails,
    this.isLoginDisabled = false,
    this.failedLoginAttempts = 0,
    this.lockedUntil,
    this.disabledBy,
    this.disabledReason,
    this.lastPasswordChange,
  });

  // --- Firestore Conversion ---

  factory UserAuthMetadataModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserAuthMetadataModel(
      id: doc.id,
      profileCollection: data['profileCollection'] ?? 'clients', // Default
      lastLoginDetails: data['lastLoginDetails'] as Timestamp?,
      isLoginDisabled: data['isLoginDisabled'] ?? false,
      failedLoginAttempts: data['failedLoginAttempts'] ?? 0,
      lockedUntil: data['lockedUntil'] as Timestamp?,
      disabledBy: data['disabledBy'],
      disabledReason: data['disabledReason'],
      lastPasswordChange: data['lastPasswordChange'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profileCollection': profileCollection,
      'lastLoginDetails': lastLoginDetails,
      'isLoginDisabled': isLoginDisabled,
      'failedLoginAttempts': failedLoginAttempts,
      'lockedUntil': lockedUntil,
      'disabledBy': disabledBy,
      'disabledReason': disabledReason,
      'lastPasswordChange': lastPasswordChange,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}