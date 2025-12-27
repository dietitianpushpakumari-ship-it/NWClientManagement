// lib/admin/labvital/lab_category_migrator.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Note: Assuming you have nanoid package for ID generation
import 'package:nanoid/nanoid.dart';
import 'package:nutricare_client_management/admin/lab_test_config_entry_page.dart';
import 'package:nutricare_client_management/helper/lab_vitals_data.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/admin/services/master_data_service.dart';

class LabCategoryMigrator {
  static const String entity = MasterEntity.entity_labTestCategory;

  // 1. Core Logic: Maps hardcoded list to the required Firestore batch format
  static Map<String, Map<String, dynamic>> _mapHardcodedCategories() {
    final Map<String, Map<String, dynamic>> itemsToUpload = {};

    // Iterate over the categories list from the helper file
    for (var categoryName in LabVitalsData.labCategories1) {
      // Use nanoid for a reliable unique document ID
      final id = nanoid(10);

      itemsToUpload[id] = {
        'id': id,
        'name': categoryName,
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
    }
    return itemsToUpload;
  }

  // 2. Migration Runner: Performs the bulk upload
  static Future<int> runBulkMigration(WidgetRef ref) async {
    final itemsToUpload = _mapHardcodedCategories();
    final service = ref.read(masterDataServiceProvider);

    // Get the target collection path: 'config_labTestCategory'
    final collectionPath = MasterCollectionMapper.getPath(entity);

    // Call the services method to upload all configured categories
    await service.bulkUploadItems(collectionPath, itemsToUpload);

    // Invalidate the category provider to force UI refresh across the app
    ref.invalidate(labTestCategoriesProvider);

    return itemsToUpload.length;
  }
}