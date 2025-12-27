import 'package:cloud_firestore/cloud_firestore.dart';

class PackageAssignmentModel {
  final String id;
  final String packageId;
  final String packageName;
  final String? description;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final bool isActive;
  final bool isLocked;
  final String clientId;

  final String? diagnosis;
  final double discount;
  final double bookedAmount;
  final String? category;
  final String? type;

  // 🎯 UI & Logic Fields
  final String? colorCode;
  final int followUpIntervalDays;
  final bool isTaxInclusive;
  final double? originalPrice;

  final String? sessionId;
  final int sessionsTotal;
  final int sessionsRemaining;
  final int offerExtraDays;
  final int offerExtraSessions;
  final int freeSessionsTotal;
  final int freeSessionsRemaining;

  // 🎯 Content Lists
  final List<String> inclusions;
  final List<String> inclusionIds;
  final List<String> programFeatureIds;
  final List<String> targetConditions;

  PackageAssignmentModel({
    required this.id,
    required this.packageId,
    required this.packageName,
    this.description,
    required this.purchaseDate,
    required this.expiryDate,
    required this.isActive,
    required this.clientId,
    this.diagnosis,
    this.discount = 0.0,
    required this.bookedAmount,
    this.category,
    this.type,
    required this.isLocked,
    this.colorCode,
    this.followUpIntervalDays = 7,
    this.isTaxInclusive = true,
    this.originalPrice,
    this.sessionId,
    this.sessionsTotal = 0,
    this.sessionsRemaining = 0,
    this.offerExtraDays = 0,
    this.offerExtraSessions = 0,
    this.freeSessionsTotal = 0,
    this.freeSessionsRemaining = 0,
    this.inclusions = const [],
    this.inclusionIds = const [],
    this.programFeatureIds = const [],
    this.targetConditions = const [],
  });

  // 🎯 RESTORED: fromMap Factory (Required for ClientModel)
  factory PackageAssignmentModel.fromMap(Map<String, dynamic> data) {
    DateTime parseDate(dynamic timestamp) {
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
      return DateTime.now();
    }

    final startDate = parseDate(data['startDate'] ?? data['purchaseDate']);
    final endDate = parseDate(data['endDate'] ?? data['expiryDate']);

    final String status = (data['status'] ?? '').toString().toLowerCase();
    final bool isActive = (status == 'active' || data['isActive'] == true) && endDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));

    return PackageAssignmentModel(
      id: data['id'] as String? ?? '', // Embedded objects might not have ID
      packageId: data['packageId'] as String? ?? '',
      packageName: data['packageName'] as String? ?? 'Unknown',
      description: data['description'] as String?,

      purchaseDate: startDate,
      expiryDate: endDate,
      isActive: isActive,

      clientId: data['clientId'] as String? ?? '',
      diagnosis: data['diagnosis'] as String?,
      type: data['type'] as String?,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,

      bookedAmount: (data['bookedAmount'] as num?)?.toDouble() ?? (data['price'] as num?)?.toDouble() ?? 0.0,

      category: data['category'] as String?,
      colorCode: data['colorCode'] as String?,
      followUpIntervalDays: (data['followUpIntervalDays'] as num?)?.toInt() ?? 7,
      isTaxInclusive: data['isTaxInclusive'] as bool? ?? true,
      originalPrice: (data['originalPrice'] as num?)?.toDouble(),

      isLocked: data['isLocked'] as bool? ?? false,
      sessionId: data['sessionId'] as String?,
      sessionsTotal: (data['sessionsTotal'] as num?)?.toInt() ?? 0,
      sessionsRemaining: (data['sessionsRemaining'] as num?)?.toInt() ?? 0,
      offerExtraDays: (data['offerExtraDays'] as num?)?.toInt() ?? 0,
      offerExtraSessions: (data['offerExtraSessions'] as num?)?.toInt() ?? 0,
      freeSessionsTotal: (data['freeSessionsTotal'] as num?)?.toInt() ?? 0,
      freeSessionsRemaining: (data['freeSessionsRemaining'] as num?)?.toInt() ?? 0,

      inclusions: List<String>.from(data['inclusions'] ?? []),
      inclusionIds: List<String>.from(data['inclusionIds'] ?? []),
      programFeatureIds: List<String>.from(data['programFeatureIds'] ?? []),
      targetConditions: List<String>.from(data['targetConditions'] ?? []),
    );
  }

  // 🎯 fromFirestore Factory
  factory PackageAssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw StateError('Cannot create PackageAssignmentModel from null data.');
    }

    // Reuse fromMap logic, but inject the document ID
    final model = PackageAssignmentModel.fromMap(data);

    // Return a copy with the correct Document ID
    return PackageAssignmentModel(
      id: doc.id,
      packageId: model.packageId,
      packageName: model.packageName,
      description: model.description,
      purchaseDate: model.purchaseDate,
      expiryDate: model.expiryDate,
      isActive: model.isActive,
      clientId: model.clientId,
      diagnosis: model.diagnosis,
      discount: model.discount,
      bookedAmount: model.bookedAmount,
      category: model.category,
      colorCode: model.colorCode,
      followUpIntervalDays: model.followUpIntervalDays,
      isTaxInclusive: model.isTaxInclusive,
      originalPrice: model.originalPrice,
      type: model.type,
      isLocked: model.isLocked,
      sessionId: model.sessionId,
      sessionsTotal: model.sessionsTotal,
      sessionsRemaining: model.sessionsRemaining,
      offerExtraDays: model.offerExtraDays,
      offerExtraSessions: model.offerExtraSessions,
      freeSessionsTotal: model.freeSessionsTotal,
      freeSessionsRemaining: model.freeSessionsRemaining,
      inclusions: model.inclusions,
      inclusionIds: model.inclusionIds,
      programFeatureIds: model.programFeatureIds,
      targetConditions: model.targetConditions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageId': packageId,
      'packageName': packageName,
      'description': description,
      'startDate': Timestamp.fromDate(purchaseDate),
      'endDate': Timestamp.fromDate(expiryDate),
      'status': isActive ? 'active' : 'expired',
      'clientId': clientId,
      'diagnosis': diagnosis,
      'discount': discount,
      'price': bookedAmount,
      'type': type,
      'category': category,
      'colorCode': colorCode,
      'followUpIntervalDays': followUpIntervalDays,
      'isTaxInclusive': isTaxInclusive,
      'originalPrice': originalPrice,
      'isLocked': isLocked,
      'sessionId': sessionId,
      'sessionsTotal': sessionsTotal,
      'sessionsRemaining': sessionsRemaining,
      'offerExtraDays': offerExtraDays,
      'offerExtraSessions': offerExtraSessions,
      'freeSessionsTotal': freeSessionsTotal,
      'freeSessionsRemaining': freeSessionsRemaining,
      'inclusions': inclusions,
      'inclusionIds': inclusionIds,
      'programFeatureIds': programFeatureIds,
      'targetConditions': targetConditions,
    };
  }
}