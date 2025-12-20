import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_analytics_service.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/consultation_data_service.dart';
import 'package:nutricare_client_management/admin/feed_service.dart';
// --- Import all Service Classes (Ensure these are correct) ---
import 'package:nutricare_client_management/admin/habit_master_service.dart';
import 'package:nutricare_client_management/admin/inclusion_master_service.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_master_service.dart';
import 'package:nutricare_client_management/admin/meeting_service.dart';
import 'package:nutricare_client_management/admin/patient_service.dart';
import 'package:nutricare_client_management/admin/services/master_data_service.dart';
import 'package:nutricare_client_management/admin/staff_management_service.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/master/service/disease_master_service.dart';
import 'package:nutricare_client_management/meal_planner/service/Dependancy_service.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/screen/Suppliment_master_service.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_service.dart';
import 'package:nutricare_client_management/modules/client/services/client_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/modules/client/services/client_service.dart';
import 'package:nutricare_client_management/helper/auth_service.dart';
import 'package:nutricare_client_management/modules/master/service/diagonosis_master_service.dart';
import 'package:nutricare_client_management/modules/master/service/diet_plan_category_service.dart';
import 'package:nutricare_client_management/modules/master/service/food_item_service.dart';
import 'package:nutricare_client_management/modules/master/service/guideline_service.dart';
import 'package:nutricare_client_management/modules/master/service/master_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/master/service/master_meal_name_service.dart';
import 'package:nutricare_client_management/modules/package/service/package_Service.dart';
import 'package:nutricare_client_management/modules/master/service/serving_unit_service.dart';
import 'package:nutricare_client_management/modules/master/service/food_category_service.dart';
import 'package:nutricare_client_management/app_theme.dart';
import 'package:nutricare_client_management/modules/package/service/package_payment_service.dart';
import 'package:nutricare_client_management/modules/package/service/program_feature_service.dart';
import 'package:nutricare_client_management/scheduler/content_scheduler_service.dart';
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
final habitMasterServiceProvider = Provider<HabitMasterService>((ref) => HabitMasterService(ref));

// 🎯 PACKAGE SERVICE
final packageServiceProvider = Provider<PackageService>((ref) => PackageService(ref));

// 🎯 SERVING UNIT SERVICE
final servingUnitServiceProvider = Provider<ServingUnitService>((ref) => ServingUnitService(ref));

// 🎯 FOOD CATEGORY SERVICE
final foodCategoryServiceProvider = Provider<FoodCategoryService>((ref) => FoodCategoryService(ref));

final diagnosisMasterServiceProvider = Provider<DiagnosisMasterService>((ref) => DiagnosisMasterService(ref));


final dietPlanCategoryServiceProvider = Provider<DietPlanCategoryService>((ref) => DietPlanCategoryService(ref));

final foodItemServiceProvider = Provider<FoodItemService>((ref) => FoodItemService(ref));
final guidelineServiceProvider = Provider<GuidelineService>((ref) => GuidelineService(ref));
final masterMealNameServiceProvider = Provider<MasterMealNameService>((ref) => MasterMealNameService(ref));
final masterDietPlanServiceProvider = Provider<MasterDietPlanService>((ref) => MasterDietPlanService(ref));
final clientDietPlanServiceProvider = Provider<ClientDietPlanService>((ref) => ClientDietPlanService(ref));
final packagePaymentServiceProvider = Provider<PackagePaymentService>((ref) => PackagePaymentService(ref));
final supplimentMasterServiceProvider = Provider<SupplimentMasterService>((ref) => SupplimentMasterService(ref));
final investigationMasterServiceProvider = Provider<InvestigationMasterService>((ref) => InvestigationMasterService(ref));
final vitalsServiceProvider = Provider<VitalsService>((ref) => VitalsService(ref));
final inclusionMasterServiceProvider = Provider<InclusionMasterService>((ref) => InclusionMasterService(ref));
final meetingServiceProvider = Provider<MeetingService>((ref) => MeetingService(ref));
final consultationDataServiceProvider = Provider<ConsultationDataService>((ref) => ConsultationDataService(ref));
final diseaseMasterServiceProvider = Provider<DiseaseMasterService>((ref) => DiseaseMasterService(ref));
final dependencyServiceProvider = Provider<DependencyService>((ref) => DependencyService(ref));
final contentServiceProvider = Provider<ContentService>((ref) => ContentService(ref));
final contentSchedulerServiceProvider = Provider<ContentSchedulerService>((ref) => ContentSchedulerService(ref));
final adminAnalyticsServiceProvider = Provider<AdminAnalyticsService>((ref) => AdminAnalyticsService(ref));
final patientIdServiceProvider = Provider<PatientIdService>((ref) => PatientIdService(ref));
final clinicalMasterServiceProvider = Provider<ClinicalMasterService>((ref) => ClinicalMasterService(ref));
final staffManagementProvider = Provider<StaffManagementService>((ref) => StaffManagementService(ref));
final feedServiceProvider = Provider<FeedService>((ref) => FeedService(ref));
final programFeatureServiceProvider = Provider<ProgramFeatureService>((ref) => ProgramFeatureService(ref));
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
  // Use the master service to fetch the list based on the entity
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