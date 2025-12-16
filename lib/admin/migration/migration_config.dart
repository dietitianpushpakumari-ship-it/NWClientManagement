// lib/features/migration/data/migration_config.dart

class CollectionDefinition {
  final String label;   // Display Name
  final String path;    // Firestore Path
  final bool isDefault; // Should it be checked by default?

  const CollectionDefinition({
    required this.label,
    required this.path,
    this.isDefault = true,
  });
}

// 🛠️ EDIT THIS LIST TO ADD/REMOVE COLLECTIONS
const List<CollectionDefinition> kMigrationCollections = [
  CollectionDefinition(
    label: 'servingUnits',
    path: 'servingUnits',
  ),
  CollectionDefinition(
    label: 'masterMealNames',
    path: 'masterMealNames', // Note: Deep path to items
  ),
  CollectionDefinition(
    label: 'foodCategories',
    path: 'foodCategories',
  ),
  CollectionDefinition(
    label: 'foodItems',
    path: 'foodItems',
  ),
  CollectionDefinition(
    label: 'guidelines',
    path: 'guidelines',
  ),
  CollectionDefinition(
    label: 'diagnoses',
    path: 'diagnoses',
  ),
  CollectionDefinition(
    label: 'investigations',
    path: 'investigations',
  ),
  CollectionDefinition(
    label: 'suppliments',
    path: 'suppliments',
  ),
  CollectionDefinition(
    label: 'disease_master',
    path: 'disease_master',
  ),
  CollectionDefinition(
    label: 'habit_master',
    path: 'habit_master',
  ),
  CollectionDefinition(
    label: 'programFeatures',
    path: 'programFeatures',
  ),
  CollectionDefinition(
    label: 'packages',
    path: 'packages',
  ),

  CollectionDefinition(
    label: 'master_allergies',
    path: 'master_allergies',
  ),
  CollectionDefinition(
    label: 'master_clinical_notes',
    path: 'master_clinical_notes',
  ),
  CollectionDefinition(
    label: 'master_complaints',
    path: 'master_complaints',
  ),
  CollectionDefinition(
    label: 'master_instructions',
    path: 'master_instructions',
  ),

 /* CollectionDefinition(
    label: 'master_LabVitals',
    path: 'master_LabVitals',
  ),*/
];