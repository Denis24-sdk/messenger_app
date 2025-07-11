import 'package:flutter/material.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_flutter/screens/chat_screen_wrapper.dart';
import 'package:messenger_flutter/components/my_textfield.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

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
          onChanged: (value) => setState(() {}),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            ),
        ],
      ),
      body: _UserList(searchQuery: _searchController.text),
    );
  }
}

class _UserList extends StatelessWidget {
  final String searchQuery;
  const _UserList({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final chatService = context.read<ChatService>();
    final auth = context.read<FirebaseAuth>();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: chatService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Ошибка"));
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allUsers = snapshot.data!;
        final filteredUsers = allUsers.where((user) {
          if (user['uid'] == auth.currentUser!.uid) return false;

          if (searchQuery.isEmpty) return true;

          final username = (user["username"] ?? "").toLowerCase();
          final email = (user["email"] ?? "").toLowerCase();
          final query = searchQuery.toLowerCase();
          return username.contains(query) || email.contains(query);
        }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(child: Text("Пользователь не найден."));
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            return _UserListItem(userData: filteredUsers[index]);
          },
        );
      },
    );
  }
}

class _UserListItem extends StatelessWidget {
  final Map<String, dynamic> userData;
  const _UserListItem({required this.userData});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<FirebaseAuth>();
    final chatService = context.read<ChatService>();
    final String? avatarUrl = userData['avatarUrl'];
    final String displayName = userData["username"] ?? userData["email"];

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null
            ? const Icon(Icons.person, size: 24, color: Colors.grey)
            : null,
      ),
      title: Text(displayName),
      onTap: () async {
        final currentUser = auth.currentUser;
        if (currentUser == null) return;

        final otherUserUid = userData['uid'];
        final String chatRoomId = await chatService.createPrivateChatRoomIfNeeded(otherUserUid);

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreenWrapper(
                chatName: displayName,
                isGroup: false,
                chatRoomId: chatRoomId,
                receiverID: userData["uid"],
                receiverEmail: userData["email"],
              ),
            ),
          );
        }
      },
    );
  }
}