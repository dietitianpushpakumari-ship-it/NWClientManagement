import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/tenant_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/package/model/package_assignment_model.dart'; // Required for Firebase.app()

final Logger _logger = Logger();

class ClientService {
  final Ref _ref; // Store Ref to access dynamic providers

  ClientService(this._ref);

  // 🎯 DYNAMIC GETTERS (Switch based on Tenant)
  // These will now automatically point to 'Guest', 'Live', or 'Clinic A' DB
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  FirebaseAuth get _auth => _ref.read(authProvider);

  // Storage usually follows the app instance too
  FirebaseStorage get _storage => FirebaseStorage.instanceFor(
      app: _firestore.app
  );
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  CollectionReference get _clientCollection => _firestore.collection('clients');

  // =================================================================
  // 🎯 NEW METHODS FOR MULTI-TENANT LOGIN
  // =================================================================

  /// Fetches the configuration for a specific tenant (e.g., 'guest')
  Future<TenantModel> fetchTenantConfig(String tenantId) async {
    // Always check the MASTER DB (Default App) for tenant configs
    final masterDb = FirebaseFirestore.instanceFor(app: Firebase.app());

    try {
      final doc = await masterDb.collection('tenants').doc(tenantId).get();

      if (!doc.exists) {
        // Fallback for initial setup if 'guest' doc doesn't exist yet
        if (tenantId == 'guest') {
          throw Exception("Guest configuration not found in Master DB.");
        }
        throw Exception("Tenant '$tenantId' not found.");
      }

      return TenantModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      throw Exception("Failed to load tenant settings: $e");
    }
  }

  /// Looks up which tenant a mobile number belongs to
  Future<String> getUserTenant(String mobile) async {
    final email = "$mobile@nutricarewellness.in";
    // Always check the LIVE DB's directory
    final liveDb = FirebaseFirestore.instanceFor(app: Firebase.app());

    try {
      final doc = await liveDb.collection('user_directory').doc(email).get();
      if (doc.exists) {
        return doc.data()?['tenant_id'] ?? 'live';
      }
    } catch (e) {
      _logger.e("Directory lookup failed: $e");
    }
    return 'live'; // Default
  }

  // =================================================================
  // ♻️ EXISTING LOGIC (Refactored to use dynamic _firestore & _auth)
  // =================================================================

  Future<void> addClient(ClientModel client, String password, PlatformFile? photo, PlatformFile? agreement) async {
    _logger.i('Attempting to add new client: ${client.name}');

    // 1. Upload Files
    String? photoUrl = await _uploadFile(photo, 'clients/${client.id}/photo');
    String? agreementUrl = await _uploadFile(agreement, 'clients/${client.id}/agreement');

    final newDocRef = _clientCollection.doc(); // Uses dynamic collection
    final clientId = newDocRef.id;

    final data = client.toMap();
    data['photoUrl'] = photoUrl;
    data['agreementUrl'] = agreementUrl;
    data['status'] = 'Inactive';
    data['hasPasswordSet'] = false;
    data['createdAt'] = FieldValue.serverTimestamp();

    await newDocRef.set(data);
    _logger.i('Client added successfully with ID: $clientId');

    // Note: If using Cloud Functions for password, ensure the function
    // supports the tenant ID or use client-side auth creation for now.
    // await _callAdminSetPasswordFunction(client.id, password);
  }

  // ... (Keep your other methods like updateClient, softDeleteClient)
  // Just ensure you replace `FirebaseFirestore.instance` with `_firestore`
  // and `FirebaseAuth.instance` with `_auth`.

