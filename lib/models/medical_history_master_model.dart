class MedicalHistoryMasterModel {
  final String id;
  final String name; // e.g., 'Diabetes Mellitus', 'PCOS', 'Hypertension'
  final DateTime createdAt;

  const MedicalHistoryMasterModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory MedicalHistoryMasterModel.fromMap(String id, Map<String, dynamic> map) {
    return MedicalHistoryMasterModel(
      id: id,
      name: map['name'] as String? ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': createdAt, // Use Firestore Timestamp when integrating with a DB
    };
  }
}