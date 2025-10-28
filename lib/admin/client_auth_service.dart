import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// 🎯 The domain prefix used to transform the mobile number into a valid email
const String _clientDomainSuffix = '@client.nutricare.com';

class ClientAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Helper to convert a mobile number into the Firebase Email format.
  String _mobileToEmail(String mobileNumber) {
    // Standardize input by removing spaces and ensuring trim
    String cleanedMobile = mobileNumber.replaceAll(RegExp(r'\s+'), '').trim();
    // Use lowercase for standard email format
    return '${cleanedMobile}$_clientDomainSuffix'.toLowerCase();
  }

  /// Creates a new Firebase Auth user with the mobile number as the login ID.
  Future<UserCredential> createOrUpdateClientAuth({
    required String mobileNumber,
    required String password,
    required String name,
  }) async {
    final email = _mobileToEmail(mobileNumber);

    try {
      // 1. Attempt to create the user directly.
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. If successful, set display name and return.
      await userCredential.user?.updateDisplayName(name);
      debugPrint('Successfully created new client Auth user: $email');
      return userCredential;

    } on FirebaseAuthException catch (e) {
      String errorMessage;

      // 3. Catch the specific error code indicating the user already exists.
      if (e.code == 'email-already-in-use') {
        // This is the functional equivalent of the check we were trying to perform.
        errorMessage = "Mobile number **$mobileNumber** is already registered with an existing account. Please use a unique mobile number.";
      } else if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak (min 6 characters).';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The mobile number is invalid.';
      } else {
        errorMessage = 'Firebase Error (${e.code}): ${e.message}';
      }

      debugPrint('Error in createOrUpdateClientAuth: ${e.code}');
      throw Exception(errorMessage);

    } catch (e) {
      debugPrint('General Error in createOrUpdateClientAuth: $e');
      rethrow;
    }
  }

  /// Tests the provided mobile number and password against Firebase Auth.
  Future<bool> testClientCredentials({
    required String mobileNumber,
    required String password,
  }) async {
    final email = _mobileToEmail(mobileNumber);
    UserCredential? userCredential;

    // We use the main instance here.
    final testAuth = FirebaseAuth.instance;

    try {
      // Attempt to sign in with the new client credentials
      userCredential = await testAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If sign-in succeeds, it means the credentials work.
      return true;

    } on FirebaseAuthException catch (e) {
      // Handle common auth errors specifically
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return false; // Credentials do not match an existing user
      }
      debugPrint('Test Credentials Error: ${e.code} - ${e.message}');
      rethrow; // Re-throw unexpected errors

    } catch (e) {
      debugPrint('General Test Credentials Error: $e');
      rethrow;

    } finally {
      // Log out the tested client user to protect the Admin's session.
      if (userCredential?.user != null) {
        await testAuth.signOut();
      }
    }
  }
}