// lib/admin/company_profile_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyProfileModel {
  // Clinic/Hospital Identity
  final String? name;
  final String? logoUrl;
  final String? patientIdPrefix; // e.g., "NC"
  final String? gstin;

  // Contact/Location
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? contactPhone;
  final String? contactEmail;

  // Banking/Payment Details
  final String? bankName;
  final String? bankAccNo;
  final String? bankIfsc;

  final Timestamp? updatedAt;

  CompanyProfileModel({
    this.name,
    this.logoUrl,
    this.patientIdPrefix,
    this.gstin,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.contactPhone,
    this.contactEmail,
    this.bankName,
    this.bankAccNo,
    this.bankIfsc,
    this.updatedAt,
  });

  factory CompanyProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return CompanyProfileModel(
      name: data['name'] as String?,
      logoUrl: data['logoUrl'] as String?,
      patientIdPrefix: data['patientIdPrefix'] as String?,
      gstin: data['gstin'] as String?,
      address: data['address'] as String?,
      city: data['city'] as String?,
      state: data['state'] as String?,
      pincode: data['pincode'] as String?,
      contactPhone: data['contactPhone'] as String?,
      contactEmail: data['contactEmail'] as String?,
      bankName: data['bankName'] as String?,
      bankAccNo: data['bankAccNo'] as String?,
      bankIfsc: data['bankIfsc'] as String?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  // Creates an empty/default model for initialization
  factory CompanyProfileModel.empty() {
    return CompanyProfileModel();
  }
}