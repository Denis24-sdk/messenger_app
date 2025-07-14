import 'package:flutter/material.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_flutter/screens/chat_screen_wrapper.dart';
import 'package:messenger_flutter/components/my_textfield.dart';
import 'package:messenger_flutter/main.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: MyTextField(
          controller: _searchController,
          hintText: "Поиск пользователей...",
          icon: Icons.search,
          obscureText: false,
          autofocus: true,
          onChanged: (value) => setState(() {}),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textSecondary,
        elevation: 0,
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
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
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Не удалось загрузить пользователей",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent,));
        }

        final allUsers = snapshot.data!;
        final filteredUsers = allUsers.where((user) {
          if (user['uid'] == auth.currentUser!.uid) return false;

          final username = (user["username"] ?? "").toLowerCase();
          final email = (user["email"] ?? "").toLowerCase();
          final query = searchQuery.toLowerCase().trim();

          if (query.isEmpty) return false;

          return username.contains(query) || email.contains(query);
        }).toList();

        if (searchQuery.trim().isEmpty) {
          return Center(
              child: Text(
                'Начните вводить логин или email',
                style: TextStyle(color: AppColors.textSecondary),
              )
          );
        }

        if (filteredUsers.isEmpty) {
          return Center(
            child: Text(
              "Пользователи не найдены",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
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
    final String displayName = userData["username"] ?? "Пользователь";
    final String email = userData["email"] ?? "email не указан";

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.card,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Icon(Icons.person, size: 28, color: AppColors.textSecondary)
                : null,
          ),
          title: Text(
            displayName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            email,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          onTap: () async {
            final currentUser = auth.currentUser;
            if (currentUser == null) return;

            final otherUserUid = userData['uid'];
            final String chatRoomId =
            await chatService.createPrivateChatRoomIfNeeded(otherUserUid);

            if (context.mounted) {
              Navigator.pop(context); // Закрываем экран
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
        ),
        Padding(
          padding: const EdgeInsets.only(left: 80, right: 16),
          child: Divider(
            color: AppColors.accentGray.withOpacity(0.3),
            height: 1,
          ),
        ),
      ],
    );
  }
}