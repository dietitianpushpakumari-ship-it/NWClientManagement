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
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/tenant_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/package/model/package_assignment_model.dart';

final Logger _logger = Logger();

class ClientService {
  final Ref _ref;

  ClientService(this._ref);

  // 🎯 POOLED DB ACCESS (Simplified)
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);
  FirebaseAuth get _auth => _ref.read(authProvider);

  // Storage uses the default app instance
  FirebaseStorage get _storage => FirebaseStorage.instance;

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');

  CollectionReference get _clientCollection => _firestore.collection('clients');

  // =================================================================
  // 🎯 HELPER METHODS
  // =================================================================

  /// Fetches the configuration for a specific tenant
  Future<TenantModel> fetchTenantConfig(String tenantId) async {
    try {
      // Direct access to the central 'tenants' collection
      final doc = await _firestore.collection('tenants').doc(tenantId).get();

      if (!doc.exists) {
        throw Exception("Tenant '$tenantId' not found in database.");
      }

      // 🎯 FIX: Use fromFirestore instead of fromMap
      return TenantModel.fromFirestore(doc);
    } catch (e) {
      throw Exception("Failed to load tenant settings: $e");
    }
  }

  /// Looks up which tenant a mobile number belongs to
  Future<String> getUserTenant(String mobile) async {
    final email = "$mobile@nutricarewellness.in";
    try {
      final doc = await _firestore.collection('user_directory').doc(email).get();
      if (doc.exists) {
        return doc.data()?['tenant_id'] ?? 'live';
      }
    } catch (e) {
      _logger.e("Directory lookup failed: $e");
    }
    return 'live'; // Default fallback
  }

  // =================================================================
  // ♻️ CLIENT MANAGEMENT
  // =================================================================

  Future<void> addClient(ClientModel client, String password, PlatformFile? photo, PlatformFile? agreement) async {
    _logger.i('Attempting to add new client: ${client.name}');

    // 1. Upload Files
    String? photoUrl = await _uploadFile(photo, 'clients/${client.id}/photo');
    String? agreementUrl = await _uploadFile(agreement, 'clients/${client.id}/agreement');

    final newDocRef = _clientCollection.doc();
    final clientId = newDocRef.id;

    final data = client.toMap();
    data['photoUrl'] = photoUrl;
    data['agreementUrl'] = agreementUrl;
    data['status'] = 'Inactive';
    data['hasPasswordSet'] = false;
    data['createdAt'] = FieldValue.serverTimestamp();

    await newDocRef.set(data);
    _logger.i('Client added successfully with ID: $clientId');
  }

  Future<Map<String, dynamic>> softDeleteClient({required String clientId, bool isCheckOnly = false}) async {
    final clientDoc = await _clientCollection.doc(clientId).get();
    if (!clientDoc.exists) {
      return {'canDelete': false, 'message': 'Client not found.'};
    }

    final clientData = clientDoc.data() as Map<String, dynamic>;
    final rawAssignments = clientData['packageAssignments'] as Map<String, dynamic>?;

    if (rawAssignments != null && rawAssignments.isNotEmpty) {
      final hasActiveAssignments = rawAssignments.values.any((assignmentMap) => assignmentMap['isActive'] == true);

      if (hasActiveAssignments) {
        final message = 'Client $clientId has active package assignments and cannot be soft deleted.';
        _logger.w(message);
        return {'canDelete': false, 'message': message};
      }
    }

    if (isCheckOnly) {
      return {'canDelete': true, 'message': 'Client $clientId can be soft deleted.'};
    }

    _logger.i('Soft deleting client: $clientId');
    try {
      await _clientCollection.doc(clientId).update({
        'isSoftDeleted': true,
        'status': 'Inactive',
        'updatedAt': FieldValue.serverTimestamp(),
        'hasPasswordSet': false,
      });
      return {'canDelete': true, 'message': 'Client soft deleted successfully.'};
    } catch (e) {
      _logger.e('Error soft deleting client $clientId: $e');
      return {'canDelete': false, 'message': 'Failed to soft delete client.'};
    }
  }

  Future<String?> _uploadFile(PlatformFile? file, String path) async {
    if (file == null || file.bytes == null) return null;
    try {
      final extension = file.extension ?? 'bin';
      final storageRef = _storage.ref().child('$path.$extension');
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
        throw Exception("Login ID has already been customized.");
      }

      final newSystemId = generateSystemId();

      await _clientCollection.doc(clientId).update({
        'loginId': newSystemId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return newSystemId;
    } catch (e, stack) {
      _logger.e('Error changing login ID', error: e, stackTrace: stack);
      rethrow;
    }
  }

  String generateSystemId() {
    final int maxRandom = 1000;
    final Random random = Random();
    int randomNumber = random.nextInt(maxRandom);
    return 'CID-${DateTime.now().millisecondsSinceEpoch % 1000}${randomNumber.toString().padLeft(4, '0')}';
  }

  // =================================================================
  // 🔐 CREDENTIALS & AUTH
  // =================================================================

  Future<void> setPasswordAndActivate(String clientId, String password) async {
    final authEmail = '$clientId@nutricarewellness.in';
    _logger.i('Starting secure password activation via Cloud Function for $clientId');

    final callable = _functions.httpsCallable('createClientCredentials');

    try {
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'clientId': clientId,
        'clientEmail': authEmail,
        'initialPassword': password,
      });

      _logger.i('Auth user successfully created: ${result.data['uid']}');

      await _clientCollection.doc(clientId).update({
        'hasPasswordSet': true,
        'status': 'Active',
        'updatedAt': FieldValue.serverTimestamp(),
      });

    } on FirebaseFunctionsException catch (e) {
      _logger.e("Cloud Function Error: ${e.message}");
      throw Exception("Failed to create credentials: ${e.message}");
    } catch (e) {
      _logger.e("General Error: $e");
      rethrow;
    }
  }

  Future<void> destroyCredentialsAndDeactivate(String clientId) async {
    _logger.i('Deactivating client and destroying credential flags: $clientId');
    try {
      await _clientCollection.doc(clientId).update({
        'hasPasswordSet': false,
        'status': 'Inactive',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      _logger.e('Error deactivating client', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> updateClientStatus(String clientId, String newStatus) async {
    try {
      if (newStatus == 'Inactive') {
        await destroyCredentialsAndDeactivate(clientId);
      } else if (newStatus == 'Active') {
        final doc = await _clientCollection.doc(clientId).get();
        final hasPassword = (doc.data() as Map<String, dynamic>?)?['hasPasswordSet'] ?? false;

        if (!hasPassword) {
          throw Exception('Cannot set status to Active: Credential has not been created.');
        }

        await _clientCollection.doc(clientId).update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e, stack) {
      _logger.e('Error updating client status', error: e, stackTrace: stack);
      rethrow;
    }
  }

  // --- ADMIN ROLE MANAGEMENT ---

  Future<void> setAdminRole({required String targetUid, required bool isAdmin}) async {
    try {
      final callable = _functions.httpsCallable('setAdminClaim');
      await callable.call(<String, dynamic>{
        'targetUid': targetUid,
        'isAdmin': isAdmin,
      });
      await FirebaseAuth.instance.currentUser?.getIdTokenResult(true);
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Failed to update role: ${e.message}');
    }
  }

  Future<bool> checkAdminStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      IdTokenResult result = await user.getIdTokenResult(true);
      return result.claims?['isAdmin'] == true;
    } catch (e) {
      return false;
    }
  }

  // =================================================================
  // 📦 PACKAGE ASSIGNMENT
  // =================================================================

  CollectionReference clientAssignmentCollection(String clientId) {
    return _clientCollection.doc(clientId).collection('packageAssignments');
  }

  Future<void> assignPackageToClient(String clientId, PackageAssignmentModel newAssignment) async {
    try {
      await clientAssignmentCollection(clientId).add(newAssignment.toMap());
    } catch (e) {
      _logger.e('Failed to assign package: $e');
      throw Exception('Failed to assign package.');
    }
  }

  Future<void> updateAssignedPackage({required String clientId, required PackageAssignmentModel updatedAssignment}) async {
    try {
      // NOTE: For subcollections, we need the doc ID of the assignment, not just packageId.
      // Assuming updatedAssignment.id holds the document ID.
      if (updatedAssignment.id.isEmpty) throw Exception("Invalid assignment ID");

      await clientAssignmentCollection(clientId).doc(updatedAssignment.id).update(updatedAssignment.toMap());
    } catch (e) {
      // Fallback for old map structure if needed, but subcollection preferred
      _logger.e('Error updating package: $e');
    }
  }

  Stream<List<PackageAssignmentModel>> streamClientAssignments(String clientId) {
    return clientAssignmentCollection(clientId)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PackageAssignmentModel.fromFirestore(doc))
        .toList());
  }
  Stream<List<ClientModel>> streamAllClientsForReporting() {
    // This streams the entire 'clients' collection
    return _clientCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ClientModel.fromFirestore(doc)).toList());
  }


  // =================================================================
  // 🔍 DATA RETRIEVAL & SEARCH
  // =================================================================

  Future<List<ClientModel>> getAllClients() async {
    try {
      final snapshot = await _clientCollection.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => ClientModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to load clients.');
    }
  }

  Future<ClientModel> getClientById(String clientId) async {
    try {
      final doc = await _clientCollection.doc(clientId).get();
      if (!doc.exists) throw Exception('Client not found.');
      return ClientModel.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ClientModel>> searchClients(String query) async {
    if (query.isEmpty) return [];

    try {
      final String cleanQuery = query.trim();
      final Map<String, DocumentSnapshot> distinctDocs = {};
      final List<Future<QuerySnapshot>> searchFutures = [];

      // A. Name Search
      searchFutures.add(_searchByName(cleanQuery));

      // B. Mobile Search
      if (RegExp(r'^[0-9]+$').hasMatch(cleanQuery)) {
        searchFutures.add(_clientCollection
            .where('mobile', isGreaterThanOrEqualTo: cleanQuery)
            .where('mobile', isLessThan: '$cleanQuery\uf8ff')
            .limit(5)
            .get());
      }

      final results = await Future.wait(searchFutures);

      for (var snapshot in results) {
        for (var doc in snapshot.docs) {
          distinctDocs[doc.id] = doc;
        }
      }

      return distinctDocs.values.map((doc) => ClientModel.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.e('Error searching clients: $e');
      return [];
    }
  }

  Future<QuerySnapshot> _searchByName(String nameQuery) {
    return _clientCollection
        .where('name', isGreaterThanOrEqualTo: nameQuery)
        .where('name', isLessThan: '$nameQuery\uf8ff')
        .limit(10)
        .get();
  }
}