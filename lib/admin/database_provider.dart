import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/tenant_model.dart';
import 'package:nutricare_client_management/core/adapters/nutricare_appointment_adapter.dart';
import 'package:nutricare_client_management/modules/appointment/services/meeting_service.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
// import 'package:nutricare_client_management/firebase_options.dart'; // Default options if needed

// 1. STATE: Store the Full Config, not just ID
final currentTenantConfigProvider = StateProvider<TenantModel?>((ref) => null);

// 2. FACTORY: Initialize App based on Config
final firebaseAppProvider = FutureProvider<FirebaseApp>((ref) async {
  final config = ref.watch(currentTenantConfigProvider);

  // If no config, use Default (Live/Super Admin)
  if (config == null) return Firebase.app();

  // Dynamic Tenants (Guest or Clinics)
  try {
    // Check if already initialized in memory
    return Firebase.app(config.id);
  } catch (e) {
    // Initialize using the keys from the Database Model
    return await Firebase.initializeApp(
      name: config.id,
      options: FirebaseOptions(
        apiKey: config.apiKey,
        appId: config.appId,
        messagingSenderId: config.messagingSenderId,
        projectId: config.projectId,
        storageBucket: config.storageBucket,
      ),
    );
  }
});

// 3. PROVIDERS (Safe Fallbacks)
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  final config = ref.watch(currentTenantConfigProvider);
  if (config != null) {
    try { return FirebaseFirestore.instanceFor(app: Firebase.app(config.id)); } catch(_) {}
  }
  return FirebaseFirestore.instance; // Default
});

final authProvider = Provider<FirebaseAuth>((ref) {
  final config = ref.watch(currentTenantConfigProvider);
  if (config != null) {
    try { return FirebaseAuth.instanceFor(app: Firebase.app(config.id)); } catch(_) {}
  }
  return FirebaseAuth.instance; // Default
});

final authStateProvider = StreamProvider<User?>((ref) {
  // 1. Watch the dynamic, tenant-aware Auth instance
  final auth = ref.watch(authProvider);

  // 2. Listen to changes on the CORRECT instance
  return auth.authStateChanges();
});

// 🎯 NEW PROVIDER DEFINITION
final meetingServiceProvider = Provider<MeetingService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final currentUser = ref.watch(authProvider).currentUser;

  // Create the Contract Implementation
  final contract = NutricareAppointmentAdapter(
      db: firestore,
      currentUserId: currentUser?.uid ?? 'unknown'
  );

  // Return the Service
  return MeetingService(contract, firestore);
});
final appointmentAdapterProvider = Provider<NutricareAppointmentAdapter>((ref) {
  final db = ref.watch(firestoreProvider);

  // Watch the Auth State. If it changes, this Adapter is re-created.
  final authState = ref.watch(authStateProvider);

  // Handle "Not Logged In" case gracefully
  final user = authState.value;
  if (user == null) {
    throw Exception("Cannot create AppointmentAdapter: No User Logged In");
  }
    return NutricareAppointmentAdapter(
      db: db,
      currentUserId: user.uid, // 🎯 Injecting the ID from AuthWrapper/State
    );
  });