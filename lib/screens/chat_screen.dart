import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger_flutter/components/chat_bubble.dart';
import 'package:messenger_flutter/components/my_textfield.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:messenger_flutter/services/storage/storage_service.dart';

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
  final StorageService _storageService = StorageService();
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

  @override
  void dispose() {
    _messageController.removeListener(_handleTyping);
    _messageController.dispose();
    _typingTimer?.cancel();
    if (_chatRoomID.isNotEmpty) {
      _chatService.updateTypingStatus(_chatRoomID, false);
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _sendImage() async {
    File? imageFile = await _storageService.pickImage();
    if (imageFile == null) return;

    _cancelReply();

    DocumentReference messageRef = await _chatService.sendLocalImageMessage(widget.receiverID, imageFile);

    Map<String, String>? uploadResult = await _storageService.uploadFile(imageFile);

    if (uploadResult != null) {
      String imageUrl = uploadResult['url']!;
      String fileId = uploadResult['fileId']!;
      await _chatService.updateImageMessageUrl(messageRef, imageUrl, fileId);
    } else {
      await messageRef.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось загрузить изображение.')));
      }
    }
  }


  void sendMessage() async {
    if (_messageController.text.isEmpty) return;

    _typingTimer?.cancel();
    _chatService.updateTypingStatus(_chatRoomID, false);

    final replyData = _replyingTo;
    _cancelReply();

    final String messageText = _messageController.text;
    _messageController.clear();

    await _chatService.sendMessage(
      widget.receiverID,
      messageText,
      replyToMessage: replyData?['message'],
      replyToSenderName: replyData?['senderName'],
    );
  }

  void _handleTyping() {
    if (_typingTimer?.isActive ?? false) _typingTimer!.cancel();
    if (_messageController.text.isNotEmpty) {
      _chatService.updateTypingStatus(_chatRoomID, true);
    }
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      _chatService.updateTypingStatus(_chatRoomID, false);
    });
  }

  void _setReplyTo(Map<String, dynamic> messageData, String senderName) {
    final message = (messageData['type'] ?? 'text').startsWith('image')
        ? '📷 Изображение'
        : messageData['message'];

    setState(() {
      _replyingTo = {
        'message': message,
        'senderName': senderName,
      };
    });
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  void _showMessageOptions(String messageID, Map<String, dynamic> data) {
    final String message = data['message'];
    final String type = data['type'] ?? 'text';
    bool isCurrentUser = data['senderID'] == _auth.currentUser!.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              if (type == 'text' && isCurrentUser)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Редактировать'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(messageID, message);
                  },
                ),
              if (isCurrentUser)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Удалить', style: TextStyle(color: Colors.red)),
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

  void _confirmClearChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Очистить чат?"),
          content: const Text("Вся история сообщений будет удалена."),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Отмена")),
            TextButton(
              child: const Text("Очистить", style: TextStyle(color: Colors.red)),
              onPressed: () {
                _chatService.clearChatHistory(_chatRoomID);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _chatService.getUserStream(widget.receiverID),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data?.data() == null) {
              return Text(widget.receiverEmail);
            }
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            bool isOnline = userData['isOnline'] ?? false;
            String statusText = isOnline ? "в сети" : "не в сети";
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userData['username'] ?? widget.receiverEmail),
                Text(statusText,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            );
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_chat') _confirmClearChat(context);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                  value: 'clear_chat', child: Text('Очистить чат')),
            ],
          ),
        ],
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
        if (snapshot.hasError) return const Center(child: Text("Ошибка загрузки"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _chatService.markMessagesAsRead(_chatRoomID, widget.receiverID);
        });

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildMessageItem(doc);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isCurrentUser = data['senderID'] == _auth.currentUser!.uid;
    final String senderName = isCurrentUser ? "Вы" : widget.receiverEmail;

    return Container(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ChatBubble(
        key: ValueKey(doc.id),
        message: data["message"],
        messageType: data["type"] ?? 'text',
        replyToMessage: data["replyToMessage"],
        replyToSender: data["replyToSender"],
        isCurrentUser: isCurrentUser,
        isRead: data['isRead'] ?? false,
        isEdited: data['isEdited'] ?? false,
        onLongPress: () => _showMessageOptions(doc.id, data),
        onReply: () => _setReplyTo(data, senderName),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _chatService.getChatRoomStream(_chatRoomID),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) return const SizedBox.shrink();
        var data = snapshot.data!.data() as Map<String, dynamic>;
        var typingStatus = data['typingStatus'] as Map<String, dynamic>? ?? {};
        if (typingStatus[widget.receiverID] == true) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(children: [
              Text("Печатает...",
                  style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic))
            ]),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildReplyContext() {
    if (_replyingTo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1)),
      child: Row(
        children: [
          const Icon(Icons.reply, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ответ на: ${_replyingTo!['senderName']}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Text(_replyingTo!['message'], maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 20),
            onPressed: _cancelReply,
          ),
        ],
      ),
    );
  }

  Widget _buildUserInput() {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: _sendImage,
          ),
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