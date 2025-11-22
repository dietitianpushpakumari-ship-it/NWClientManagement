import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/data/wellness_content_data.dart';

class LibraryUploader {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadLibrary() async {
    final collection = _firestore.collection('wellness_library');
    int addedCount = 0;
    int skippedCount = 0;

    print("🚀 Starting Wellness Library Upload...");

    for (var item in wellnessLibraryData) {
      final docRef = collection.doc(item.id); // Use the custom ID as the Doc ID

      // 1. Check for existence (Non-redundancy)
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // 2. Upload if new
        await docRef.set(item.toMap());
        print("✅ Added: ${item.title}");
        addedCount++;
      } else {
        // Optional: Update if you want to overwrite content
        // await docRef.update(item.toMap());
        print("Example Skipped (Already exists): ${item.title}");
        skippedCount++;
      }
    }

    print("🎉 Upload Complete!");
    print("Added: $addedCount, Skipped: $skippedCount");
  }
}