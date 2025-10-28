import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// NOTE: This class requires proper implementation for file handling
// (e.g., image_picker) and Firebase Storage interaction.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  /// Updates the user's profile picture URL (e.g., after successful Storage upload).
  Future<void> updateProfileImage(String newImageUrl) async {
    if (currentUser == null) throw Exception("User not authenticated.");
    try {
      // In a real app:
      // 1. Use image_picker/file_picker to get a file.
      // 2. Upload the file to Firebase Storage.
      // 3. Get the download URL (newImageUrl).
      await currentUser!.updatePhotoURL(newImageUrl);
      notifyListeners(); // Notify UI components (like the Drawer) to rebuild
    } catch (e) {
      throw Exception("Failed to update profile image: $e");
    }
  }

  /// Updates the user's display name.
  Future<void> updateProfileName(String newName) async {
    if (currentUser == null) throw Exception("User not authenticated.");
    try {
      await currentUser!.updateDisplayName(newName);
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to update profile name: $e");
    }
  }

  /// Sends a password reset email to the user's registered email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception("Failed to send reset email: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}