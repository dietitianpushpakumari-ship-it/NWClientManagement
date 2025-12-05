import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider, Provider, Consumer;
import 'package:nutricare_client_management/admin/admin_dashboard_Screen.dart';
import 'package:nutricare_client_management/admin/authwrapper.dart';
import 'package:nutricare_client_management/admin/user_management_service.dart';
import 'package:nutricare_client_management/app_theme.dart'; // 🎯 Ensure this imports your new AppTheme
import 'package:nutricare_client_management/firebase_options.dart';
import 'package:nutricare_client_management/login_screen.dart';
import 'package:nutricare_client_management/modules/client/services/client_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/master/service/diagonosis_master_service.dart';
import 'package:nutricare_client_management/modules/master/service/master_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/master/service/diet_plan_category_service.dart';
import 'package:nutricare_client_management/meal_planner/service/diet_plan_service.dart';
import 'package:nutricare_client_management/modules/master/service/food_category_service.dart';
import 'package:nutricare_client_management/modules/master/service/food_item_service.dart';
import 'package:nutricare_client_management/modules/master/service/guideline_service.dart';
import 'package:nutricare_client_management/modules/master/service/master_meal_name_service.dart';
import 'package:nutricare_client_management/modules/master/service/serving_unit_service.dart';
import 'package:nutricare_client_management/on_boarding_screen.dart';
import 'package:nutricare_client_management/screens/admin_home_Screen.dart';
import 'package:nutricare_client_management/helper/auth_service.dart';
import 'package:nutricare_client_management/modules/client/services/client_service.dart';
import 'package:nutricare_client_management/modules/package/service/package_Service.dart';
import 'package:nutricare_client_management/modules/package/service/package_payment_service.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// 🎯 1. ADD THIS CLASS to manage the theme state
class ThemeManager with ChangeNotifier {
  // Default theme
  AppThemeType _currentTheme = AppThemeType.deepTeal;

  AppThemeType get currentTheme => _currentTheme;

  void setTheme(AppThemeType type) {
    _currentTheme = type;
    notifyListeners(); // Triggers the app to rebuild with new colors
  }
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully.");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  await Future.delayed(const Duration(seconds: 1));

  runApp(
      ProviderScope(
        child:
    MultiProvider(
      providers: [
        // 🎯 2. ADD ThemeManager PROVIDER HERE
        ChangeNotifierProvider(create: (_) => ThemeManager()),

        Provider<ClientService>(create: (_) => ClientService()),
        Provider<VitalsService>(create: (_) => VitalsService()),
        Provider<PackagePaymentService>(create: (_) => PackagePaymentService()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<PackageService>(create: (_) => PackageService()),
        Provider<ServingUnitService>(create: (_) => ServingUnitService()),
        Provider<FoodCategoryService>(create: (_) => FoodCategoryService()),
        Provider<DietPlanCategoryService>(create: (_) => DietPlanCategoryService()),
        Provider<FoodItemService>(create: (_) => FoodItemService()),
        Provider<GuidelineService>(create: (_) => GuidelineService()),
        Provider<MasterMealNameService>(create: (_) => MasterMealNameService()),
        Provider<MasterDietPlanService>(create: (_) => MasterDietPlanService()),
        Provider<DietPlanService>(create: (_) => DietPlanService()),
        Provider<ClientDietPlanService>(create: (_) => ClientDietPlanService()),
        Provider<DiagnosisMasterService>(create: (_) => DiagnosisMasterService()),
      ],
      child: MyApp(hasSeenOnboarding: hasSeenOnboarding),
    ),),
  );
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    // 🎯 3. WRAP MaterialApp with CONSUMER to listen for theme changes
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          title: 'NutriCare Client Management',
          debugShowCheckedModeBanner: false,

          // 🎯 4. USE DYNAMIC THEME
          // This now uses the 'currentTheme' from your ThemeManager
          theme: AppTheme.getTheme(
              type: themeManager.currentTheme,
              brightness: Brightness.light
          ),
          darkTheme: AppTheme.getTheme(
              type: themeManager.currentTheme,
              brightness: Brightness.dark
          ),
          themeMode: ThemeMode.system,

          home: hasSeenOnboarding ? const AuthWrapper() : const OnboardingScreen(),
        );
      },
    );
  }
}