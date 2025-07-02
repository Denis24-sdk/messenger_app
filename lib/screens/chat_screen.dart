// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:messenger_flutter/components/my_textfield.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';

class ChatScreen extends StatelessWidget {
  final String receiverEmail;
  final String receiverID;

  ChatScreen({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
  });

  final TextEditingController _messageController = TextEditingController();

  // Создаем экземпляр сервиса
  final ChatService _chatService = ChatService();

  // Отправка сообщения
  void sendMessage() async {
    // Отправляем сообщение, только если поле не пустое
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(receiverID, _messageController.text);

      // Очищаем поле ввода после отправки
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(receiverEmail), // В заголовке будет email собеседника (пока что)
      ),
      body: Column(
        children: [
          // Область для сообщений (пока пустая)
          Expanded(
            child: Container(),
          ),

          // Поле ввода и кнопка
          _buildUserInput(),
        ],
      ),
    );
  }

  // Виджет для поля ввода
  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Поле для текста
          Expanded(
            child: MyTextField(
              controller: _messageController,
              hintText: "Введите сообщение...",
              obscureText: false,
            ),
          ),

          // Кнопка отправки
          IconButton(
            onPressed: sendMessage,
            icon: const Icon(Icons.arrow_upward),
          ),
        ],
      ),
    );
  }
}