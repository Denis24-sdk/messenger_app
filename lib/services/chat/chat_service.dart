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

    // TODO: Создать ID чата и добавить сообщение в базу данных
  }
}