import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_flutter/models/message.dart';


class ChatService {
  // Получаем экземпляр Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Получаем поток пользователей
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Преобразуем каждый документ в Map
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  Future<void> signOut() async {
    return await _auth.signOut();
  }

  // ОТПРАВКА СООБЩЕНИЙ
  Future<void> sendMessage(String receiverID, String message) async {
    // Получаем информацию о текущем пользователе
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // Создаем новое сообщение
    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
    );

    // Создаем ID чата из UID текущего пользователя и получателя (отсортированных)
    List<String> ids = [currentUserID, receiverID];
    ids.sort(); // Сортируем ID, это гарантирует, что ID чата всегда будет одинаковым для любой пары
    String chatRoomID = ids.join('_'); // Объединяем их в одну строку

    // Добавляем новое сообщение в базу данных
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  // МЕТОД ПОЛУЧЕНИЕ СООБЩЕНИЙ
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    // Создаем ID комнаты чата из ID двух пользователей
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false) // Сортируем сообщения по времени
        .snapshots();
  }

}