// lib/main.dart

import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider, Provider, Consumer;
import 'package:nutricare_client_management/admin/authwrapper.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/app_theme.dart';
import 'package:nutricare_client_management/firebase_options.dart';
import 'package:nutricare_client_management/on_boarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 1. ADD THIS CLASS to manage the theme state
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

  // 🎯 STEP 1: Initialize Firebase Default App FIRST to avoid concurrency issues.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully.");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  // 🎯 STEP 2: Activate App Check AFTER Firebase is ready
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
  } catch (e) {
    print("AppCheck activation failed: $e");
  }

  // 🎯 STEP 3: Load SharedPreferences after platform/Firebase setup
  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;


  runApp(
    ProviderScope(
      child:
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeManager()),
        ],
        child: MyApp(hasSeenOnboarding: hasSeenOnboarding, lastTenantId: prefs.getString('last_tenant_id')),
      ),),
  );
  FlutterNativeSplash.remove();
}

class MyApp extends ConsumerStatefulWidget {
  final bool hasSeenOnboarding;
  final String? lastTenantId;

  const MyApp({
    super.key,
    required this.hasSeenOnboarding,
    this.lastTenantId
  });

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isRestoringSession = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    if (widget.lastTenantId != null) {
      try {
        final clientService = ref.read(clientServiceProvider);
        final config = await clientService.fetchTenantConfig(widget.lastTenantId!);

        ref.read(currentTenantConfigProvider.notifier).state = config;

        // Force initialization of that specific Firebase App
        await ref.read(firebaseAppProvider.future);
        print("✅ Restored session for tenant: ${widget.lastTenantId}");
      } catch (e) {
        print("Failed to restore session: $e");
        // 🎯 CRITICAL: Sign out any conflicting user and remove the bad ID
        await FirebaseAuth.instance.signOut();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('last_tenant_id');
      }
    }

    if (mounted) {
      setState(() {
        _isRestoringSession = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          title: 'NutriCare Client Management',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(type: themeManager.currentTheme, brightness: Brightness.light),
          darkTheme: AppTheme.getTheme(type: themeManager.currentTheme, brightness: Brightness.dark),
          themeMode: ThemeMode.system,

          home: _isRestoringSession
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : (widget.hasSeenOnboarding ? const AuthWrapper() : const OnboardingScreen()),
        );
      },
    );
  }
}