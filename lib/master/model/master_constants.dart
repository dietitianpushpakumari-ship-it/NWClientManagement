// --- 1. Entity Name Constants (Used for UI, Dialogs, Errors) ---
abstract class MasterEntity {
  static const String entity_allergy = 'entity_allergy'; //
  static const String entity_disease = 'entity_disease'; //
  static const String entity_supplement = 'entity_supplement'; //
  static const String entity_giSymptom = 'entity_giSymptom'; //
  static const String entity_develop_habits = 'entity_developHabit';
  static const String entity_waterIntake = 'entity_waterIntake';
  static const String entity_caffeineSource = 'entity_caffeineSource';
  static const String entity_Complaint = 'entity_Complaint'; //
  static const String entity_Diagnosis = 'entity_Diagnosis'; //
  static const String entity_Clinicalnotes = 'entity_Clinicalnotes'; //
  static const String entity_Investigation = 'entity_Investigation'; //

  // Food/Diet Planning Masters (typically complex)
  static const String entity_FoodItem = 'entity_FoodItem'; //
  static const String entity_FoodCategory = 'entity_FoodCategory'; //
  static const String entity_MealNames = 'entity_MealNames'; //
  static const String entity_ServingUnits = 'entity_ServingUnits'; //
  static const String entity_Guidelines = 'entity_Guidelines'; //
  static const String entity_DietPlanCategories = 'entity_DietPlanCategories'; //


  // Simple Dropdown Masters
  static const String entity_LifestyleHabit = 'entity_lifestyleHabit';
  static const String entity_ActivityLevels = 'entity_ActivityLevels';
  static const String entity_SleepQuality = 'entity_SleepQuality';
  static const String entity_MenstrualStatus = 'entity_MenstrualStatus';

  static const String entity_foodHabitsOptions = 'entity_foodHabitsOptions';
  static const String entity_packagefeature = 'entity_packageFeature';
  static const String entity_packageInclusion = 'entity_packageInclusion';
  static const String entity_packageCategory = 'entity_packageCategory';
  static const String entity_packageTargetCondition = 'entity_packageTargetCondition';
  static const String entity_packages = 'entity_packages';
  static const String entity_mealTemplates = 'entity_mealTemplates';

  static const String entity_labTestCategory = 'entity_labTestCategory';
  static const String entity_labTestConfig = 'entity_labTestConfigs';

  static const String entity_userDesignation = 'designations';
  static const String entity_userQualification = 'qualifications';
  static const String entity_userSpecialization = 'specializations';

}

abstract class TransactionEntity {
  static const String entity_patientVitals = 'entity_patientVitals'; // For package entries themselves
  static const String entity_patientMealPlan = 'entity_patientMealPlan';
  static const String entity_patientSubscription = 'entity_patientSubscription';
  static const String entity_patientPayment = 'entity_patientPayment';
}

// --- 2. Collection Path Constants (Used in MasterDataService) ---
abstract class FirestoreCollection {
  static const String collection_allergy = 'master_allergies';
  static const String collection_master_disease = 'master_disease';
  static const String collection_master_suppliment = 'master_supplement';
  static const String collection_master_giSymptom = 'master_gi';
  static const String collection_master_lifestyle_habits = 'master_lifestyle_habits';
  static const String collection_master_develop_habits = 'master_develop_habits';
  static const String collection_master_intake = 'master_intake'; // Shared for Water/Caffeine

// 🎯 NEW CLINICAL ASSESSMENT COLLECTIONS
  static const String collection_complaint = 'master_complaints';
  static const String collection_diagnosis = 'master_diagnoses';
  static const String collection_clinicalnote = 'master_clinical_notes';
  static const String collection_Investigation = 'master_Investigation';


// Food/Diet Planning Masters (typically complex)
  static const String collection_FoodItem = 'master_FoodItem';
  static const String collection_FoodCategory = 'master_FoodCategory';
  static const String collection_MealNames= 'master_MealNames';
  static const String collection_ServingUnits = 'master_ServingUnits';
  static const String collection_Guidelines = 'master_Guidelines';
  static const String collection_DietPlanCategories = 'master_DietPlanCategories';

  // Simple Dropdown Masters
  static const String collection_ActivityLevels = 'master_ActivityLevels';
  static const String collection_SleepQuality = 'master_SleepQuality';
  static const String collection_MenstrualStatus  = 'master_MenstrualStatus';
  static const String collection_foodHabitsOptions  = 'master_foodHabitsOptions';
  static const String collection_caffeineSource  = 'master_caffeineSource';

  static const String collection_packagefeature = 'master_packageFeature';
  static const String collection_packageInclusion = 'master_packageInclusion';
  static const String collection_packageCategory = 'master_packageCategory';
  static const String collection_packageTargetCondition = 'master_packageTargetCondition';
  static const String collection_packages = 'master_packages';
  static const String collection_mealTemplates = 'master_mealTemplates';
  static const String collection_labTestCategory = 'config_labTestCategory';
  static const String collection_labTestConfig = 'config_labTestConfigs';

