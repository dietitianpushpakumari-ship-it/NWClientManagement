// lib/models/client_media_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum MediaType { photo, video, document }

class ClientMediaModel {
  final String id;
  final String clientId;
  final DateTime uploadDate;
  final String fileName;
  final String fileUrl; // URL from Firebase Storage
  final MediaType type;
  final String? description;

  ClientMediaModel({
    required this.id,
    required this.clientId,
    required this.uploadDate,
    required this.fileName,
    required this.fileUrl,
    required this.type,
    this.description,
  });

  factory ClientMediaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClientMediaModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      uploadDate: (data['uploadDate'] as Timestamp).toDate(),
      fileName: data['fileName'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      type: MediaType.values.firstWhere(
              (e) => e.toString() == 'MediaType.${data['type']}',
          orElse: () => MediaType.photo),
      description: data['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'uploadDate': FieldValue.serverTimestamp(),
      'fileName': fileName,
      'fileUrl': fileUrl,
      'type': type.toString().split('.').last, // Store as string
      'description': description,
    };
  }
}