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
  Map<String, dynamic>? _replyingTo;

  @override
  void initState() {
    super.initState();
    List<String> ids = [_auth.currentUser!.uid, widget.receiverID];
    ids.sort();
    _chatRoomID = ids.join('_');
    _messageController.addListener(_handleTyping);
  }

  void _handleTyping() {
    if (_typingTimer == null || !_typingTimer!.isActive) {
      _chatService.updateTypingStatus(_chatRoomID, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      _chatService.updateTypingStatus(_chatRoomID, false);
    });
  }

  void _setReplyTo(Map<String, dynamic> messageData, String senderName) {
    setState(() {
      _replyingTo = {
        'message': messageData['message'],
        'senderName': senderName,
      };
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      _typingTimer?.cancel();
      _chatService.updateTypingStatus(_chatRoomID, false);

      final replyData = _replyingTo;
      _cancelReply();

      await _chatService.sendMessage(
        widget.receiverID,
        _messageController.text,
        replyToMessage: replyData?['message'],
        replyToSenderName: replyData?['senderName'],
      );
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
    if (_chatRoomID.isNotEmpty) {
      _chatService.updateTypingStatus(_chatRoomID, false);
    }
    super.dispose();
  }

  void _showEditDialog(String messageID, String currentMessage) {
    final TextEditingController editController = TextEditingController(text: currentMessage);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Редактировать сообщение"),
        content: TextField(controller: editController, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
          TextButton(
            onPressed: () {
              _chatService.editMessage(_chatRoomID, messageID, editController.text);
              Navigator.pop(context);
            },
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(String messageID, String message) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Редактировать'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(messageID, message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Удалить'),
                onTap: () {
                  _chatService.deleteMessage(_chatRoomID, messageID);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReplyContext() {
    if (_replyingTo == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ответ на: ${_replyingTo!['senderName']}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                Text(_replyingTo!['message'], maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close),
            onPressed: _cancelReply,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _chatService.getUserStream(widget.receiverID),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Text(widget.receiverEmail);
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            bool isOnline = userData['isOnline'] ?? false;
            String statusText = isOnline ? "в сети" : "не в сети";
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.receiverEmail),
                Text(statusText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildTypingIndicator(),
          _buildReplyContext(),
          _buildUserInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(_auth.currentUser!.uid, widget.receiverID),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Ошибка загрузки");
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _chatService.markMessagesAsRead(_chatRoomID, widget.receiverID);
            scrollDown();
          }
        });
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
      stream: _chatService.getChatRoomStream(_chatRoomID),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) return const SizedBox.shrink();
        var data = snapshot.data!.data() as Map<String, dynamic>;
        var typingStatus = data['typingStatus'] as Map<String, dynamic>?;
        if (typingStatus != null && typingStatus[widget.receiverID] == true) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(children: [Text("Печатает...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))]),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isCurrentUser = data['senderID'] == _auth.currentUser!.uid;
    bool isRead = data['isRead'] ?? false;
    bool isEdited = data['isEdited'] ?? false;
    final String senderName = isCurrentUser ? "Вы" : widget.receiverEmail;

    // Контейнер для позиционирования и вертикальных отступов между сообщениями.
    return Container(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: ChatBubble(
        key: ValueKey(doc.id),
        message: data["message"],
        replyToMessage: data["replyToMessage"],
        replyToSender: data["replyToSender"],
        isCurrentUser: isCurrentUser,
        isRead: isRead,
        isEdited: isEdited,
        onLongPress: () => _showMessageOptions(doc.id, data["message"]),
        onReply: () => _setReplyTo(data, senderName),
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