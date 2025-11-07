// lib/models/content_scheduler_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/scheduler/disease_tag.dart';

class ContentSchedulerModel {
  final String id;
  final String clientId;
  final DiseaseTag diseaseTag; // Filter for content
  final ContentFrequency frequency;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime lastSentDate; // For backend tracking

  ContentSchedulerModel({
    required this.id,
    required this.clientId,
    required this.diseaseTag,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.lastSentDate,
  });

  factory ContentSchedulerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContentSchedulerModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      diseaseTag: DiseaseTag.fromName(data['diseaseTag'] ?? 'general'),
      frequency: ContentFrequency.fromName(data['frequency'] ?? 'weekly'),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      lastSentDate: (data['lastSentDate'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'diseaseTag': diseaseTag.name,
      'frequency': frequency.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'lastSentDate': Timestamp.fromDate(lastSentDate),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}