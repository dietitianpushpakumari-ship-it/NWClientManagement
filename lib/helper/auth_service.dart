import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart'; // To access authProvider

// 🎯 1. GLOBAL RIVERPOD PROVIDER DEFINITION
// This registers AuthService and injects the Ref object.
final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref));

// 🎯 2. SERVICE CLASS (No longer extends ChangeNotifier)
class AuthService {
  final Ref _ref;

  // 🎯 3. Constructor accepts Ref
  AuthService(this._ref);

  // 🎯 4. Dynamic Getter for Multi-Tenancy
  // This ensures the services uses the correct FirebaseAuth instance for the active tenant.
  FirebaseAuth get _auth => _ref.read(authProvider);

  User? get currentUser => _auth.currentUser;

  /// Updates the user's profile picture URL (e.g., after successful Storage upload).
  Future<void> updateProfileImage(String newImageUrl) async {
    if (currentUser == null) throw Exception("User not authenticated.");
    try {
      // 🎯 Uses the current user from the dynamic auth instance
      await currentUser!.updatePhotoURL(newImageUrl);
      // Note: Call notifyListeners() is removed. UI should watch a StreamProvider (like userStreamProvider)
      // or manually refresh the user object after this call.
    } catch (e) {
      throw Exception("Failed to update profile image: $e");
    }
  }

  /// Updates the user's display name.
  Future<void> updateProfileName(String newName) async {
    if (currentUser == null) throw Exception("User not authenticated.");
    try {
      await currentUser!.updateDisplayName(newName);
      // notifyListeners() removed.
    } catch (e) {
      throw Exception("Failed to update profile name: $e");
    }
  }

  /// Sends a password reset email to the user's registered email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // 🎯 Uses the dynamic Auth instance
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception("Failed to send reset email: $e");
    }
  }

  Future<void> signOut() async {
    // 🎯 Uses the dynamic Auth instance
    await _auth.signOut();
  }

}