import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/feed_content_model.dart';


class FeedService {
  Ref ref;

  FeedService(this.ref);
  FirebaseFirestore get _firestore => ref.read(firestoreProvider);

  CollectionReference get _feedCollection => _firestore.collection('client_feed');

  // --- READ (Admin Stream) ---
  Stream<List<FeedContentModel>> streamAllFeeds() {
    return _feedCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FeedContentModel.fromFirestore(doc))
        .toList());
  }

  // --- CREATE / UPDATE ---
  Future<void> saveFeedItem(FeedContentModel item) async {
    if (item.id.isEmpty) {
      await _feedCollection.add(item.toMap());
    } else {
      await _feedCollection.doc(item.id).update(item.toMap());
    }
  }

  // --- DELETE ---
  Future<void> deleteFeedItem(String id) async {
    await _feedCollection.doc(id).delete();
  }

  // --- ANALYTICS: Increment Share Count ---
  Future<void> trackShare(String id) async {
    await _feedCollection.doc(id).update({
      'shares': FieldValue.increment(1)
    });
  }
}