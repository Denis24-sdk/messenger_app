import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger_flutter/components/chat_bubble.dart';
import 'package:messenger_flutter/components/my_textfield.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:messenger_flutter/services/storage/storage_service.dart';
import 'package:photo_view/photo_view.dart';

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
  Map<String, dynamic>? _receiverData; // Данные о собеседнике

  @override
  void initState() {
    super.initState();
    List<String> ids = [_auth.currentUser!.uid, widget.receiverID];
    ids.sort();
    _chatRoomID = ids.join('_');
    _messageController.addListener(_handleTyping);
    _loadReceiverData(); // Загружаем данные о собеседнике
  }

  // Загрузка данных о собеседнике
  Future<void> _loadReceiverData() async {
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.receiverID)
        .get();

    if (doc.exists) {
      setState(() {
        _receiverData = doc.data()!;
      });
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
    _scrollController.dispose();
    super.dispose();
  }

  // Открытие профиля собеседника
  void _openReceiverProfile(BuildContext context) {
    if (_receiverData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Профиль"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _openFullScreenAvatar(context, _receiverData!['avatarUrl']),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _receiverData!['avatarUrl'] != null
                      ? NetworkImage(_receiverData!['avatarUrl'])
                      : null,
                  child: _receiverData!['avatarUrl'] == null
                      ? Icon(Icons.person, size: 50, color: Colors.grey.shade800)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _receiverData!['username'] ?? widget.receiverEmail,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.receiverEmail,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_receiverData!['bio'] != null && _receiverData!['bio'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    _receiverData!['bio'],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                _receiverData!['isOnline'] == true ? "В сети" : "Не в сети",
                style: TextStyle(
                  color: _receiverData!['isOnline'] == true ? Colors.green : Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Закрыть"),
          ),
        ],
      ),
    );
  }

  // Открытие аватара на весь экран
  void _openFullScreenAvatar(BuildContext context, String? imageUrl) {
    if (imageUrl == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: PhotoView(
                  imageProvider: NetworkImage(imageUrl),
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                  loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white, size: 60),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        title: GestureDetector( // Добавляем обработчик нажатия на весь AppBar
          onTap: () => _openReceiverProfile(context),
          child: StreamBuilder<DocumentSnapshot>(
            stream: _chatService.getUserStream(widget.receiverID),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data?.data() == null) {
                return Text(widget.receiverEmail);
              }
              var userData = snapshot.data!.data() as Map<String, dynamic>;
              bool isOnline = userData['isOnline'] ?? false;
              String statusText = isOnline ? "в сети" : "не в сети";
              String? avatarUrl = userData['avatarUrl'];

              // Сохраняем данные о собеседнике
              if (_receiverData == null) {
                _receiverData = userData;
              }

              return Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Icon(Icons.person, size: 20, color: Colors.grey.shade800)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userData['username'] ?? widget.receiverEmail),
                      Text(statusText,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
                    ],
                  ),
                ],
              );
            },
          ),
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