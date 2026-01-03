import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_analytics_service.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/consultation_data_service.dart';
import 'package:nutricare_client_management/admin/feed_service.dart';
import 'package:nutricare_client_management/admin/generic_service.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_master_service.dart';
import 'package:nutricare_client_management/admin/meeting_service_old.dart';
import 'package:nutricare_client_management/admin/patient_service.dart';
import 'package:nutricare_client_management/admin/services/master_data_service.dart';
import 'package:nutricare_client_management/admin/staff_management_service.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/services/client_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/modules/client/services/client_service.dart';
import 'package:nutricare_client_management/modules/master/service/food_item_service.dart';
import 'package:nutricare_client_management/modules/master/service/master_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/master/service/master_meal_name_service.dart';
import 'package:nutricare_client_management/modules/package/service/package_Service.dart';
import 'package:nutricare_client_management/app_theme.dart';
import 'package:nutricare_client_management/modules/package/service/package_payment_service.dart';
import 'package:nutricare_client_management/scheduler/content_service.dart';

// -----------------------------------------------------------------
// 1. STATE MANAGEMENT PROVIDERS
// -----------------------------------------------------------------

class ThemeManager with ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.deepTeal;
  AppThemeType get currentTheme => _currentTheme;
  void setTheme(AppThemeType type) { _currentTheme = type; notifyListeners(); }
}

final themeManagerProvider = ChangeNotifierProvider<ThemeManager>((ref) => ThemeManager());


// -----------------------------------------------------------------
// 2. CORE SERVICE PROVIDERS (ALL PASSING 'ref')
// -----------------------------------------------------------------

// 🎯 AUTH/LOGIN SERVICE
//final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref));

// 🎯 CLIENT SERVICE
final clientServiceProvider = Provider<ClientService>((ref) => ClientService(ref));

// 🎯 VITALS SERVICE
//final vitalsServiceProvider = Provider<VitalsService>((ref) => VitalsService(ref));

// 🎯 HABIT MASTER SERVICE

// 🎯 PACKAGE SERVICE
final habitMasterServiceProvider = Provider<GenericMasterService>((ref) => GenericMasterService(ref,collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_develop_habits)));
final diagnosisMasterServiceProvider = Provider<GenericMasterService>((ref) => GenericMasterService(ref,collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_Diagnosis)));
final serviceUnitMasterServiceProvider = Provider<GenericMasterService>((ref) => GenericMasterService(ref,collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_ServingUnits)));
final dietPlanCategoryServiceProvider = Provider<GenericMasterService>((ref) => GenericMasterService(ref,collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_DietPlanCategories)));
final foodCategoryProvider = Provider<GenericMasterService>((ref) => GenericMasterService(ref,collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_FoodCategory)));
final guidelineServiceProvider = Provider<GenericMasterService>((ref) => GenericMasterService(ref,collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_Investigation)));
final investigationMasterServiceProvider = Provider<GenericMasterService>((ref) => GenericMasterService(ref,collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_Investigation)));
final diseaseMasterServiceProvider = Provider<GenericMasterService>((ref) => GenericMasterService(ref,collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_disease)));
final supplimentMasterServiceProvider = Provider<GenericMasterService>((ref) => GenericMasterService(ref,collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_supplement)));
final packageServiceProvider = Provider<PackageService>((ref) => PackageService(ref));
final foodItemServiceProvider = Provider<FoodItemService>((ref) => FoodItemService(ref));
final masterMealNameServiceProvider = Provider<MasterMealNameService>((ref) => MasterMealNameService(ref));
final masterDietPlanServiceProvider = Provider<MasterDietPlanService>((ref) => MasterDietPlanService(ref));
final clientDietPlanServiceProvider = Provider<ClientDietPlanService>((ref) => ClientDietPlanService(ref));
final packagePaymentServiceProvider = Provider<PackagePaymentService>((ref) => PackagePaymentService(ref));
final vitalsServiceProvider = Provider<VitalsService>((ref) => VitalsService(ref));
final inclusionMasterServiceProvider = Provider<GenericMasterService>((ref) => GenericMasterService(ref,collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_packageInclusion)));
final meetingServiceOldProvider = Provider<MeetingServiceOld>((ref) => MeetingServiceOld(ref));
final consultationDataServiceProvider = Provider<ConsultationDataService>((ref) => ConsultationDataService(ref));
final contentServiceProvider = Provider<ContentService>((ref) => ContentService(ref));
final adminAnalyticsServiceProvider = Provider<AdminAnalyticsService>((ref) => AdminAnalyticsService(ref));
final patientIdServiceProvider = Provider<PatientIdService>((ref) => PatientIdService(ref));
final clinicalMasterServiceProvider = Provider<ClinicalMasterService>((ref) => ClinicalMasterService(ref));
final staffManagementProvider = Provider<StaffManagementService>((ref) => StaffManagementService(ref));
final feedServiceProvider = Provider<FeedService>((ref) => FeedService(ref));
final programFeatureServiceProvider = Provider<GenericMasterService>((ref) => GenericMasterService(ref,collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_packagefeature)));
final masterDataServiceProvider = Provider<MasterDataService>((ref) => MasterDataService(ref));
final allStaffStreamProvider = StreamProvider<List<AdminProfileModel>>((ref) {
  return ref.watch(staffManagementProvider).streamAllStaff();
});

// 🎯 2.3 MASTER DATA STREAMS
final specializationsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(staffManagementProvider).streamSpecializations();
});

final qualificationsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(staffManagementProvider).streamQualifications();
});

final designationsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(staffManagementProvider).streamDesignations();
});


final clinicalComplaintsDataProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final service = ref.watch(masterDataServiceProvider);
  final mapper = MasterCollectionMapper.getPath;
  // Use the master services to fetch the list based on the entity
  return await service.fetchMasterList(mapper(MasterEntity.entity_Complaint));
});

final nutritionDiagnosisDataProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final service = ref.watch(masterDataServiceProvider);
  final mapper = MasterCollectionMapper.getPath;
  return await service.fetchMasterList(mapper(MasterEntity.entity_Diagnosis));
});
final clientDetailProvider = FutureProvider.family.autoDispose<ClientModel, String>((ref, clientId) async {
  final service = ref.watch(clientServiceProvider);
  return await service.getClientById(clientId);
});














































































































// ... Continue this pattern for all other services.