import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/quiz_bank_data.dart';
import 'package:nutricare_client_management/admin/quiz_model.dart';

class QuizUploader {

  final Ref _ref; // Store Ref to access dynamic providers
  QuizUploader(this._ref);

  // 🎯 DYNAMIC GETTERS (Switch based on Tenant)
  // These will now automatically point to 'Guest', 'Live', or 'Clinic A' DB
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);


  Future<void> uploadQuizBank() async {
    final collection = _firestore.collection('quiz_bank');
    int added = 0;
    int skipped = 0;

    print("🚀 Starting Quiz Bank Upload...");

    for (QuizQuestion q in masterQuizBank) {
      final docRef = collection.doc(q.id); // Use our custom ID as Doc ID

      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // Create Map manually since toMap isn't in your entity file yet
        // Or add a toMap() method to your QuizQuestion model
        await docRef.set({
          'question': q.question,
          'isFact': q.isFact,
          'explanation': q.explanation,
          'category': q.category,
          'imageUrl': q.imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print("✅ Added: [${q.category}] ${q.question.substring(0, 20)}...");
        added++;
      } else {
        print("⏭️ Skipped (Exists): ${q.id}");
        skipped++;
      }
    }

    print("🎉 Upload Complete! Added: $added, Skipped: $skipped");
  }
}