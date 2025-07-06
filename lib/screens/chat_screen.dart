import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:messenger_flutter/components/chat_bubble.dart';
import 'package:messenger_flutter/components/my_textfield.dart';
import 'package:messenger_flutter/models/message.dart';
import 'package:messenger_flutter/providers/chat_provider.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatName;
  final bool isGroup;
  final String? receiverID;
  final String? receiverEmail;

  const ChatScreen({
    super.key,
    required this.chatName,
    required this.isGroup,
    this.receiverID,
    this.receiverEmail,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  Map<String, dynamic>? _replyingTo;

  @override
  void initState() {
    super.initState();
    context.read<ChatProvider>().loadInitialData(widget.isGroup, widget.receiverID);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final provider = context.read<ChatProvider>();
    provider.sendMessage(
      _messageController.text,
      widget.receiverID,
      replyToMessage: _replyingTo?['message'],
      replyToSenderName: _replyingTo?['senderName'],
    );
    _messageController.clear();
    _cancelReply();
  }

  void _sendImage() {
    _cancelReply();
    context.read<ChatProvider>().sendImage(widget.receiverID);
  }

  void _setReplyTo(Message message) {
    final chatProvider = context.read<ChatProvider>();
    final authId = context.read<FirebaseAuth>().currentUser!.uid;
    bool isCurrentUser = message.senderID == authId;
    String senderName = "Вы";
    if (!isCurrentUser) {
      senderName = widget.isGroup
          ? (chatProvider.userCache[message.senderID]?['username'] ??
          message.senderEmail)
          : widget.chatName;
    }

    final replyText =
    (message.type).startsWith('image') ? '📷 Изображение' : message.message;
    setState(() => _replyingTo = {'message': replyText, 'senderName': senderName});
  }

  void _cancelReply() {
    if (mounted) setState(() => _replyingTo = null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _openReceiverProfile(context),
          child: _AppBarTitle(
            isGroup: widget.isGroup,
            chatName: widget.chatName,
            receiverID: widget.receiverID,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_chat') _confirmClearChat(context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                  value: 'clear_chat', child: Text('Очистить чат')),
            ],
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(child: _MessageList(onReply: _setReplyTo)),
          const _TypingIndicator(),
          if (_replyingTo != null)
            _ReplyContext(
              replyingTo: _replyingTo!,
              onCancel: _cancelReply,
            ),
          _UserInput(
            controller: _messageController,
            onSend: _sendMessage,
            onAttach: _sendImage,
          ),
        ],
      ),
    );
  }

  void _openReceiverProfile(BuildContext context) {
    if (widget.isGroup) return;
    final receiverData = context.read<ChatProvider>().receiverData;
    if (receiverData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: receiverData['avatarUrl'] != null
                  ? NetworkImage(receiverData['avatarUrl'])
                  : null,
              child: receiverData['avatarUrl'] == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(receiverData['username'] ?? widget.chatName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.receiverEmail ?? '',
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _confirmClearChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Очистить чат?"),
          content: const Text("Вся история сообщений будет удалена."),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("Отмена")),
            TextButton(
              child: const Text("Очистить", style: TextStyle(color: Colors.red)),
              onPressed: () {
                context.read<ChatProvider>().clearChatHistory();
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  final bool isGroup;
  final String chatName;
  final String? receiverID;

  const _AppBarTitle({
    required this.isGroup,
    required this.chatName,
    this.receiverID,
  });

  @override
  Widget build(BuildContext context) {
    if (isGroup) {
      return Row(children: [
        const CircleAvatar(radius: 20, child: Icon(Icons.group)),
        const SizedBox(width: 12),
        Text(chatName),
      ]);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: context.read<ChatService>().getUserStream(receiverID!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return Text(chatName);
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        bool isOnline = userData['isOnline'] ?? false;
        String statusText = isOnline ? "в сети" : "не в сети";
        String? avatarUrl = userData['avatarUrl'];

        return Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
              avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, size: 20, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userData['username'] ?? chatName),
                Text(statusText,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MessageList extends StatefulWidget {
  final Function(Message) onReply;
  const _MessageList({required this.onReply});

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showMessageOptions(BuildContext context, Message message) {
    final provider = context.read<ChatProvider>();
    final authId = context.read<FirebaseAuth>().currentUser!.uid;
    bool isCurrentUser = message.senderID == authId;

    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Wrap(children: <Widget>[
          if (message.type == 'text' && isCurrentUser)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Редактировать'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showEditDialog(context, message);
              },
            ),
          if (isCurrentUser)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                provider.deleteMessage(message.id!);
              },
            ),
        ]),
      ),
    );
  }


  void _showEditDialog(BuildContext context, Message message) {
    final editController = TextEditingController(text: message.message);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Редактировать"),
        content: TextField(controller: editController, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Отмена")),
          TextButton(
            onPressed: () {
              context
                  .read<ChatProvider>()
                  .editMessage(message.id!, editController.text);
              Navigator.pop(dialogContext);
            },
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            provider.markMessagesAsRead();
            if (_scrollController.hasClients) {
              if (provider.messages.isNotEmpty &&
                  provider.messages.first.senderID == context.read<FirebaseAuth>().currentUser!.uid) {
                _scrollController.animateTo(0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut);
              }
            }
          }
        });

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(8),
          itemCount: provider.messages.length,
          itemBuilder: (context, index) {
            final message = provider.messages[index];
            return _buildMessageItem(context, message, key: ValueKey(message.id!));
          },
        );
      },
    );
  }

  Widget _buildMessageItem(BuildContext context, Message message, {Key? key}) {
    final chatProvider = context.read<ChatProvider>();
    final authId = context.read<FirebaseAuth>().currentUser!.uid;
    bool isCurrentUser = message.senderID == authId;
    String senderName = "Вы";
    final parentState = context.findAncestorStateOfType<_ChatScreenState>()!;

    if (!isCurrentUser) {
      senderName = parentState.widget.isGroup
          ? (chatProvider.userCache[message.senderID]?['username'] ??
          message.senderEmail)
          : parentState.widget.chatName;
    }

    if (message.senderID == 'system') {
      return Center(
        key: key,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(message.message,
              style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
        ),
      );
    }

    return RepaintBoundary(
      child: ChatBubble(
        key: key,
        message: message.message,
        messageType: message.type,
        senderName:
        parentState.widget.isGroup && !isCurrentUser ? senderName : null,
        replyToMessage: message.replyToMessage,
        replyToSender: message.replyToSender,
        isCurrentUser: isCurrentUser,
        isRead: message.isRead,
        isEdited: message.isEdited,
        onLongPress: () => _showMessageOptions(context, message),
        onReply: () => widget.onReply(message),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final chatService = context.read<ChatService>();
    final authId = context.read<FirebaseAuth>().currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: chatService.getChatRoomStream(chatProvider.chatRoomId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const SizedBox.shrink();
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        var typingStatus = data['typingStatus'] as Map<String, dynamic>? ?? {};
        typingStatus
            .removeWhere((key, value) => key == authId || value == false);
        if (typingStatus.isEmpty) return const SizedBox.shrink();

        final typingUserID = typingStatus.keys.first;
        final typingUserName =
            chatProvider.userCache[typingUserID]?['username'] ?? 'Кто-то';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(children: [
            Text("$typingUserName печатает...",
                style: TextStyle(
                    color: Colors.grey.shade600, fontStyle: FontStyle.italic))
          ]),
        );
      },
    );
  }
}

class _ReplyContext extends StatelessWidget {
  final Map<String, dynamic> replyingTo;
  final VoidCallback onCancel;

  const _ReplyContext({required this.replyingTo, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1)),
      child: Row(
        children: [
          Icon(Icons.reply, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ответ на: ${replyingTo['senderName']}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700)),
                Text(replyingTo['message'],
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 20),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _UserInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  const _UserInput({
    required this.controller,
    required this.onSend,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              onPressed: onAttach),
          Expanded(
              child: MyTextField(
                controller: controller,
                hintText: "Сообщение...",
                obscureText: false,
              )),
          Container(
            decoration:
            const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            margin: const EdgeInsets.only(left: 8),
            child: IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.arrow_upward, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}