  Future<Map<String, dynamic>> softDeleteClient({required String clientId, bool isCheckOnly = false}) async {
    final clientDoc = await _clientCollection.doc(clientId).get();
    if (!clientDoc.exists) {
      return {'canDelete': false, 'message': 'Client not found.'};
    }

    final clientData = clientDoc.data() as Map<String, dynamic>;
    final rawAssignments = clientData['packageAssignments'] as Map<String, dynamic>?;

    // Check for any active package assignments
    if (rawAssignments != null && rawAssignments.isNotEmpty) {
      final hasActiveAssignments = rawAssignments.values.any((assignmentMap) => assignmentMap['isActive'] == true);

      if (hasActiveAssignments) {
        final message = 'Client $clientId has active package assignments and cannot be soft deleted until packages expire or are marked inactive.';
        _logger.w(message);
        // Deletion is NOT allowed
        return {'canDelete': false, 'message': message};
      }
    }

    if (isCheckOnly) {
      // Check passed, soft delete is allowed.
      return {'canDelete': true, 'message': 'Client $clientId can be soft deleted.'};
    }

    // If isCheckOnly is false, proceed with soft deletion since the check passed.
    _logger.i('Soft deleting client: $clientId');
    try {
      await _clientCollection.doc(clientId).update({
        'isSoftDeleted': true,
        'status': 'Inactive',
        'updatedAt': FieldValue.serverTimestamp(),
        'hasPasswordSet': false,
      });
      _logger.i('Client $clientId soft deleted successfully.');
      return {'canDelete': true, 'message': 'Client soft deleted successfully. The client status is now Inactive.'};
    } catch (e) {
      _logger.e('Error soft deleting client $clientId: ${e.toString()}');
      return {'canDelete': false, 'message': 'Failed to soft delete client due to a service error.'};
    }
  }


