import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';

import '../chat_message_model.dart';


final adminChatServiceProvider = Provider<AdminChatService>((ref) {
  // This watches the dynamic database provider we created earlier
  final firestore = ref.watch(firestoreProvider);
  return AdminChatService(firestore);
});
class AdminChatService {
  final FirebaseFirestore _firestore;
  late final FirebaseStorage _storage;


  AdminChatService(this._firestore) {
    // Ensure Storage uses the same App/Project as Firestore
    _storage = FirebaseStorage.instanceFor(app: _firestore.app);
  }

  // 1️⃣ DEFINE THE PROVIDER

  // =================================================================
  // 🎯 1. CLIENT LIST STREAMS
  // =================================================================

  // Used for the main Inbox Client List (Sorted by most recent message)
  Stream<QuerySnapshot> getAllChats() {
    return _firestore
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // (Optional) If you want to filter by Active/Archived at the client level later
  Stream<List<QueryDocumentSnapshot>> getActiveChats() {
    return _firestore
        .collection('chats')
        .where('isArchived', isNotEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Stream<List<QueryDocumentSnapshot>> getArchivedChats() {
    return _firestore
        .collection('chats')
        .where('isArchived', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // =================================================================
  // 🎯 2. GLOBAL TICKET DASHBOARD STREAMS
  // =================================================================

  // Global: All Pending Requests from ALL clients
  Stream<List<ChatMessageModel>> getActiveTickets() {
    return _firestore
        .collectionGroup('messages')
        .where('type', isEqualTo: 'request')
        .where('requestStatus', isEqualTo: 'pending')
        .orderBy('timestamp', descending: false) // Oldest first
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc))
            .toList());
  }

  // Global: Recently Resolved Requests
  Stream<List<ChatMessageModel>> getArchivedTickets() {
    return _firestore
        .collectionGroup('messages')
        .where('type', isEqualTo: 'request')
        .where('requestStatus', whereIn: ['approved', 'rejected', 'completed'])
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc))
            .toList());
  }

  // =================================================================
  // 🎯 3. INDIVIDUAL CHAT METHODS
  // =================================================================

  // Get messages for a specific client
  Stream<List<ChatMessageModel>> getMessages(String clientId) {
    return _firestore
        .collection('chats')
        .doc(clientId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc))
            .toList());
  }

  // Resolve/Update Request Status
  Future<void> updateRequestStatus(String clientId, String messageId,
      RequestStatus status, String? adminComment) async {
    await _firestore
        .collection('chats')
        .doc(clientId)
        .collection('messages')
        .doc(messageId)
        .update({
      'requestStatus': status.name,
      'adminComment': adminComment,
    });
  }

  // Toggle Archive Status for a Client
  Future<void> toggleChatArchive(String clientId, bool archive) async {
    await _firestore.collection('chats').doc(clientId).set({
      'isArchived': archive
    }, SetOptions(merge: true));
  }

  // ... existing code ...

  Future<void> sendAdminMessage({
    required String clientId,
    required String text,
    required MessageType type,
    File? attachmentFile,
    String? attachmentName,
    ChatMessageModel? replyTo, // 🆕 The ticket/message being replied to
  }) async {
    String? attachmentUrl;

    if (attachmentFile != null) {
      final ref = _storage.ref().child('chat_attachments/admin_${DateTime
          .now()
          .millisecondsSinceEpoch}_$attachmentName');
      final uploadTask = ref.putFile(attachmentFile);
      final snapshot = await uploadTask;
      attachmentUrl = await snapshot.ref.getDownloadURL();
    }

    // 🎯 Generate Reply Context
    String? replyText;
    MessageType? replyType;
    if (replyTo != null) {
      replyType = replyTo.type;
      if (replyTo.type == MessageType.request) {
        replyText = "Ticket: ${replyTo.requestType.name.toUpperCase()}";
      } else if (replyTo.type == MessageType.image) {
        replyText = "📷 Photo";
      } else {
        replyText = replyTo.text;
      }
    }

    final message = ChatMessageModel(
      id: '',
      // Auto-generated by Firestore
      senderId: 'admin',
      isSenderClient: false,
      text: text,
      type: type,
      timestamp: DateTime.now(),
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      messageStatus: MessageStatus.sent,
      // 🎯 Save Reference
      replyToMessageId: replyTo?.id,
      replyToMessageText: replyText,
      replyToMessageType: replyType,
    );

    final chatDocRef = _firestore.collection('chats').doc(clientId);
    await chatDocRef.collection('messages').add(message.toMap());

    await chatDocRef.set({
      'lastMessage': type == MessageType.text
          ? "👨‍⚕️ $text"
          : "👨‍⚕️ Sent attachment",
      'lastMessageTime': FieldValue.serverTimestamp(),
      'hasPendingRequest': false,
      'isArchived': false,
    }, SetOptions(merge: true));
  }
  Future<void> rejectRequest(String requestId, String reason) async {
    try {
      // TODO: Add your actual database or API logic here

      print("Request $requestId rejected because: $reason");

    } catch (e) {
      print("Error rejecting request: $e");
      rethrow; // Pass the error back to the UI so you can show a Snackbar
    }
  }
}