import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';

// --- 1. THE MODEL ---
class SystemConfigModel {
  final String translationApiKey;
  final String translationModel;
  final bool isTranslationEnabled;

  SystemConfigModel({
    required this.translationApiKey,
    required this.translationModel,
    this.isTranslationEnabled = true,
  });

  factory SystemConfigModel.fromMap(Map<String, dynamic>? data) {
    if (data == null) return SystemConfigModel(translationApiKey: '', translationModel: 'gemini-1.5-flash');

    return SystemConfigModel(
      translationApiKey: data['translationApiKey'] ?? '',
      translationModel: data['translationModel'] ?? 'gemini-1.5-flash',
      isTranslationEnabled: data['isTranslationEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'translationApiKey': translationApiKey,
      'translationModel': translationModel,
      'isTranslationEnabled': isTranslationEnabled,
    };
  }
}

// --- 2. THE PROVIDER ---
final systemConfigProvider = StreamProvider<SystemConfigModel>((ref) {
  return ref.read(firestoreProvider)
      .collection('configurations')
      .doc('system_settings')
      .snapshots()
      .map((doc) => SystemConfigModel.fromMap(doc.data()));
});

// --- 3. THE SERVICE ---
class SystemConfigService {
  final Ref _ref;
  SystemConfigService(this._ref);

  Future<void> updateConfig(SystemConfigModel config) async {
    await _ref.read(firestoreProvider)
        .collection('configurations')
        .doc('system_settings')
        .set(config.toMap(), SetOptions(merge: true));
  }

  // Helper to get config once (non-stream)
  Future<SystemConfigModel> getConfigOnce() async {
    final doc = await _ref.read(firestoreProvider).collection('configurations').doc('system_settings').get();
    return SystemConfigModel.fromMap(doc.data());
  }
}

final systemConfigServiceProvider = Provider((ref) => SystemConfigService(ref));