  static const String collection_patientVitals = 'patient_vitals';
  static const String collection_patientMealPlan = 'patient_mealPlan';
  static const String collection_patientSubscription = 'patient_subscription';
  static const String collection_patientPayment = 'patient_payment';


  static const String collection_masterUserDesignation = 'configurations/staff_master';
  static const String collection_masterUserQualification = 'configurations/staff_master';
  static const String collection_masterUserSpecialization = 'configurations/staff_master';
}


// --- 3. Collection Mapper ---
// Maps the Entity Name constant to the Collection Path constant.
class MasterCollectionMapper {

  // 🎯 Central Map: Maps the Entity Constant to the Collection Path Constant
  static const Map<String, String> collectionMap = {
    MasterEntity.entity_allergy: FirestoreCollection.collection_allergy,
    MasterEntity.entity_disease: FirestoreCollection.collection_master_disease,
    MasterEntity.entity_supplement: FirestoreCollection.collection_master_suppliment,
    MasterEntity.entity_giSymptom: FirestoreCollection.collection_master_giSymptom,
    MasterEntity.entity_LifestyleHabit: FirestoreCollection.collection_master_lifestyle_habits,
    MasterEntity.entity_develop_habits: FirestoreCollection.collection_master_develop_habits,
    // Note: Water Intake and Caffeine Source point to the same collection path
    MasterEntity.entity_waterIntake: FirestoreCollection.collection_master_intake,
    MasterEntity.entity_caffeineSource: FirestoreCollection.collection_caffeineSource,

    MasterEntity.entity_Complaint: FirestoreCollection.collection_complaint,
    MasterEntity.entity_Diagnosis: FirestoreCollection.collection_diagnosis,
    MasterEntity.entity_Clinicalnotes: FirestoreCollection.collection_clinicalnote,
    MasterEntity.entity_Investigation: FirestoreCollection.collection_Investigation,

// Food/Diet Planning Masters (typically complex)
    MasterEntity.entity_FoodItem: FirestoreCollection.collection_FoodItem,
    MasterEntity.entity_FoodCategory: FirestoreCollection.collection_FoodCategory,
    MasterEntity.entity_MealNames: FirestoreCollection.collection_MealNames,
    MasterEntity.entity_ServingUnits: FirestoreCollection.collection_ServingUnits,
    MasterEntity.entity_Guidelines: FirestoreCollection.collection_Guidelines,
    MasterEntity.entity_DietPlanCategories: FirestoreCollection.collection_DietPlanCategories,
    MasterEntity.entity_mealTemplates: FirestoreCollection.collection_mealTemplates,



    // Simple Dropdown Masters
    MasterEntity.entity_ActivityLevels: FirestoreCollection.collection_ActivityLevels,
    MasterEntity.entity_SleepQuality: FirestoreCollection.collection_SleepQuality,
    MasterEntity.entity_MenstrualStatus: FirestoreCollection.collection_MenstrualStatus,
    MasterEntity.entity_foodHabitsOptions: FirestoreCollection.collection_foodHabitsOptions,

    MasterEntity.entity_packagefeature : FirestoreCollection.collection_packagefeature,
    MasterEntity.entity_packages :FirestoreCollection.collection_packages,
    MasterEntity.entity_packageInclusion: FirestoreCollection.collection_packageInclusion,
    MasterEntity.entity_packageTargetCondition : FirestoreCollection.collection_packageTargetCondition,
    MasterEntity.entity_packageCategory : FirestoreCollection.collection_packageCategory,
    MasterEntity.entity_labTestCategory: FirestoreCollection.collection_labTestCategory,
    MasterEntity.entity_labTestConfig : FirestoreCollection.collection_labTestConfig,
    TransactionEntity.entity_patientVitals: FirestoreCollection.collection_patientVitals,
    TransactionEntity.entity_patientMealPlan: FirestoreCollection.collection_patientMealPlan,
    TransactionEntity.entity_patientSubscription:FirestoreCollection.collection_patientSubscription,
    TransactionEntity.entity_patientPayment:FirestoreCollection.collection_patientPayment,

    MasterEntity.entity_userDesignation : FirestoreCollection.collection_masterUserDesignation,
    MasterEntity.entity_userQualification : FirestoreCollection.collection_masterUserQualification,
    MasterEntity.entity_userSpecialization : FirestoreCollection.collection_masterUserSpecialization,




  };

  /// Returns the corresponding Firestore collection path for a given entity name.
  static String getPath(String entityName) {
    final path = collectionMap[entityName];
    if (path == null) {
      throw ArgumentError(
          'Master list entity "$entityName" not found in MasterCollectionMapper.'
      );
    }
    return path;
  }
}