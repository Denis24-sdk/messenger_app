import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:messenger_flutter/models/chat_room.dart';
import 'package:messenger_flutter/providers/home_provider.dart';
import 'package:messenger_flutter/screens/account_screen.dart';
import 'package:messenger_flutter/screens/search_screen.dart';
import 'package:messenger_flutter/screens/chat_screen_wrapper.dart';
import 'package:messenger_flutter/services/auth_service.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:messenger_flutter/screens/create_group_screen_wrapper.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _signOut(BuildContext context) {
    context.read<AuthService>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AccountScreen())),
          icon: const Icon(Icons.person),
        ),
        title: const Text("Чаты"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SearchScreen())),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: const Column(
        children: [
          _FilterButtons(),
          Expanded(
            child: _ChatList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CreateGroupScreenWrapper()));
        },
        child: const Icon(Icons.group_add),
      ),
    );
  }
}

class _FilterButtons extends StatelessWidget {
  const _FilterButtons();

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterButton(context, homeProvider, "Все", ChatFilter.all),
          _buildFilterButton(context, homeProvider, "ЛС", ChatFilter.private),
          _buildFilterButton(context, homeProvider, "Группы", ChatFilter.group),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, HomeProvider provider,
      String text, ChatFilter filter) {
    bool isSelected = provider.currentFilter == filter;
    return TextButton(
      onPressed: () => provider.setFilter(filter),
      style: TextButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList();

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();

    if (homeProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final chatRooms = homeProvider.filteredChatRooms;

    if (chatRooms.isEmpty) {
      return const Center(child: Text("Нет активных чатов."));
    }

    return ListView.builder(
      itemCount: chatRooms.length,
      itemBuilder: (context, index) {
        final room = chatRooms[index];
        return room.isGroup
            ? _GroupChatItem(chatRoom: room)
            : _PrivateChatItem(chatRoom: room);
      },
    );
  }
}

class _GroupChatItem extends StatelessWidget {
  final ChatRoom chatRoom;
  const _GroupChatItem({required this.chatRoom});

  @override
  Widget build(BuildContext context) {
    final lastMessage = chatRoom.lastMessage;
    final String currentUserId = context.read<AuthService>().user!.uid;

    String prefix = "";
    if (lastMessage != null && lastMessage.senderID != 'system') {
      prefix = (lastMessage.senderID == currentUserId) ? "Вы: " : "";
    }

    String formattedTime = lastMessage != null
        ? DateFormat('HH:mm').format(lastMessage.timestamp.toDate())
        : "";

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: chatRoom.groupAvatarUrl != null
            ? NetworkImage(chatRoom.groupAvatarUrl!)
            : null,
        child: chatRoom.groupAvatarUrl == null
            ? const Icon(Icons.group, color: Colors.grey)
            : null,
      ),
      title: Text(chatRoom.groupName ?? 'Группа',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$prefix${lastMessage?.message ?? ''}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(formattedTime),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreenWrapper(
            chatRoomId: chatRoom.id,
            chatName: chatRoom.groupName ?? 'Группа',
            isGroup: true,
          ),
        ),
      ),
    );
  }
}

class _PrivateChatItem extends StatelessWidget {
  final ChatRoom chatRoom;
  const _PrivateChatItem({required this.chatRoom});

  @override
  Widget build(BuildContext context) {
    final chatService = context.read<ChatService>();
    final currentUserId = context.read<AuthService>().user!.uid;

    if (chatRoom.otherUserId == null || chatRoom.otherUserId!.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: chatService.getUserStream(chatRoom.otherUserId!),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
          return const _ChatItemPlaceholder();
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final lastMessage = chatRoom.lastMessage;
        final chatName = userData['username'] ?? userData['email'];
        final prefix = (lastMessage?.senderID == currentUserId) ? "Вы: " : "";
        final formattedTime = lastMessage != null
            ? DateFormat('HH:mm').format(lastMessage.timestamp.toDate())
            : "";
        final avatarUrl = userData['avatarUrl'];
        final isOnline = userData['isOnline'] ?? false;

        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade300,
                backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(chatName),
          subtitle: Text('$prefix${lastMessage?.message ?? ''}',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(formattedTime),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreenWrapper(
                receiverID: userData["uid"],
                receiverEmail: userData["email"],
                chatName: chatName,
                isGroup: false,
                chatRoomId: chatRoom.id,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChatItemPlaceholder extends StatelessWidget {
  const _ChatItemPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(radius: 24, backgroundColor: Colors.grey.shade300),
      title: Container(height: 16, width: 100, color: Colors.grey.shade300),
      subtitle: Container(height: 12, width: 150, color: Colors.grey.shade300),
    );
  }
}