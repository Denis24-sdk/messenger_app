import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_flutter/models/chat_room.dart';
import 'package:messenger_flutter/models/message.dart';
import 'package:messenger_flutter/services/storage/storage_service.dart';

class ChatService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StorageService _storageService = StorageService();

  ChatService({required FirebaseFirestore firestore, required FirebaseAuth auth})
      : _firestore = firestore,
        _auth = auth;

  Future<String> createPrivateChatRoomIfNeeded(String otherUserID) async {
    final currentUserID = _auth.currentUser!.uid;
    List<String> ids = [currentUserID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomID);
    final docSnapshot = await chatRoomRef.get();

    if (!docSnapshot.exists) {
      await chatRoomRef.set({
        'chatRoomId': chatRoomID,
        'members': ids,
        'isGroup': false,
        'lastMessage': null,
        'lastMessageSenderId': null,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return chatRoomID;
  }

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore
        .collection("Users")
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<ChatRoom>> getChatRoomsStream() {
    final String currentUserID = _auth.currentUser!.uid;
    return _firestore
        .collection('chat_rooms')
        .where('members', arrayContains: currentUserID)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatRoom.fromFirestore(doc, currentUserID))
        .toList());
  }

  Stream<List<Message>> getMessagesStream(String chatRoomID) {
    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  Future<void> createGroupChat(String groupName, List<String> memberIds) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUsername =
        _auth.currentUser!.displayName ?? _auth.currentUser!.email!;

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
      String chatRoomID, String messageText, String? receiverID,
      {String? replyToMessage, String? replyToSenderName}) async {
    final String currentUserID = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: _auth.currentUser!.email!,
      receiverID: receiverID ?? '',
      message: messageText,
      timestamp: timestamp,
      replyToMessage: replyToMessage,
      replyToSender: replyToSenderName,
    );

    DocumentReference chatRoomRef =
    _firestore.collection("chat_rooms").doc(chatRoomID);

    await chatRoomRef.update({
      'lastMessage': messageText,
      'lastMessageSenderId': currentUserID,
      'lastMessageTimestamp': timestamp,
    });

    await chatRoomRef.collection("messages").add(newMessage.toMap());
  }

  Future<DocumentReference> sendImageMessage(String chatRoomID,
      {required File imageFile, String? receiverID}) async {
    final String currentUserID = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: _auth.currentUser!.email!,
      receiverID: receiverID ?? '',
      message: imageFile.path,
      type: 'image_local',
      timestamp: timestamp,
    );

    DocumentReference chatRoomRef =
    _firestore.collection("chat_rooms").doc(chatRoomID);

    await chatRoomRef.update({
      'lastMessage': "📷 Изображение",
      'lastMessageSenderId': currentUserID,
      'lastMessageTimestamp': timestamp,
    });

    return await chatRoomRef.collection("messages").add(newMessage.toMap());
  }

  Future<void> updateMessageWithImageUrl(
      DocumentReference messageRef, String url, String fileId) async {
    await messageRef.update({
      'message': url,
      'fileId': fileId,
      'type': 'image',
    });
  }

  Future<void> deleteMessage(String chatRoomID, String messageID) async {
    DocumentReference messageRef = _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .doc(messageID);
    DocumentSnapshot doc = await messageRef.get();

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['type'] == 'image' && data['fileId'] != null) {
        await _storageService.deleteFile(data['fileId']);
      }
    }

    await messageRef.update({
      'message': 'Сообщение удалено',
      'type': 'text',
      'isEdited': true,
      'fileId': null
    });
  }

  Future<void> editMessage(
      String chatRoomID, String messageID, String newMessage) async {
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .doc(messageID)
        .update({
      'message': newMessage,
      'isEdited': true,
    });
  }

  Future<void> clearChatHistory(String chatRoomID) async {
    final CollectionReference messagesRef = _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages");
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
      'lastMessage': 'Чат очищен',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot> getUserStream(String userID) {
    return _firestore.collection('Users').doc(userID).snapshots();
  }

  Stream<DocumentSnapshot> getChatRoomStream(String chatRoomID) {
    return _firestore.collection('chat_rooms').doc(chatRoomID).snapshots();
  }

  Future<void> markMessagesAsRead(String chatRoomID) async {
    final String currentUserId = _auth.currentUser!.uid;
    final querySnapshot = await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .where('senderID', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    if (querySnapshot.docs.isEmpty) return;

    final WriteBatch batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}