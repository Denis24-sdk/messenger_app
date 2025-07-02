import 'package:flutter/material.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_flutter/screens/chat_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // МЕТОД ВЫХОДА
  void signOut(BuildContext context) async {

    final authService = ChatService();
    try {
      await authService.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Главная"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
        actions: [
          // Кнопка выхода
          IconButton(
            onPressed: () => signOut(context),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: _buildUserList(),
    );
  }

  // Строим список пользователей
  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatService.getUsersStream(),
      builder: (context, snapshot) {
        // Обработка ошибок
        if (snapshot.hasError) {
          return const Text("Ошибка");
        }

        // Загрузка
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Загрузка...");
        }

        // Получаем список пользователей и строим ListView
        return ListView(
          children: snapshot.data!
              .map<Widget>((userData) => _buildUserListItem(userData, context))
              .toList(),
        );
      },
    );
  }

  // Строим отдельный элемент списка
  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    // отфильтровываем текущего пользователя
    if (userData["email"] != _auth.currentUser!.email) {
      return ListTile(

        leading: const CircleAvatar(
          // Пока что просто иконка, но это место для будущей аватарке
          child: Icon(Icons.person),
        ),

        // Используем оператор '??', чтобы показать email, если логина вдруг нет (для старых аккаунтов)  (для отладки, временно)
        title: Text(userData["username"] ?? userData["email"]),
        onTap: () {
          // перейти в чат при нажатии
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                receiverEmail: userData["username"] ?? userData["email"],
                receiverID: userData["uid"],
              ),
            ),
          );
        },
      );
    } else {
      return Container();
    }
  }
}