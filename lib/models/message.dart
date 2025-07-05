// lib/models/message.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final String? fileId;
  final String type;
  final Timestamp timestamp;
  final String? replyToMessage;
  final String? replyToSender;
  final bool? isEdited;
  final bool? isRead;

  Message({
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.message,
    this.fileId,
    this.type = 'text',
    required this.timestamp,
    this.replyToMessage,
    this.replyToSender,
    this.isEdited,
    this.isRead,
  });

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
      'isEdited': isEdited ?? false,
      'isRead': isRead ?? false,
    };
  }
}