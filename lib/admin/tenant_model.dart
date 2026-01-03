import 'package:cloud_firestore/cloud_firestore.dart';

class TenantModel {
  final String id;
  final String name;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final String status; // 'active', 'suspended', 'pending'
  final String? logoUrl;
  final String? address;
  final String? website;
  final DateTime? createdAt;
  final DateTime? invitedAt; // 🎯 This was missing

  TenantModel({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    this.status = 'active',
    this.logoUrl,
    this.address,
    this.website,
    this.createdAt,
    this.invitedAt,
  });

  factory TenantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Helper: Safely convert Firestore Timestamp to DateTime
    DateTime? toDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      return null;
    }

    return TenantModel(
      id: doc.id,
      name: data['name'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      ownerPhone: data['ownerPhone'] ?? '',
      status: data['status'] ?? 'active',
      logoUrl: data['logoUrl'],
      address: data['address'],
      website: data['website'],
      createdAt: toDateTime(data['createdAt']),
      invitedAt: toDateTime(data['invitedAt']), // 🎯 Map it here
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'ownerPhone': ownerPhone,
      'status': status,
      'logoUrl': logoUrl,
      'address': address,
      'website': website,
// 🔴 THIS WAS LIKELY MISSING OR COMMENTED OUT
      'createdAt': createdAt,

      'invitedAt': invitedAt,
    };
  }
}