import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/core/adapters/nutricare_appointment_adapter.dart';
import 'package:nutricare_client_management/modules/appointment/services/meeting_service.dart';

// =============================================================================
// 1. CORE FIREBASE PROVIDERS (Pooled Architecture)
// =============================================================================

// Just returns the default Firestore instance (Pooled DB)
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Just returns the default Auth instance
final authProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Stream of Auth Changes (Standard)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// =============================================================================
// 2. SERVICE PROVIDERS (Injected with Core Providers)
// =============================================================================

// 🎯 Meeting Service
final meetingServiceProvider = Provider<MeetingService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final currentUser = ref.watch(authProvider).currentUser;

  // Create the Contract Implementation
  final contract = NutricareAppointmentAdapter(
      db: firestore,
      currentUserId: currentUser?.uid ?? 'unknown'
  );

  return MeetingService(contract, firestore);
});

// 🎯 Appointment Adapter
final appointmentAdapterProvider = Provider<NutricareAppointmentAdapter>((ref) {
  final db = ref.watch(firestoreProvider);
  final authState = ref.watch(authStateProvider);

  final user = authState.value;

  // Graceful fallback if not logged in (prevents crashes during logout)
  if (user == null) {
    return NutricareAppointmentAdapter(db: db, currentUserId: 'guest');
  }

  return NutricareAppointmentAdapter(
    db: db,
    currentUserId: user.uid,
  );
});