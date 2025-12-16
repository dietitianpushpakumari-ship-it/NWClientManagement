// lib/features/migration/services/db_migration_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DbMigrationService {

  static final DbMigrationService _instance = DbMigrationService._internal();
  factory DbMigrationService() => _instance;
  DbMigrationService._internal();

  FirebaseFirestore? _sourceDb;
  FirebaseFirestore? _destDb;

  // 1. Initialize Source (Current App)
  void initSource() {
    _sourceDb = FirebaseFirestore.instance;
  }

  // 2. Initialize Target (Dynamic from Dropdown)
  Future<void> connectToTarget(Map<String, dynamic> config) async {
    // Check if we have the required keys
    if (config['project_id'] == null || config['api_key'] == null) {
      throw Exception("Missing Firebase Keys in Tenant Document");
    }

    final String appName = 'target_${config['project_id']}';

    try {
      // Check if already initialized to avoid "DuplicateApp" error
      FirebaseApp destApp;
      if (Firebase.apps.any((app) => app.name == appName)) {
        destApp = Firebase.app(appName);
      } else {
        destApp = await Firebase.initializeApp(
          name: appName,
          options: FirebaseOptions(
            apiKey: config['api_key'],
            appId: config['app_id'],
            messagingSenderId: config['messaging_sender_id'] ?? '123456',
            projectId: config['project_id'],
          ),
        );
      }

      _destDb = FirebaseFirestore.instanceFor(app: destApp);
      print("✅ Successfully connected to ${config['project_id']}");

    } catch (e) {
      print("❌ Connection Failed: $e");
      rethrow;
    }
  }

  // 3. The Copy Logic (Unchanged)
  Future<void> copyCollection({
    required String path,
    required Function(double percent) onProgress,
  }) async {
    if (_sourceDb == null) initSource();
    if (_destDb == null) throw Exception("Target DB not connected! Call connectToTarget() first.");

    final snapshot = await _sourceDb!.collection(path).get();
    final totalDocs = snapshot.docs.length;

    if (totalDocs == 0) {
      onProgress(1.0);
      return;
    }

    WriteBatch batch = _destDb!.batch();
    int batchCount = 0;
    int processedCount = 0;

    for (var doc in snapshot.docs) {
      final docRef = _destDb!.collection(path).doc(doc.id);
      batch.set(docRef, doc.data());

      batchCount++;
      processedCount++;

      if (batchCount >= 400) {
        await batch.commit();
        batch = _destDb!.batch();
        batchCount = 0;
        onProgress(processedCount / totalDocs);
      }
    }

    if (batchCount > 0) await batch.commit();
    onProgress(1.0);
  }
}