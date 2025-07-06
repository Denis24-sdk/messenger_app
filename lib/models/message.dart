import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String? id;
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final String? fileId;
  final String type;
  final Timestamp timestamp;
  final String? replyToMessage;
  final String? replyToSender;
  final bool isEdited;
  final bool isRead;

  Message({
    this.id,
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.message,
    this.fileId,
    this.type = 'text',
    required this.timestamp,
    this.replyToMessage,
    this.replyToSender,
    this.isEdited = false,
    this.isRead = false,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderID: data['senderID'] ?? '',
      senderEmail: data['senderEmail'] ?? '',
      receiverID: data['receiverID'] ?? '',
      message: data['message'] ?? '',
      fileId: data['fileId'],
      type: data['type'] ?? 'text',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      replyToMessage: data['replyToMessage'],
      replyToSender: data['replyToSender'],
      isEdited: data['isEdited'] ?? false,
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'message': message,
      'fileId': fileId,
      'type': type,
      'timestamp': timestamp,
      'replyToMessage': replyToMessage,
      'replyToSender': replyToSender,
      'isEdited': isEdited,
      'isRead': isRead,
    };
  }
}