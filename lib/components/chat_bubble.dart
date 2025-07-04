import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final bool isRead;
  final bool isEdited;
  final void Function()? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.isRead,
    required this.isEdited,
    this.onLongPress,
  });

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

    return GestureDetector(
      onLongPress: isCurrentUser && !isDeleted ? onLongPress : null,
      child: Container(
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.green[400] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        margin: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 8),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          alignment: WrapAlignment.end,
          spacing: 8.0,
          children: [
            Text(message, style: messageStyle),
            if (isEdited && !isDeleted)
              Text(
                "отредактировано",
                style: TextStyle(
                  fontSize: 10,
                  color: (isCurrentUser ? Colors.white : Colors.black).withOpacity(0.7),
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
    );
  }
}