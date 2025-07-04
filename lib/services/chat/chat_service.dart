import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_flutter/models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Стрим всех юзеров для экрана поиска
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  // Стрим активных чатов для главного экрана
  Stream<List<Map<String, dynamic>>> getChatRoomsStream() {
    final String currentUserID = _auth.currentUser!.uid;

    return _firestore
        .collection('chat_rooms')
        .where('members', arrayContains: currentUserID) // Находим чаты, где юзер - участник
        .snapshots()
        .asyncMap((snapshot) async {
      // Для каждого чата получаем данные собеседника
      List<Future<Map<String, dynamic>?>> userFutures =
      snapshot.docs.map((doc) async {
        List<dynamic> members = doc.data()['members'];
        String otherUserID = members.firstWhere((id) => id != currentUserID);

        final userDoc = await _firestore.collection('Users').doc(otherUserID).get();
        return userDoc.data();
      }).toList();

      final usersData = await Future.wait(userFutures);
      return usersData.where((user) => user != null).cast<Map<String, dynamic>>().toList();
    });
  }

  Future<void> signOut() async {
    return await _auth.signOut();
  }

  Future<void> sendMessage(String receiverID, String message) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
    );

    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    // Создаем или обновляем документ чата с метаданными
    await _firestore.collection("chat_rooms").doc(chatRoomID).set({
      'members': ids,
      'last_message_timestamp': timestamp,
    }, SetOptions(merge: true));

    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }
}