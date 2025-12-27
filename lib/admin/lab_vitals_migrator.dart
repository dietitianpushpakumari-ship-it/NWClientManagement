// lib/admin/labvital/lab_vitals_migrator.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/lab_test_config_model.dart';
import 'package:nutricare_client_management/admin/lab_test_config_service.dart';
import 'package:nutricare_client_management/helper/lab_vitals_data.dart';

class LabVitalsMigrator {

  // 1. Core Logic: Maps hardcoded data to Firestore model
  static Map<String, LabTestConfigModel> _mapHardcodedData() {
    return LabVitalsData.allLabTests1.map((key, config) {
      return MapEntry(
        key,
        LabTestConfigModel(
          id: key, // Use the map key (e.g., 'hemoglobin') as the document ID
          displayName: config.displayName,
          unit: config.unit,
          category: config.category,
          minRange: config.minRange,
          maxRange: config.maxRange,
          isReverseLogic: config.isReverseLogic,
        ),
      );
    });
  }

  // 2. Migration Runner: Performs the bulk upload
  static Future<int> runBulkMigration(WidgetRef ref) async {
    final testsToUpload = _mapHardcodedData();
    final service = ref.read(labTestConfigServiceProvider);

    // Call the services method to upload all configured tests
    await service.bulkUploadTests(testsToUpload);

    // Invalidate the provider that streams the tests to force UI refresh
    ref.invalidate(allLabTestsStreamProvider);

    return testsToUpload.length;
  }
}