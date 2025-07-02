import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderID; // кто отправил
  final String senderEmail;
  final String receiverID; // кому отправил
  final String message;
  final Timestamp timestamp;

  Message({
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.message,
    required this.timestamp,
  });

  // Преобразование в Map для сохранения в Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'message': message,
      'timestamp': timestamp,
    };
  }
}