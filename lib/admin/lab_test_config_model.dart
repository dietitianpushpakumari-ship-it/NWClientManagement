import 'package:cloud_firestore/cloud_firestore.dart';

class LabTestConfigModel {
  final String id; // Test Key (e.g., 'hemoglobin')
  final String displayName;
  final String unit;
  final String category; // e.g., 'Hematology', 'Diabetic Profile'
  final double? minRange;
  final double? maxRange;
  final bool isReverseLogic; // e.g., true for HDL (higher is better)

  const LabTestConfigModel({
    this.id = '',
    required this.displayName,
    required this.unit,
    required this.category,
    this.minRange,
    this.maxRange,
    this.isReverseLogic = false,
  });

  factory LabTestConfigModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return const LabTestConfigModel(displayName: '', unit: '', category: '');

    return LabTestConfigModel(
      id: doc.id,
      displayName: data['displayName'] as String? ?? '',
      unit: data['unit'] as String? ?? '',
      category: data['category'] as String? ?? '',
      minRange: (data['minRange'] as num?)?.toDouble(),
      maxRange: (data['maxRange'] as num?)?.toDouble(),
      isReverseLogic: data['isReverseLogic'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'unit': unit,
      'category': category,
      'minRange': minRange,
      'maxRange': maxRange,
      'isReverseLogic': isReverseLogic,
    };
  }

  LabTestConfigModel copyWith({
    String? id,
    String? displayName,
    String? unit,
    String? category,
    double? minRange,
    double? maxRange,
    bool? isReverseLogic,
  }) {
    return LabTestConfigModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      minRange: minRange ?? this.minRange,
      maxRange: maxRange ?? this.maxRange,
      isReverseLogic: isReverseLogic ?? this.isReverseLogic,
    );
  }
}