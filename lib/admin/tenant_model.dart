import 'package:cloud_firestore/cloud_firestore.dart';

enum TenantStatus { pending, active, suspended }

class TenantModel {
  final String id;
  final String name;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;

  // Firebase Config
  final String apiKey;
  final String appId;        // Web App ID (Default)
  final String androidAppId; // 🎯 NEW
  final String iosAppId;     // 🎯 NEW
  final String messagingSenderId;
  final String projectId;
  final String storageBucket;

  final TenantStatus status;
  final DateTime? createdAt;
  final DateTime? invitedAt;

  TenantModel({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.apiKey,
    required this.appId,
    required this.androidAppId, // 🎯
    required this.iosAppId,     // 🎯
    required this.messagingSenderId,
    required this.projectId,
    required this.storageBucket,
    this.status = TenantStatus.active,
    this.createdAt,
    this.invitedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'ownerPhone': ownerPhone,
      'apiKey': apiKey,
      'appId': appId,
      'androidAppId': androidAppId, // 🎯 Save
      'iosAppId': iosAppId,         // 🎯 Save
      'messagingSenderId': messagingSenderId,
      'projectId': projectId,
      'storageBucket': storageBucket,
      'status': status.name,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'invitedAt': invitedAt != null ? Timestamp.fromDate(invitedAt!) : null,
    };
  }

  factory TenantModel.fromMap(String id, Map<String, dynamic> map) {
    return TenantModel(
      id: id,
      name: map['name'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerEmail: map['ownerEmail'] ?? '',
      ownerPhone: map['ownerPhone'] ?? '',
      apiKey: map['apiKey'] ?? '',
      appId: map['appId'] ?? '',
      androidAppId: map['androidAppId'] ?? '', // 🎯 Load
      iosAppId: map['iosAppId'] ?? '',         // 🎯 Load
      messagingSenderId: map['messagingSenderId'] ?? '',
      projectId: map['projectId'] ?? '',
      storageBucket: map['storageBucket'] ?? '',
      status: TenantStatus.values.firstWhere((e) => e.name == (map['status'] ?? 'active'), orElse: () => TenantStatus.active),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      invitedAt: (map['invitedAt'] as Timestamp?)?.toDate(),
    );
  }
}