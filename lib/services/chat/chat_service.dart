import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


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
}