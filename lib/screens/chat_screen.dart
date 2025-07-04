import 'dart:async';
import 'package:flutter/material.dart';
import 'package:messenger_flutter/components/my_textfield.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:messenger_flutter/components/chat_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;

  const ChatScreen({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  Timer? _typingTimer;
  String _chatRoomID = "";

  @override
  void initState() {
    super.initState();
    List<String> ids = [_auth.currentUser!.uid, widget.receiverID];
    ids.sort();
    _chatRoomID = ids.join('_');

    // Как только заходим на экран, помечаем сообщения собеседника как прочитанные
    _chatService.markMessagesAsRead(_chatRoomID, widget.receiverID);

    _messageController.addListener(_handleTyping);
  }

  // Логика индикатора набора текста
  void _handleTyping() {
    if (_typingTimer == null || !_typingTimer!.isActive) {
      _chatService.updateTypingStatus(_chatRoomID, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      _chatService.updateTypingStatus(_chatRoomID, false);
    });
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      _typingTimer?.cancel();
      _chatService.updateTypingStatus(_chatRoomID, false);

      await _chatService.sendMessage(widget.receiverID, _messageController.text);
      _messageController.clear();
    }
  }

  void scrollDown() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTyping);
    _messageController.dispose();
    _typingTimer?.cancel();
    // Отправляем финальный статус "не печатает" при выходе с экрана
    _chatService.updateTypingStatus(_chatRoomID, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title в StreamBuilder, чтобы он обновлялся
        title: StreamBuilder<DocumentSnapshot>(
          stream: _chatService.getUserStream(widget.receiverID),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Text(widget.receiverEmail);

            var userData = snapshot.data!.data() as Map<String, dynamic>;
            bool isOnline = userData['isOnline'] ?? false;
            String statusText;

            if (isOnline) {
              statusText = "в сети";
            } else {
              Timestamp? lastSeen = userData['last_seen'];
              statusText = "не в сети";
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.receiverEmail),
                Text(
                  statusText,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildTypingIndicator(),
          _buildUserInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(_auth.currentUser!.uid, widget.receiverID),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Ошибка загрузки");
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollDown());
        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          children: snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<DocumentSnapshot>(
      // Слушаем изменения в документе чата
      stream: _chatService.getChatRoomStream(_chatRoomID),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.data() == null) {
          return const SizedBox.shrink();
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        var typingStatus = data['typingStatus'] as Map<String, dynamic>?;

        // Проверяем, печатает ли собеседник
        if (typingStatus != null && typingStatus[widget.receiverID] == true) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Text(
                  "Печатает...",
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          );
        }
        // Если не печатает, возвращаем пустой виджет
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isCurrentUser = data['senderID'] == _auth.currentUser!.uid;

    // Получаем статус прочтения (если поля нет, считаем что не прочитано)
    bool isRead = data['isRead'] ?? false;

    return Container(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ChatBubble(
        message: data["message"],
        isCurrentUser: isCurrentUser,
        isRead: isRead,
      ),
    );
  }


  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 8, right: 8, top: 8),
      child: Row(
        children: [
          Expanded(
            child: MyTextField(
              controller: _messageController,
              hintText: "Сообщение...",
              obscureText: false,
            ),
          ),
          Container(
            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            margin: const EdgeInsets.only(left: 8),
            child: IconButton(
              onPressed: sendMessage,
              icon: const Icon(Icons.arrow_upward, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}