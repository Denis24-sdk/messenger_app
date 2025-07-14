import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:messenger_flutter/models/message.dart';

class ChatRoom {
  final String id;
  final bool isGroup;
  final List<String> members;
  final Message? lastMessage;

  final String? groupName;
  final String? groupAvatarUrl;
  final String? createdBy;
  final Timestamp? createdAt;

  final String? otherUserId;

  final Map<String, int> unreadCount;

  ChatRoom({
    required this.id,
    required this.isGroup,
    required this.members,
    this.lastMessage,
    this.groupName,
    this.groupAvatarUrl,
    this.createdBy,
    this.createdAt,
    this.otherUserId,
    required this.unreadCount,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc, String currentUserId) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    Message? lastMessage;
    if (data['lastMessageTimestamp'] is Timestamp) {
      lastMessage = Message(
        senderID: data['lastMessageSenderId'] ?? '',
        senderEmail: '',
        receiverID: '',
        message: data['lastMessage'] ?? '',
        timestamp: data['lastMessageTimestamp'],
      );
    }

    bool isGroup = data['isGroup'] ?? false;
    String? otherId;
    if (!isGroup) {
      final List<dynamic> memberIds = data['members'] ?? [];
      otherId = memberIds.firstWhere((id) => id != currentUserId, orElse: () => '') as String?;
    }

    return ChatRoom(
      id: doc.id,
      isGroup: isGroup,
      members: List<String>.from(data['members'] ?? []),
      lastMessage: lastMessage,
      groupName: data['groupName'],
      groupAvatarUrl: data['groupAvatarUrl'],
      createdBy: data['createdBy'],
      createdAt: data['createdAt'],
      otherUserId: otherId,
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }
}