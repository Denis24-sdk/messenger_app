import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final String? replyToMessage;
  final String? replyToSender;
  final bool isCurrentUser;
  final bool isRead;
  final bool isEdited;
  final void Function()? onLongPress;
  final void Function()? onReply;

  const ChatBubble({
    super.key,
    required this.message,
    this.replyToMessage,
    this.replyToSender,
    required this.isCurrentUser,
    required this.isRead,
    required this.isEdited,
    this.onLongPress,
    this.onReply,
  });

  Widget _buildReplyWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Colors.white.withOpacity(0.2)
            : Colors.black.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 3,
                color: isCurrentUser ? Colors.white : Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    replyToSender ?? "...",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser ? Colors.white : Colors.green,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    replyToMessage ?? "...",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrentUser
                          ? Colors.white.withOpacity(0.9)
                          : Colors.black.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Icon? statusIcon;
    final bool isDeleted = message == "Сообщение удалено";
    if (isCurrentUser && !isDeleted) {
      statusIcon = Icon(
        isRead ? Icons.done_all : Icons.done,
        size: 16,
        color: isRead ? Colors.blue : Colors.grey[600],
      );
    }
    final messageStyle = TextStyle(
      color: isCurrentUser ? Colors.white : Colors.black,
      fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
    );

    final bubbleContent = GestureDetector(
      onLongPress:
      isCurrentUser && !isDeleted ? onLongPress : null,
      child: Container(
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.green[400] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyToMessage != null) _buildReplyWidget(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 8.0,
                children: [
                  Text(message, style: messageStyle),
                  if (isEdited && !isDeleted)
                    Text(
                      "отредактировано",
                      style: TextStyle(
                        fontSize: 10,
                        color: (isCurrentUser ? Colors.white : Colors.black)
                            .withOpacity(0.7),
                      ),
                    ),
                  if (statusIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: statusIcon,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Dismissible(
      key: key!,
      direction: DismissDirection.startToEnd,
      background: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.reply, color: Colors.grey),
      ),
      confirmDismiss: (direction) async {
        onReply?.call();
        return false;
      },
      child: bubbleContent,
    );
  }
}