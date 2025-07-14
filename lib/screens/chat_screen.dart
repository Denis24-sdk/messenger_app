import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:messenger_flutter/components/chat_bubble.dart';
import 'package:messenger_flutter/main.dart';
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
    context
        .read<ChatProvider>()
        .loadInitialData(widget.isGroup, widget.receiverID);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
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
    setState(
            () => _replyingTo = {'message': replyText, 'senderName': senderName});
  }

  void _cancelReply() {
    if (mounted) setState(() => _replyingTo = null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textSecondary,
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
            color: AppColors.card,
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear_chat') _confirmClearChat(context);
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'clear_chat',
                child: Text(
                  'Очистить чат',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
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
    if (widget.isGroup || widget.receiverID == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StreamBuilder<DocumentSnapshot>(
          stream: context.read<ChatService>().getUserStream(widget.receiverID!),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data?.data() == null) {
              return const AlertDialog(
                backgroundColor: AppColors.card,
                content: Center(
                    child: CircularProgressIndicator(color: AppColors.accent)),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final String? avatarUrl = userData['avatarUrl'];
            final String username = userData['username'] ?? widget.chatName;
            final String? bio = userData['bio'];
            final bool isOnline = userData['isOnline'] ?? false;
            final bool hasBio = bio != null && bio.isNotEmpty;

            return AlertDialog(
              backgroundColor: AppColors.card,
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.accentGray,
                        backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? Icon(Icons.person,
                            size: 50, color: AppColors.textSecondary)
                            : null,
                      ),
                      if (isOnline)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: AppColors.card, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    username,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasBio ? bio : 'Нет информации',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: hasBio
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmClearChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text("Очистить чат?",
              style: TextStyle(color: AppColors.textPrimary)),
          content: Text("Вся история сообщений будет удалена безвозвратно.",
              style: TextStyle(color: AppColors.textSecondary)),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text("Отмена",
                    style: TextStyle(color: AppColors.textSecondary))),
            TextButton(
              child: const Text("Очистить",
                  style: TextStyle(color: Colors.redAccent)),
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
        const CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.accentGray,
          child: Icon(Icons.group, color: AppColors.textSecondary, size: 22),
        ),
        const SizedBox(width: 12),
        Text(chatName,
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ]);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: context.read<ChatService>().getUserStream(receiverID!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return Text(chatName,
              style: TextStyle(color: AppColors.textPrimary));
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        bool isOnline = userData['isOnline'] ?? false;
        String statusText = isOnline ? "в сети" : "не в сети";
        Color statusColor =
        isOnline ? AppColors.accent : AppColors.textSecondary;
        String? avatarUrl = userData['avatarUrl'];

        return Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.accentGray,
              backgroundImage:
              avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Icon(Icons.person, size: 20, color: AppColors.textSecondary)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userData['username'] ?? chatName,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                Text(statusText,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        color: statusColor)),
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
      backgroundColor: AppColors.card,
      builder: (bottomSheetContext) => SafeArea(
        child: Wrap(children: <Widget>[
          if (message.type == 'text' && isCurrentUser)
            ListTile(
              leading: Icon(Icons.edit, color: AppColors.textSecondary),
              title: Text('Редактировать',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showEditDialog(context, message);
              },
            ),
          if (isCurrentUser)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text('Удалить',
                  style: TextStyle(color: Colors.redAccent)),
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
        backgroundColor: AppColors.card,
        title: Text("Редактировать сообщение",
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: editController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: "...",
            hintStyle: TextStyle(color: AppColors.textSecondary),
            border: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.accentGray)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.accent)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Отмена",
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              context
                  .read<ChatProvider>()
                  .editMessage(message.id!, editController.text);
              Navigator.pop(dialogContext);
            },
            child: Text("Сохранить", style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final authId = context.read<FirebaseAuth>().currentUser!.uid;
    final parentState = context.findAncestorStateOfType<_ChatScreenState>()!;

    if (chatProvider.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        chatProvider.markMessagesAsRead();
        if (_scrollController.hasClients &&
            chatProvider.messages.isNotEmpty &&
            chatProvider.messages.first.senderID == authId) {
          _scrollController.animateTo(0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        }
      }
    });

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chatProvider.messages.length,
      itemBuilder: (context, index) {
        final message = chatProvider.messages[index];
        return _buildMessageItem(
          context,
          message,
          isGroup: parentState.widget.isGroup,
          chatName: parentState.widget.chatName,
          authId: authId,
          userCache: chatProvider.userCache,
          key: ValueKey(message.id!),
        );
      },
    );
  }

  Widget _buildMessageItem(
      BuildContext context,
      Message message, {
        Key? key,
        required bool isGroup,
        required String chatName,
        required String authId,
        required Map<String, Map<String, dynamic>> userCache,
      }) {
    bool isCurrentUser = message.senderID == authId;
    String senderName = "Вы";

    if (!isCurrentUser && isGroup) {
      senderName =
      (userCache[message.senderID]?['username'] ?? message.senderEmail);
    }

    if (message.senderID == 'system') {
      return Center(
          key: key,
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(message.message,
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic))));
    }

    return ChatBubble(
      key: key,
      message: message.message,
      messageType: message.type,
      senderName: isGroup && !isCurrentUser ? senderName : null,
      replyToMessage: message.replyToMessage,
      replyToSender: message.replyToSender,
      isCurrentUser: isCurrentUser,
      timestamp: message.timestamp,
      isRead: message.isRead,
      isEdited: message.isEdited,
      aspectRatio: message.aspectRatio,
      onLongPress: () => _showMessageOptions(context, message),
      onReply: () => widget.onReply(message),
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
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic))
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
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      color: AppColors.card,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            color: AppColors.accent,
            margin: const EdgeInsets.only(right: 12),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ответ для ${replyingTo['senderName']}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(replyingTo['message'],
                    style: TextStyle(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded,
                size: 20, color: AppColors.textSecondary),
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
    return Container(
      padding: EdgeInsets.fromLTRB(
          4, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
              icon: Icon(Icons.add_photo_alternate_outlined,
                  color: AppColors.textSecondary, size: 26),
              onPressed: onAttach),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: null,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Сообщение...",
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 40,
            child: FilledButton(
              onPressed: onSend,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.arrow_upward, color: AppColors.background),
            ),
          ),
        ],
      ),
    );
  }
}