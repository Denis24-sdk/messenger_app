import 'package:flutter/material.dart';
import 'package:messenger_flutter/providers/chat_provider.dart';
import 'package:messenger_flutter/screens/chat_screen.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:messenger_flutter/services/storage/storage_service.dart';
import 'package:provider/provider.dart';

class ChatScreenWrapper extends StatelessWidget {
  final String chatName;
  final bool isGroup;
  final String chatRoomId;
  final String? receiverID;
  final String? receiverEmail;

  const ChatScreenWrapper({
    super.key,
    required this.chatName,
    required this.isGroup,
    required this.chatRoomId,
    this.receiverID,
    this.receiverEmail,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatProvider(
        chatRoomId: chatRoomId,
        chatService: context.read<ChatService>(),
        storageService: context.read<StorageService>(),
      ),
      child: ChatScreen(
        chatName: chatName,
        isGroup: isGroup,
        receiverID: receiverID,
        receiverEmail: receiverEmail,
      ),
    );
  }
}