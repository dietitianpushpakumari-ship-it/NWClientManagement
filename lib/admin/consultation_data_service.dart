import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/modules/client/services/client_service.dart';

import 'database_provider.dart';

class ConsultationDataService {

  final Ref _ref; // Store Ref to access dynamic providers

  ConsultationDataService(this._ref);
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  // Collection where temporary vitals data is stored (Step 2)
  static const String _vitalsCollection = 'clientVitals';

  // Collection where temporary meal plan data is stored (Step 3)
  static const String _mealPlanCollection = 'clientDietPlans';
  static const String _masterPlanAssignmentCollection = 'clientDietPlans';


  // 🎯 Check if Vitals data exists for a given temporary client ID
  Future<bool> checkVitalsCompletion(String clientId) async {
    try {
      // Assuming you store vitals documents with the clientId as the ID,
      // or use it in a query (e.g., if you store multiple vitals records).
      // For simplicity, let's assume one document per client in a 'vitals' subcollection
      final snapshot = await _firestore
          .collection(_vitalsCollection)
          .where('clientId', isEqualTo: clientId)
          .limit(1)
          // .doc(clientId)
          // Assuming doc ID is the client ID
          .get();

      // If the document exists, the step is complete
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking vitals completion for $clientId: $e');
      return false;
    }
  }

  // 🎯 Check if Meal Plan data exists for a given temporary client ID
  Future<bool> checkMealPlanCompletion(String clientId) async {
    try {
      // Assuming meal plan documents are stored similarly
      final snapshot = await _firestore
          .collection(_mealPlanCollection)
          .where('clientId', isEqualTo: clientId)
          .where('isReadyToDeliver', isEqualTo: true)
          .limit(1)
          // .doc(clientId) // Assuming doc ID is the client ID
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking meal plan completion for $clientId: $e');
      return false;
    }
  }

  Future<bool> checkMealAssignmentCompletion(String clientId) async {
    try {
      // Assuming meal plan documents are stored similarly
      final snapshot = await _firestore
          .collection(_masterPlanAssignmentCollection)
          .where('clientId', isEqualTo: clientId)
          .limit(1)
          // .doc(clientId) // Assuming doc ID is the client ID
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking meal plan completion for $clientId: $e');
      return false;
    }
  }

}
