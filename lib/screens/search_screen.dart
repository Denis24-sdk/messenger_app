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
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextField(
          controller: _searchController,
          hintText: "Поиск...",
          obscureText: false,
          autofocus: true,
          textInputAction: TextInputAction.search,
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Ошибка"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Нет пользователей."));
        }

        var allUsers = snapshot.data!;

        // Фильтруем пользователей
        final filteredUsers = allUsers.where((user) {
          if (user['uid'] == _auth.currentUser!.uid) {
            return false;
          }
          if (_searchQuery.isEmpty) {
            return true;
          }
          String username = (user["username"] ?? "").toLowerCase();
          String email = (user["email"] ?? "").toLowerCase();
          String query = _searchQuery.toLowerCase();
          return username.contains(query) || email.contains(query);
        }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(child: Text("Пользователь не найден."));
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            return _buildUserListItem(filteredUsers[index], context);
          },
        );
      },
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> userData, BuildContext context) {
    final String? avatarUrl = userData['avatarUrl'];
    final String displayName = userData["username"] ?? userData["email"];

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null
            ? Icon(Icons.person, size: 24, color: Colors.grey.shade800)
            : null,
      ),
      title: Text(displayName),
      onTap: () {
        final currentUser = _auth.currentUser;
        if (currentUser == null) return;

        List<String> ids = [currentUser.uid, userData['uid']];
        ids.sort();
        String chatRoomId = ids.join('_');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatName: displayName,
              isGroup: false,
              chatRoomId: chatRoomId,
              receiverID: userData["uid"],
              receiverEmail: userData["email"],
            ),
          ),
        );
      },
    );
  }
}