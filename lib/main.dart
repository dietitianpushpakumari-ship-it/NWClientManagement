import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider, Provider, Consumer;
import 'package:nutricare_client_management/admin/authwrapper.dart';
import 'package:nutricare_client_management/app_theme.dart';
import 'package:nutricare_client_management/firebase_options.dart';
import 'package:nutricare_client_management/on_boarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// 1. Theme Manager (Kept as is)
class ThemeManager with ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.deepTeal;

  AppThemeType get currentTheme => _currentTheme;

  void setTheme(AppThemeType type) {
    _currentTheme = type;
    notifyListeners();
  }
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 🎯 STEP 1: Initialize Firebase Default App
  // We ONLY initialize the default app now. No dynamic switching.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully.");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  // 🎯 STEP 2: Activate App Check
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
      appleProvider: kReleaseMode ? AppleProvider.deviceCheck : AppleProvider.debug,
    );
  } catch (e) {
    print("AppCheck activation failed: $e");
  }

  // 🎯 STEP 3: Load SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeManager()),
        ],
        child: MyApp(hasSeenOnboarding: hasSeenOnboarding),
      ),
    ),
  );
  FlutterNativeSplash.remove();
}

class MyApp extends ConsumerWidget {
  final bool hasSeenOnboarding;

  const MyApp({
    super.key,
    required this.hasSeenOnboarding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎯 Use the ThemeManager from Provider (not Riverpod)
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          title: 'NutriCare Client Management',
          debugShowCheckedModeBanner: false,

          // Theme Config
          theme: AppTheme.getTheme(type: themeManager.currentTheme, brightness: Brightness.light),
          darkTheme: AppTheme.getTheme(type: themeManager.currentTheme, brightness: Brightness.dark),
          themeMode: ThemeMode.system,

          // 🎯 NAVIGATION LOGIC
          // If the user has seen onboarding, go to AuthWrapper.
          // AuthWrapper checks if they are logged in.
          // If logged in, AuthWrapper restores their session (Tenant ID).
          home: hasSeenOnboarding ? const AuthWrapper() : const OnboardingScreen(),
        );
      },
    );
  }
}