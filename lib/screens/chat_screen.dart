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
  final String chatName;
  final bool isGroup;
  final String chatRoomId;
  final String? receiverID;
  final String? receiverEmail;

  const ChatScreen({
    super.key,
    required this.chatName,
    required this.isGroup,
    required this.chatRoomId,
    this.receiverID,
    this.receiverEmail,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final StorageService _storageService = StorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, Map<String, dynamic>> _userCache = {};
  Map<String, dynamic>? _replyingTo;
  Timer? _typingTimer;
  Map<String, dynamic>? _receiverData;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleTyping);
    if (widget.isGroup) {
      _loadGroupMembersData();
    } else {
      _loadReceiverData();
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTyping);
    _messageController.dispose();
    _typingTimer?.cancel();
    if (mounted) {
      _chatService.updateTypingStatus(widget.chatRoomId, false);
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReceiverData() async {
    if (widget.receiverID == null) return;
    final doc = await FirebaseFirestore.instance.collection('Users').doc(widget.receiverID).get();
    if (doc.exists && mounted) {
      setState(() => _receiverData = doc.data());
    }
  }

  Future<void> _loadGroupMembersData() async {
    final chatRoomDoc = await FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId).get();
    if (!mounted || !chatRoomDoc.exists || chatRoomDoc.data()!['members'] == null) return;

    List<String> memberIds = List<String>.from(chatRoomDoc.data()!['members']);
    for (String id in memberIds) {
      if (!_userCache.containsKey(id)) {
        final userDoc = await FirebaseFirestore.instance.collection('Users').doc(id).get();
        if (userDoc.exists) {
          if (!mounted) return;
          setState(() => _userCache[id] = userDoc.data()!);
        }
      }
    }
  }

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    _typingTimer?.cancel();
    _chatService.updateTypingStatus(widget.chatRoomId, false);

    final replyData = _replyingTo;
    _cancelReply();

    await _chatService.sendMessage(
      widget.chatRoomId,
      _messageController.text.trim(),
      receiverID: widget.receiverID,
      replyToMessage: replyData?['message'],
      replyToSenderName: replyData?['senderName'],
    );
    _messageController.clear();
  }

  void _sendImage() async {
    File? imageFile = await _storageService.pickImage();
    if (imageFile == null) return;
    _cancelReply();

    DocumentReference messageRef = await _chatService.sendLocalImageMessage(
        widget.chatRoomId, widget.receiverID ?? '', imageFile);

    Map<String, String>? uploadResult = await _storageService.uploadFile(imageFile);
    if (uploadResult != null) {
      await _chatService.updateImageMessageUrl(messageRef, uploadResult['url']!, uploadResult['fileId']!);
    } else {
      await messageRef.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось загрузить изображение.')));
      }
    }
  }

  void _handleTyping() {
    if (!mounted) return;
    _typingTimer?.cancel();
    if (_messageController.text.isNotEmpty) {
      _chatService.updateTypingStatus(widget.chatRoomId, true);
    }
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) _chatService.updateTypingStatus(widget.chatRoomId, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_chat') _confirmClearChat(context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(value: 'clear_chat', child: Text('Очистить чат')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildTypingIndicator(),
          if (_replyingTo != null) _buildReplyContext(),
          _buildUserInput(),
        ],
      ),
    );
  }

  Widget _buildReplyContext() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1)),
      child: Row(
        children: [
          Icon(Icons.reply, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ответ на: ${_replyingTo!['senderName']}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
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

  Widget _buildAppBarTitle() {
    if (widget.isGroup) {
      return Row(children: [
        const CircleAvatar(radius: 20, child: Icon(Icons.group)),
        const SizedBox(width: 12),
        Text(widget.chatName),
      ]);
    }

    return GestureDetector(
      onTap: () => _openReceiverProfile(context),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _chatService.getUserStream(widget.receiverID!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Text(widget.chatName);
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          if (_receiverData == null) _receiverData = userData;

          bool isOnline = userData['isOnline'] ?? false;
          String statusText = isOnline ? "в сети" : "не в сети";
          String? avatarUrl = userData['avatarUrl'];

          return Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? Icon(Icons.person, size: 20, color: Colors.grey.shade800) : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userData['username'] ?? widget.chatName),
                  Text(statusText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(widget.chatRoomId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Ошибка загрузки"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _chatService.markMessagesAsRead(widget.chatRoomId, _auth.currentUser!.uid);
        });

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) => _buildMessageItem(snapshot.data!.docs[index]),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    if (data['senderID'] == 'system') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(data['message'], style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
        ),
      );
    }

    bool isCurrentUser = data['senderID'] == _auth.currentUser!.uid;
    String senderName = "Вы";
    if (!isCurrentUser) {
      senderName = widget.isGroup
          ? (_userCache[data['senderID']]?['username'] ?? data['senderEmail'] ?? 'Участник')
          : widget.chatName;
    }

    return ChatBubble(
      key: ValueKey(doc.id),
      message: data["message"],
      messageType: data["type"] ?? 'text',
      senderName: widget.isGroup && !isCurrentUser ? senderName : null,
      replyToMessage: data["replyToMessage"],
      replyToSender: data["replyToSender"],
      isCurrentUser: isCurrentUser,
      isRead: data['isRead'] ?? false,
      isEdited: data['isEdited'] ?? false,
      onLongPress: () => _showMessageOptions(doc.id, data),
      onReply: () => _setReplyTo(data, senderName),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _chatService.getChatRoomStream(widget.chatRoomId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) return const SizedBox.shrink();

        var data = snapshot.data!.data() as Map<String, dynamic>;
        var typingStatus = data['typingStatus'] as Map<String, dynamic>? ?? {};
        typingStatus.removeWhere((key, value) => key == _auth.currentUser!.uid || value == false);
        if (typingStatus.isEmpty) return const SizedBox.shrink();

        String typingUserName = "Собеседник";
        if (widget.isGroup) {
          final typingUserID = typingStatus.keys.first;
          typingUserName = _userCache[typingUserID]?['username'] ?? 'Кто-то';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(children: [
            Text("$typingUserName печатает...", style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic))
          ]),
        );
      },
    );
  }

  Widget _buildUserInput() {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.add_photo_alternate_outlined), onPressed: _sendImage),
          Expanded(child: MyTextField(
            controller: _messageController,
            hintText: "Сообщение...",
            obscureText: false,
          )),
          Container(
            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            margin: const EdgeInsets.only(left: 8),
            child: IconButton(onPressed: sendMessage, icon: const Icon(Icons.arrow_upward, color: Colors.white)),
          ),
        ],
      ),
    );
  }


  // диалоговые окна

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
                  backgroundImage: _receiverData!['avatarUrl'] != null ? NetworkImage(_receiverData!['avatarUrl']) : null,
                  child: _receiverData!['avatarUrl'] == null ? Icon(Icons.person, size: 50, color: Colors.grey.shade800) : null,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _receiverData!['username'] ?? widget.chatName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.receiverEmail ?? '',
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Закрыть")),
        ],
      ),
    );
  }

  void _openFullScreenAvatar(BuildContext context, String? imageUrl) {
    if (imageUrl == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoView(
            imageProvider: NetworkImage(imageUrl),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    )));
  }

  void _setReplyTo(Map<String, dynamic> messageData, String senderName) {
    final message = (messageData['type'] ?? 'text').startsWith('image')
        ? '📷 Изображение'
        : messageData['message'];
    setState(() => _replyingTo = {'message': message, 'senderName': senderName});
  }

  void _cancelReply() => setState(() => _replyingTo = null);


  void _showMessageOptions(String messageID, Map<String, dynamic> data) {
    bool isCurrentUser = data['senderID'] == _auth.currentUser!.uid;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: <Widget>[
          if (data['type'] == 'text' && isCurrentUser)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Редактировать'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(messageID, data['message']);
              },
            ),
          if (isCurrentUser)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _chatService.deleteMessage(widget.chatRoomId, messageID);
              },
            ),
        ]),
      ),
    );
  }

  void _showEditDialog(String messageID, String currentMessage) {
    final editController = TextEditingController(text: currentMessage);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Редактировать"),
        content: TextField(controller: editController, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
          TextButton(
            onPressed: () {
              _chatService.editMessage(widget.chatRoomId, messageID, editController.text);
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
      builder: (context) => AlertDialog(
        title: const Text("Очистить чат?"),
        content: const Text("Вся история сообщений будет удалена."),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Отмена")),
          TextButton(
            child: const Text("Очистить", style: TextStyle(color: Colors.red)),
            onPressed: () {
              _chatService.clearChatHistory(widget.chatRoomId);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