  Future<String?> _uploadFile(PlatformFile? file, String path) async {
    if (file == null || file.bytes == null) return null;
    try {
      final extension = file.extension ?? 'bin';
      final storageRef = _storage.ref().child('$path.$extension'); // Dynamic storage
      final uploadTask = storageRef.putData(file.bytes!, SettableMetadata(contentType: _getMimeType(extension)));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  String _getMimeType(String? extension) {
    final ext = extension?.toLowerCase();
    if (ext == 'jpg' || ext == 'jpeg') return 'image/jpeg';
    if (ext == 'png') return 'image/png';
    return 'application/octet-stream';
  }

  Future<String> changeLoginIdToSystem(String clientId, String currentMobile) async {
    _logger.i('Attempting to change login ID for client: $clientId');
    try {
      final doc = await _clientCollection.doc(clientId).get();
      final currentLoginId = (doc.data() as Map<String, dynamic>?)?['loginId'];

      if (currentLoginId != currentMobile) {
        _logger.w('Login ID change attempted but ID was not mobile. Current ID: $currentLoginId');
        throw Exception("Login ID has already been customized and cannot be changed again.");
      }

      final newSystemId = generateSystemId();

      await _clientCollection.doc(clientId).update({
        'loginId': newSystemId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.i('Login ID successfully changed to system ID: $newSystemId');
      return newSystemId;

    } catch (e, stack) {
      _logger.e('Error changing login ID: ${e.toString()}', error: e, stackTrace: stack);
      rethrow;
    }
  }
  String generateSystemId() {
    // Ensure the maximum value for random generation is at least 1
    final int maxRandom = 10 > 0 ? 10 : 1000;

    final Random random = Random();

    // Calculate a random number using the adjusted max
    int randomNumber = random.nextInt(maxRandom);

    // You might also want to combine a timestamp or a unique prefix
    return 'CID-${DateTime.now().millisecondsSinceEpoch % 1000}${randomNumber.toString().padLeft(4, '0')}';
  }

  // --- Authentication/Credential Methods (with Robust Logging) ---

  Future<void> setPasswordAndActivate(String clientId, String password) async {
    final authEmail = '$clientId@nutricarewellness.in';
    _logger.i('Starting secure password activation via Cloud Function for $clientId');

    // 1. Prepare data for the Cloud Function call
    final instance = FirebaseFunctions.instanceFor(region: 'asia-south1');
    final callable = instance.httpsCallable('createClientCredentials');

    try {
      // 2. Call the secure Cloud Function to create the Auth user
      _logger.d('Calling Cloud Function to create Auth user: $authEmail');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'clientId': clientId,
        'clientEmail': authEmail,
        'initialPassword': password,
      });

      _logger.i('Auth user successfully created: ${result.data['uid']}');

      // 3. Update Firestore flags to 'Active' and 'hasPasswordSet'
      await _clientCollection.doc(clientId).update({
        'hasPasswordSet': true, // Now TRUE since the password was set by the Admin SDK
        'status': 'Active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _logger.i('Client flags set to Active/hasPasswordSet=true.');

    } on FirebaseFunctionsException catch (e) {
      _logger.e("Cloud Function Error during credential creation: ${e.message}");
      // Re-throw specific errors (e.g., if the user already exists)
      throw Exception("Failed to create credentials: ${e.message}");

    } on FirebaseAuthException catch (e) {
      // Catch any potential client-side auth errors (less likely now)
      _logger.e("Firebase Auth Error: ${e.message}");
      throw Exception("Auth Error: ${e.message}");

    } catch (e) {
      _logger.e("General Error in password activation: $e");
      rethrow;
    }
  }
  Future<void> destroyCredentialsAndDeactivate(String clientId) async {
    _logger.i('Deactivating client and destroying credential flags: $clientId');
    try {
      // In a real app, trigger Admin SDK to delete/disable the Auth user here.

      await _clientCollection.doc(clientId).update({
        'hasPasswordSet': false,
        'status': 'Inactive',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.i('Client flags set to Inactive/hasPasswordSet=false.');
    } catch (e, stack) {
      _logger.e('Error deactivating client: ${e.toString()}', error: e, stackTrace: stack);
      rethrow;
    }


  }



  //Mock method to test login credentials
  Future<bool> testClientLogin(String id, String password) async {
    debugPrint('Testing login for ID: $id...');
    await Future.delayed(const Duration(seconds: 1));
    // Mock logic: success if ID is NOT 00000 AND password is '123456'
    return id != '00000' && password == '123456';
  }

  // 🎯 Mock Firebase call
  Future<void> updateClientPassword(String clientId, String newPassword) async {
    debugPrint('Resetting password for Client ID: $clientId');
    await Future.delayed(const Duration(milliseconds: 500));
  }


  Future<void> updateClientStatus(String clientId, String newStatus) async {
    _logger.i('Attempting to change status for $clientId to $newStatus');
    try {
      if (newStatus == 'Inactive') {
        await destroyCredentialsAndDeactivate(clientId);
      } else if (newStatus == 'Active') {
        final doc = await _clientCollection.doc(clientId).get();
        final hasPassword = (doc.data() as Map<String, dynamic>?)?['hasPasswordSet'] ?? false;

        if (!hasPassword) {
          _logger.w('Cannot set status to Active: Credential has not been created.');
          throw Exception('Cannot set status to Active: Credential has not been created.');
        }

        await _clientCollection.doc(clientId).update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _logger.i('Status successfully set to Active.');
      }
    } catch (e, stack) {
      _logger.e('Error updating client status: ${e.toString()}', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> testLoginCredentials(String loginId, String password, ClientModel liveClient) async {
    _logger.i('Starting real credential test for login ID: $loginId');
    final authEmail = '$loginId@yoursystem.com';

    if (liveClient.status != 'Active' || !liveClient.hasPasswordSet) {
      _logger.w('Test failed: Firestore status check failed. Status: ${liveClient.status}, HasPassword: ${liveClient.hasPasswordSet}');
      throw Exception('System status is Inactive or Credentials not set. Check LIVE Status.');
    }

    try {
      _logger.d('Attempting Firebase Auth sign-in with email: $authEmail');
      await _auth.signInWithEmailAndPassword(email: authEmail, password: password);
      _logger.i('Authentication successful! Credentials verified.');

      await _auth.signOut();
      _logger.d('Client session immediately signed out.');

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-email') {
        _logger.w("Authentication failed: Invalid ID or Password. Code: ${e.code}");
        throw Exception("Authentication Failed: Invalid ID or Password.");
      }
      _logger.e("Firebase Error during test login: ${e.message}", error: e);
      throw Exception("Firebase Error: ${e.message}");
    } catch (e, stack) {
      _logger.e("General Login Test Error: ${e.toString()}", error: e, stackTrace: stack);
      throw Exception("Login Test Error: ${e.toString()}");
    }
  }


  // --- ADMIN ROLE MANAGEMENT ---

  /// Calls the Cloud Function to set the 'isAdmin' custom claim for a user.
  /// The user calling this function must already have the 'isAdmin' claim.
  Future<void> setAdminRole({
    required String targetUid,
    required bool isAdmin,
  }) async {
    _logger.i('Attempting to set admin role for UID: $targetUid to isAdmin: $isAdmin');
    // 1. Specify the region (MUST match your deployment in index.js)
    final instance = FirebaseFunctions.instanceFor(region: 'asia-south1');

    try {
      final callable = instance.httpsCallable('setAdminClaim');

      // 2. Call the function with the target user's UID and the boolean flag
      await callable.call(<String, dynamic>{
        'targetUid': targetUid,
        'isAdmin': isAdmin,
      });

      // 3. CRITICAL: Force the token to refresh so the calling user's
      //    (the super-admin) claims are immediately updated.
      await FirebaseAuth.instance.currentUser?.getIdTokenResult(true);

      _logger.i('Role successfully updated for $targetUid. isAdmin: $isAdmin');

    } on FirebaseFunctionsException catch (e) {
      // Log error from the function (e.g., 'permission-denied')
      _logger.e('Cloud Function Error in setAdminRole: ${e.code} - ${e.message}');

      // Re-throw a user-friendly exception for the UI to handle
      if (e.code == 'permission-denied') {
        throw Exception('Access Denied: You do not have sufficient privileges to perform this action.');
      } else if (e.code == 'invalid-argument') {
        throw Exception('Invalid user ID or role parameter provided.');
      }
      throw Exception('Failed to update role: ${e.message}');
    } catch (e) {
      _logger.e('General error during setAdminRole.', error: e);
      rethrow;
    }
  }

  /// Checks the current user's token for the 'isAdmin' custom claim.
  Future<bool> checkAdminStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    try {
      // Get the ID token result (which contains the custom claims)
      // Pass 'true' to force a fresh token fetch to get the absolute latest claims.
      IdTokenResult result = await user.getIdTokenResult(true);

      // Safely check for the 'isAdmin' claim
      final isAdmin = result.claims?['isAdmin'] == true;
      _logger.d('Admin status check for ${user.uid}: $isAdmin');
      return isAdmin;
    } catch (e) {
      _logger.e('Error checking admin status.', error: e);
      return false;
    }
  }

  /// Assigns a package to a client and updates the client's record.
  /// NOTE: This method is now OBSOLETE for saving, as we are using a separate subcollection,
  /// but it's kept here for compatibility with existing code that may rely on the 'activePackages' map.
  /*Future<void> assignPackageToClient({
    required String clientId,
    required PackageAssignmentModel assignment,
  }) async {
    // _logger.i('Assigning package ${assignment.packageId} to client $clientId');
    try {
      // Use the packageId as the key in the nested map
      final packageKey = 'activePackages.${assignment.id}';

      await _clientCollection.doc(clientId).update({
        packageKey: assignment.toMap(), // This saves the updated map with diagnosis, discount, and bookedAmount
        'lastPackageUpdate': FieldValue.serverTimestamp(),
      });
      // _logger.i('Package assigned successfully.');
    } catch (e, stack) {
      // _logger.e('Error assigning package: ${e.toString()}', error: e, stackTrace: stack);
      throw Exception('Failed to assign package to client.');
    }
  }*/

  Future<void> assignPackageToClient(String clientId, PackageAssignmentModel newAssignment) async {
    try {
      // 🎯 THE FIX: Use .add() to ensure a new unique document ID is created.
      // This allows the same package to be assigned multiple times (renewal/extension).
      await clientAssignmentCollection(clientId).add(newAssignment.toMap());
    } catch (e) {
      _logger.e('Failed to assign package: $e');
      throw Exception('Failed to assign package to client: ${e.toString()}');
    }
  }
  Future<List<ClientModel>> getAllClients() async {
    _logger.i('Fetching all client records.');
    try {
      final snapshot = await _clientCollection.orderBy('createdAt', descending: true).get();

      return snapshot.docs.map((doc) => ClientModel.fromFirestore(doc)).toList();
    } catch (e, stack) {
      _logger.e('Error fetching all clients: ${e.toString()}', error: e, stackTrace: stack);
      throw Exception('Failed to load clients.');
    }


  }

  /// Retrieves a single client record by their Firestore document ID.
  Future<ClientModel> getClientById(String clientId) async {
    _logger.i('Fetching client record for ID: $clientId');
    try {
      final doc = await _clientCollection.doc(clientId).get();

      if (!doc.exists) {
        throw Exception('Client with ID $clientId not found.');
      }

      return ClientModel.fromFirestore(doc);
    } catch (e, stack) {
      _logger.e('Error fetching client by ID: ${e.toString()}', error: e, stackTrace: stack);
      // Re-throw the original exception or a service-specific one
      rethrow;
    }
  }

  // UPDATE ASSIGNED PACKAGE
  /// Updates an existing package assignment (used for editing diagnosis, discount, etc.).
  Future<void> updateAssignedPackage( {
    required String clientId,
    required PackageAssignmentModel updatedAssignment,
  }) async {
    // Assuming _logger is defined and imported
    // _logger.i('Updating package assignment ${updatedAssignment.packageId} for client $clientId');
    try {
      // The key structure activePackages.packageId is used to target the specific nested map entry
      final packageKey = 'activePackages.${updatedAssignment.packageId}';

      await _clientCollection.doc(clientId).update({
        // Overwrites the existing map entry with the new data from the model
        packageKey: updatedAssignment.toMap(),
        'lastPackageUpdate': FieldValue.serverTimestamp(),
      });
      // _logger.i('Package assignment updated successfully.');
    } catch (e) {
      // _logger.e('Error updating package assignment: ${e.toString()}');
      throw Exception('Failed to update package assignment for client.');
    }
  }

  // DELETE ASSIGNED PACKAGE
  /// Deletes a package assignment (removes it entirely from the client's record).
  Future<void> deleteAssignedPackage({
    required String clientId,
    required String packageId,
  }) async {
    // _logger.w('Attempting to delete package $packageId from client $clientId');
    try {
      // Use FieldValue.delete() to remove the specific key from the map
      final packageKey = 'activePackages.$packageId';

      await _clientCollection.doc(clientId).update({
        packageKey: FieldValue.delete(), // Firestore command to remove the map entry
        'lastPackageUpdate': FieldValue.serverTimestamp(),
      });
      // _logger.i('Package assignment deleted successfully.');
    } catch (e) {
      // _logger.e('Error deleting package assignment: ${e.toString()}');
      throw Exception('Failed to delete package assignment for client.');
    }
  }

  /// Provides a stream of all client documents for the reporting screen.
  Stream<List<ClientModel>> streamAllClientsForReporting() {
    // This streams the entire 'clients' collection
    return _clientCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ClientModel.fromFirestore(doc)).toList());
  }


  CollectionReference clientAssignmentCollection(String clientId) {
    // 🎯 FIX: Drill down from the existing _clientCollection reference.
    // This correctly returns a CollectionReference, resolving the type mismatch error
    // that the compiler was seeing.
    return _clientCollection
        .doc(clientId)
        .collection('packageAssignments');
  }

  /// Provides a stream of all package assignments for a specific client.
  Stream<List<PackageAssignmentModel>> streamClientAssignments(String clientId) {
    // 1. Get the CollectionReference for the subcollection.
    final assignmentRef = clientAssignmentCollection(clientId);

    // 2. Apply the ORDER BY clause to the CollectionReference (Query object).
    return assignmentRef
    // 🎯 FIX: orderBy is applied BEFORE .snapshots()
        .orderBy('purchaseDate', descending: true)
        .snapshots() // Now convert the ordered query to a stream
        .map((snapshot) => snapshot.docs
        .map((doc) => PackageAssignmentModel.fromFirestore(doc))
        .toList());
  }


  Future<bool> checkAssignmentCompleted(String clientId) async {
    // 1. Get the CollectionReference for the subcollection.
    final assignmentRef = clientAssignmentCollection(clientId);


    try {
      final snapshot = await assignmentRef
          .where('clientId', isEqualTo: clientId)
          .limit(1)
          .get();

      // If the document exists, the step is complete
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking vitals completion for $clientId: $e');
      return false;
    }
  }

  Future<void> changePassword(String clientId, String newPassword) async {
    _logger.i('Attempting to change password for client: $clientId');

    // 1. Call Cloud Function to perform the admin-level password reset
    await _callAdminSetPasswordFunction(clientId, newPassword);

    // 2. Update Firestore flag (if the function succeeded)
    await _clientCollection.doc(clientId).update({
      'hasPasswordSet': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _logger.i('Successfully changed password and updated hasPasswordSet flag for $clientId.');
  }
  Future<void> _callAdminSetPasswordFunction(String clientId, String password) async {
    try {
      // NOTE: The actual Firebase Cloud Function 'adminSetClientPassword' must be deployed
      // separately to handle the secure update of the user's Firebase Auth record.
      final HttpsCallable callable = _functions.httpsCallable('adminSetClientPassword');

      final result = await callable.call<dynamic>({
        'clientId': clientId,
        'password': password,
      });

      //if (kDebugMode) {
        _logger.d('Cloud Function Response: ${result.data}');
     // }

    } on FirebaseFunctionsException catch (e) {
      _logger.e('Firebase Function Error (adminSetClientPassword): ${e.code} - ${e.message}');
      throw Exception('Failed to set password securely. Please ensure the Cloud Function is deployed and working. Error: ${e.message}');
    } catch (e) {
      _logger.e('Unknown error setting password: ${e.toString()}');
      throw Exception('Failed to set password due to an unknown error.');
    }
  }


}