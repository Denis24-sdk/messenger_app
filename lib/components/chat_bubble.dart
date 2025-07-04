import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final bool isRead;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    // Определяем иконку статуса
    Icon? statusIcon;
    if (isCurrentUser) {
      statusIcon = Icon(
        isRead ? Icons.done_all : Icons.done,
        size: 16,
        color: isRead ? Colors.blue : Colors.grey[600],
      );
    }

    return Container(
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
          Text(
            message,
            style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),
          ),
          if (statusIcon != null) // Показываем иконку, только если это сообщение текущего пользователя
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: statusIcon,
            ),
        ],
      ),
    );
  }
}
