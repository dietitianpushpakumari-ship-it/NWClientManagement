import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nutricare_client_management/admin/admin_dashboard_Screen.dart';
import 'package:nutricare_client_management/admin/authwrapper.dart';
import 'package:nutricare_client_management/admin/user_management_service.dart';
import 'package:nutricare_client_management/app_theme.dart';
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



void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  final prefs = await SharedPreferences.getInstance();
  // If the key is null, it means it's the first launch, so we show onboarding
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully.");


   // await FirebaseAppCheck.instance.activate(
     // androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
     // appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    //);
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  // 1. DEFINE YOUR DEBUG TOKEN HERE

  await FirebaseAppCheck.instance.activate(
    // Set androidProvider to `AndroidProvider.debug`
    androidProvider: AndroidProvider.debug,
  );

  //final token = await FirebaseAppCheck.instance.getToken(false);
  //print('DEBUG TOKEN: $token');
 /* if (kDebugMode) {
    try {
      final token = await FirebaseAppCheck.instance.getToken(true);
      if (token != null) {
        // This will print the token to the standard Flutter console, which may be more reliable
        debugPrint('🎯 APP CHECK DEBUG TOKEN (Manual Check): $token');
      } else {
        debugPrint('🎯 APP CHECK DEBUG: Token is null after activation.');
      }
    } catch (e) {
      debugPrint('🎯 APP CHECK DEBUG ERROR: Failed to get token: $e');
    }
  }*/
  // 🎯 CORRECT APP CHECK INITIALIZATION FOR ANDROID
  //await UserManagementService().initializeSuperAdmin();

  // --- Your App Initialization Logic Goes Here ---
  // (e.g., Firebase, SharedPreferences, API calls, theme loading)
  await Future.delayed(const Duration(seconds: 1)); // Example delay

  // 3. Remove the splash screen

  runApp(
    MultiProvider(
      providers: [
        // Make ClientService available throughout the app
        Provider<ClientService>(create: (_) => ClientService()),
        // Make PackagePaymentService available throughout the app
        Provider<VitalsService>(create: (_) => VitalsService()),
        Provider<PackagePaymentService>(create: (_) => PackagePaymentService()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<PackageService>(create: (_) => PackageService()),
        Provider<ServingUnitService>(create: (_) => ServingUnitService()),
        Provider<FoodCategoryService>(create: (_) => FoodCategoryService()),
        Provider<DietPlanCategoryService>(
          create: (_) => DietPlanCategoryService(),
        ),
        Provider<FoodItemService>(create: (_) => FoodItemService()),
        Provider<GuidelineService>(create: (_) => GuidelineService()),
        Provider<MasterMealNameService>(create: (_) => MasterMealNameService()),
        Provider<MasterDietPlanService>(create: (_) => MasterDietPlanService()),
        Provider<DietPlanService>(create: (_) => DietPlanService()),
        Provider<ClientDietPlanService>(create: (_) => ClientDietPlanService()),
        Provider<DiagnosisMasterService>(
          create: (_) => DiagnosisMasterService(),
        ),
        // Add other necessary providers (e.g., AuthProvider, UserProvider) here
      ],
      child: MyApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {


    Widget initialScreen;
    if (hasSeenOnboarding) {
      // If user has seen it, go to AuthWrapper to check if they are logged in
      initialScreen = const AuthWrapper();
    } else {
      // If user hasn't seen it, show the Onboarding screen
      initialScreen = const OnboardingScreen();
    }


    return MaterialApp(
      title: 'NutriCare Client Management',
      debugShowCheckedModeBanner: false,

      // APPLY THE WELLNESS MATERIAL 3 THEMES
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Conditional logic for the initial route (The transition from Splash)
    //  home: hasSeenOnboarding ? const LoginScreen() : const OnboardingScreen(),
      home: const OnboardingScreen(),
    );
  }
}
