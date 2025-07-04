import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_flutter/models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Стрим чатов для главного экрана. Сортировка по последнему сообщению.
  Stream<QuerySnapshot> getChatRoomsStream() {
    final String currentUserID = _auth.currentUser!.uid;
    return _firestore
        .collection('chat_rooms')
        .where('members', arrayContains: currentUserID)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  Future<void> signOut() async {
    return await _auth.signOut();
  }

  // При отправке сообщения обновляем метаданные чата.
  Future<void> sendMessage(
      String receiverID,
      String message,
      {String? replyToMessage, String? replyToSenderName}
      ) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
      replyToMessage: replyToMessage,
      replyToSender: replyToSenderName,
    );

    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    await _firestore.collection("chat_rooms").doc(chatRoomID).set({
      'members': ids,
      'lastMessage': message,
      'lastMessageSenderId': currentUserID,
      'lastMessageTimestamp': timestamp,
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
        .snapshots(includeMetadataChanges: false); 
  }

  // Обновляем статус набора текста в чате
  Future<void> updateTypingStatus(String chatRoomID, bool isTyping) async {
    final String currentUserID = _auth.currentUser!.uid;
    await _firestore.collection("chat_rooms").doc(chatRoomID).set(
      {
        'typingStatus': {
          currentUserID: isTyping,
        }
      },
      SetOptions(merge: true),
    );
  }

// Стрим для получения данных самого чата
  Stream<DocumentSnapshot> getChatRoomStream(String chatRoomID) {
    return _firestore.collection('chat_rooms').doc(chatRoomID).snapshots();
  }



  // Обновляем статус пользователя и время последнего визита
  Future<void> updateUserStatus(bool isOnline) async {
    // Убеждаемся, что пользователь залогинен
    if (_auth.currentUser == null) return;

    final String currentUserID = _auth.currentUser!.uid;

    await _firestore.collection("Users").doc(currentUserID).update({
      'isOnline': isOnline,
      'last_seen': Timestamp.now(),
    });
  }

//Стрим для получения данных конкретного пользователя (нужен для UI)
  Stream<DocumentSnapshot> getUserStream(String userID) {
    return _firestore.collection('Users').doc(userID).snapshots();
  }


  // Отмечаем сообщения как прочитанные
  Future<void> markMessagesAsRead(String chatRoomID, String receiverID) async {
    // Получаем все непрочитанные сообщения, отправленные собеседником
    final querySnapshot = await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .where('senderID', isEqualTo: receiverID)
        .where('isRead', isEqualTo: false)
        .get();

    // Используем WriteBatch для атомарного обновления всех документов
    final WriteBatch batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }



  // для редактирования и удаления
  Future<void> editMessage(String chatRoomID, String messageID, String newMessage) async {
    final Timestamp newTimestamp = Timestamp.now();
    final DocumentReference messageRef = _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .doc(messageID);

    // Обновляем само сообщение
    await messageRef.update({
      'message': newMessage,
      'isEdited': true,
      'lastEditedAt': newTimestamp,
    });

    // Проверяем, было ли это сообщение последним в чате
    final DocumentSnapshot chatRoomDoc = await _firestore.collection("chat_rooms").doc(chatRoomID).get();
    final DocumentSnapshot messageDoc = await messageRef.get();

    if (chatRoomDoc.exists && (chatRoomDoc.data() as Map).containsKey('lastMessageTimestamp')) {
      if ((chatRoomDoc.get('lastMessageTimestamp') as Timestamp).millisecondsSinceEpoch == (messageDoc.get('timestamp') as Timestamp).millisecondsSinceEpoch) {
        await _firestore.collection("chat_rooms").doc(chatRoomID).update({
          'lastMessage': newMessage,
        });
      }
    }
  }

  Future<void> deleteMessage(String chatRoomID, String messageID) async {
    const String deletedMessage = 'Сообщение удалено';
    final DocumentReference messageRef = _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .doc(messageID);

    // Обновляем текст сообщения на "удалено"
    await messageRef.update({
      'message': deletedMessage,
      'isEdited': true,
    });

    final DocumentSnapshot chatRoomDoc = await _firestore.collection("chat_rooms").doc(chatRoomID).get();
    final DocumentSnapshot messageDoc = await messageRef.get();

    if (chatRoomDoc.exists && (chatRoomDoc.data() as Map).containsKey('lastMessageTimestamp')) {
      if ((chatRoomDoc.get('lastMessageTimestamp') as Timestamp).millisecondsSinceEpoch == (messageDoc.get('timestamp') as Timestamp).millisecondsSinceEpoch) {
        await _firestore.collection("chat_rooms").doc(chatRoomID).update({
          'lastMessage': deletedMessage,
        });
      }
    }
  }

}

