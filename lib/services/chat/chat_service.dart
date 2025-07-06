import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_flutter/models/message.dart';
import 'package:messenger_flutter/services/storage/storage_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Stream<QuerySnapshot> getChatRoomsStream() {
    final String currentUserID = _auth.currentUser!.uid;
    return _firestore
        .collection('chat_rooms')
        .where('members', arrayContains: currentUserID)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  Future<void> createGroupChat(String groupName, List<String> memberIds) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUsername = _auth.currentUser!.displayName ?? _auth.currentUser!.email!;

    List<String> allMemberIds = [currentUserId, ...memberIds];
    allMemberIds = allMemberIds.toSet().toList();

    DocumentReference groupDocRef = _firestore.collection('chat_rooms').doc();

    await groupDocRef.set({
      'chatRoomId': groupDocRef.id,
      'groupName': groupName,
      'members': allMemberIds,
      'isGroup': true,
      'createdBy': currentUserId,
      'createdAt': Timestamp.now(),
      'lastMessage': '$currentUsername создал(а) группу',
      'lastMessageSenderId': 'system',
      'lastMessageTimestamp': Timestamp.now(),
    });
  }

  Future<void> sendMessage(
      String chatRoomID,
      String message, {
        String? receiverID,
        String? replyToMessage,
        String? replyToSenderName,
      }) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID ?? '',
      message: message,
      type: 'text',
      timestamp: timestamp,
      replyToMessage: replyToMessage,
      replyToSender: replyToSenderName,
    );

    DocumentReference chatRoomRef = _firestore.collection("chat_rooms").doc(chatRoomID);

    if (!(await chatRoomRef.get()).exists && receiverID != null) {
      await chatRoomRef.set({
        'members': [currentUserID, receiverID],
        'isGroup': false,
      });
    }

    await chatRoomRef.update({
      'lastMessage': message,
      'lastMessageSenderId': currentUserID,
      'lastMessageTimestamp': timestamp,
    });

    await chatRoomRef.collection("messages").add(newMessage.toMap());
  }

  Future<DocumentReference> sendLocalImageMessage(String chatRoomID, String receiverID, File imageFile, {String? fileId}) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: imageFile.path,
      fileId: fileId,
      type: 'image_local',
      timestamp: timestamp,
    );

    DocumentReference chatRoomRef = _firestore.collection("chat_rooms").doc(chatRoomID);

    await chatRoomRef.update({
      'lastMessage': "📷 Изображение",
      'lastMessageSenderId': currentUserID,
      'lastMessageTimestamp': timestamp,
    });

    return await chatRoomRef.collection("messages").add(newMessage.toMap());
  }

  Future<void> updateImageMessageUrl(DocumentReference messageRef, String newUrl, String newFileId) async {
    await messageRef.update({
      'message': newUrl,
      'fileId': newFileId,
      'type': 'image',
    });
  }

  Future<void> deleteMessage(String chatRoomID, String messageID) async {
    DocumentReference messageRef = _firestore.collection("chat_rooms").doc(chatRoomID).collection("messages").doc(messageID);
    DocumentSnapshot doc = await messageRef.get();

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['type'] == 'image' && data['fileId'] != null) {
        await _storageService.deleteFile(data['fileId']);
      }
    }

    await messageRef.update({'message': 'Сообщение удалено', 'type': 'text', 'isEdited': true, 'fileId': null});
  }

  Future<void> clearChatHistory(String chatRoomID) async {
    final CollectionReference messagesRef = _firestore.collection("chat_rooms").doc(chatRoomID).collection("messages");
    final messagesSnapshot = await messagesRef.get();
    final WriteBatch batch = _firestore.batch();

    for (var doc in messagesSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['type'] == 'image' && data['fileId'] != null) {
        await _storageService.deleteFile(data['fileId']);
      }
      batch.delete(doc.reference);
    }

    await batch.commit();
    await _firestore.collection("chat_rooms").doc(chatRoomID).update({
      'lastMessage': 'Чат очищен', 'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getMessages(String chatRoomID) {
    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  Future<void> updateUserStatus(bool isOnline) async {
    if (_auth.currentUser == null) return;
    final String currentUserID = _auth.currentUser!.uid;
    await _firestore.collection("Users").doc(currentUserID).update({
      'isOnline': isOnline,
      'last_seen': Timestamp.now(),
    });
  }

  Stream<DocumentSnapshot> getUserStream(String userID) {
    return _firestore.collection('Users').doc(userID).snapshots();
  }

  Future<void> markMessagesAsRead(String chatRoomID, String currentUserId) async {
    final querySnapshot = await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .where('senderID', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final WriteBatch batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> editMessage(String chatRoomID, String messageID, String newMessage) async {
    await _firestore.collection("chat_rooms").doc(chatRoomID).collection("messages").doc(messageID).update({
      'message': newMessage, 'isEdited': true,
    });
  }

  Future<void> updateTypingStatus(String chatRoomID, bool isTyping) async {
    final String currentUserID = _auth.currentUser!.uid;
    await _firestore.collection("chat_rooms").doc(chatRoomID).set(
      {'typingStatus': {currentUserID: isTyping}}, SetOptions(merge: true),
    );
  }

  Stream<DocumentSnapshot> getChatRoomStream(String chatRoomID) {
    return _firestore.collection('chat_rooms').doc(chatRoomID).snapshots();
  }
}