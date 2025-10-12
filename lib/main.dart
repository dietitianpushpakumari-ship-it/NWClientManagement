import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nutricare_client_management/firebase_options.dart';
import 'package:nutricare_client_management/meal_planner/service/diet_plan_category_service.dart';
import 'package:nutricare_client_management/meal_planner/service/diet_plan_service.dart';
import 'package:nutricare_client_management/meal_planner/service/food_category_service.dart';
import 'package:nutricare_client_management/meal_planner/service/food_item_service.dart';
import 'package:nutricare_client_management/meal_planner/service/guideline_service.dart';
import 'package:nutricare_client_management/meal_planner/service/master_diet_plan_service.dart';
import 'package:nutricare_client_management/meal_planner/service/master_meal_name_service.dart';
import 'package:nutricare_client_management/meal_planner/service/serving_unit_service.dart';
import 'package:nutricare_client_management/screens/admin_home_Screen.dart';
import 'package:nutricare_client_management/services/auth_service.dart';
import 'package:nutricare_client_management/services/client_service.dart';
import 'package:nutricare_client_management/services/package_Service.dart';
import 'package:nutricare_client_management/services/package_payment_service.dart';
import 'package:nutricare_client_management/services/vitals_service.dart';
import 'package:provider/provider.dart';
// import 'firebase_options.dart'; // <<< GENERATE THIS FILE WITH FLUTTERFIRE CLI!
import 'screens/master_client_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully.");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }


      runApp(
          MultiProvider(
            providers: [
              // Make ClientService available throughout the app
              Provider<ClientService>(
                create: (_) => ClientService(),
              ),
              // Make PackagePaymentService available throughout the app
              Provider<VitalsService>(
                create: (_) => VitalsService(),
              ),
              Provider<PackagePaymentService>(
                create: (_) => PackagePaymentService(),
              ),
              Provider<AuthService>(
                create: (_) => AuthService(),
              ),
              Provider<PackageService>(
                create: (_) => PackageService(),
              ),
              Provider<ServingUnitService>(
                create: (_) => ServingUnitService(),
              ),
              Provider<FoodCategoryService>(
                create: (_) => FoodCategoryService(),
              ),
              Provider<DietPlanCategoryService>(
                create: (_) => DietPlanCategoryService(),
              ),
              Provider<FoodItemService>(
                create: (_) => FoodItemService(),
              ),
              Provider<GuidelineService>(
                create: (_) => GuidelineService(),
              ),
              Provider<MasterMealNameService>(
                 create: (_) => MasterMealNameService()),
              Provider<MasterDietPlanService>(
                  create: (_) => MasterDietPlanService()),
              Provider<DietPlanService>(
                  create: (_) => DietPlanService()),
              // Add other necessary providers (e.g., AuthProvider, UserProvider) here
            ],
            child: const MyApp(),
          ),
      );

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        useMaterial3: true,
      ),
      home: const AdminHomeScreen(),
    );
  }
}