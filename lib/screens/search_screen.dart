import 'package:flutter/material.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_flutter/screens/chat_screen.dart';
import 'package:messenger_flutter/components/my_textfield.dart';


class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Обновляем состояние при каждом изменении в поле поиска.
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    // Очищаем контроллер, чтобы избежать утечек памяти.
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Найти пользователя"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: MyTextField(
              controller: _searchController,
              hintText: "Поиск...",
              obscureText: false,
            ),
          ),
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Ошибка"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text("Загрузка..."));
        }

        // Фильтруем полный список пользователей на основе поискового запроса.
        var allUsers = snapshot.data!;
        List<Map<String, dynamic>> filteredUsers = allUsers.where((user) {
          if (user['email'] == _auth.currentUser!.email) {
            return false;
          }

          String username = (user["username"] ?? "").toLowerCase();
          String email = (user["email"] ?? "").toLowerCase();
          String query = _searchQuery.toLowerCase();

          return username.contains(query) || email.contains(query);
        }).toList();

        if (filteredUsers.isEmpty && _searchQuery.isNotEmpty) {
          return const Center(child: Text("Пользователь не найден."));
        }

        // ListView.builder для производительности, особенно на больших списках.
        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            return _buildUserListItem(filteredUsers[index], context);
          },
        );
      },
    );
  }

  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.person),
      ),
      title: Text(userData["username"] ?? userData["email"]),
      subtitle: Text(userData["email"]),
      onTap: () {
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
  }
}