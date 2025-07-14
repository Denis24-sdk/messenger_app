import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:messenger_flutter/main.dart';
import 'package:messenger_flutter/models/chat_room.dart';
import 'package:messenger_flutter/providers/home_provider.dart';
import 'package:messenger_flutter/screens/account_screen_wrapper.dart';
import 'package:messenger_flutter/screens/create_group_screen_wrapper.dart';
import 'package:messenger_flutter/screens/search_screen.dart';
import 'package:messenger_flutter/screens/chat_screen_wrapper.dart';
import 'package:messenger_flutter/services/auth_service.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().listenToChatRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AccountScreenWrapper())),
          icon: const Icon(Icons.person_outline_rounded),
        ),
        title: const Text("Чаты"),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textSecondary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SearchScreen())),
            icon: const Icon(Icons.search),
          ),
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
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CreateGroupScreenWrapper())),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.group_add_rounded),
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
        children: [
          Expanded(
              child: _buildFilterButton(
                  context, homeProvider, "Все", ChatFilter.all)),
          const SizedBox(width: 8),
          Expanded(
              child: _buildFilterButton(
                  context, homeProvider, "Личные", ChatFilter.private)),
          const SizedBox(width: 8),
          Expanded(
              child: _buildFilterButton(
                  context, homeProvider, "Группы", ChatFilter.group)),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, HomeProvider provider,
      String text, ChatFilter filter) {
    bool isSelected = provider.currentFilter == filter;
    return isSelected
        ? FilledButton(
      onPressed: () => provider.setFilter(filter),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    )
        : OutlinedButton(
      onPressed: () => provider.setFilter(filter),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        backgroundColor: AppColors.card,
        side: BorderSide(color: AppColors.accentGray.withOpacity(0.5)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text),
    );
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList();

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();

    if (homeProvider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    final chatRooms = homeProvider.filteredChatRooms;

    if (chatRooms.isEmpty) {
      return Center(
          child: Text("Нет активных чатов.",
              style: TextStyle(color: AppColors.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
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
        radius: 25,
        backgroundColor: AppColors.card,
        backgroundImage: chatRoom.groupAvatarUrl != null
            ? NetworkImage(chatRoom.groupAvatarUrl!)
            : null,
        child: chatRoom.groupAvatarUrl == null
            ? const Icon(Icons.group, color: AppColors.textSecondary)
            : null,
      ),
      title: Text(chatRoom.groupName ?? 'Группа',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      subtitle: Text('$prefix${lastMessage?.message ?? 'Нет сообщений'}',
          style: TextStyle(color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: Text(formattedTime, style: TextStyle(color: AppColors.textSecondary)),
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

    final otherUserIDs =
    chatRoom.members.where((id) => id != currentUserId).toList();
    if (otherUserIDs.isEmpty) {
      return const SizedBox.shrink();
    }
    final String otherUserID = otherUserIDs.first;

    return StreamBuilder<DocumentSnapshot>(
      stream: chatService.getUserStream(otherUserID),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
          return const _ChatItemPlaceholder();
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final lastMessage = chatRoom.lastMessage;
        final chatName = userData['username'] ?? userData['email'];
        final prefix = (lastMessage != null && lastMessage.senderID == currentUserId)
            ? "Вы: "
            : "";
        final formattedTime = lastMessage != null
            ? DateFormat('HH:mm').format(lastMessage.timestamp.toDate())
            : "";
        final avatarUrl = userData['avatarUrl'];
        final isOnline = userData['isOnline'] ?? false;
        final unreadCount = chatRoom.unreadCount[currentUserId] ?? 0;
        final hasUnread = unreadCount > 0;

        return ListTile(
          leading: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.card,
                backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, color: AppColors.textSecondary)
                    : null,
              ),
              if (isOnline)
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                ),
            ],
          ),
          title: Text(chatName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          subtitle: Text('$prefix${lastMessage?.message ?? 'Нет сообщений'}',
              style: TextStyle(
                color: hasUnread
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formattedTime, style: TextStyle(color: AppColors.textSecondary)),
              if (hasUnread) ...[
                const SizedBox(height: 4),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                        color: AppColors.background,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ]
            ],
          ),
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
      leading: const CircleAvatar(radius: 25, backgroundColor: AppColors.card),
      title: Container(
          height: 16,
          width: 100,
          color: AppColors.card,
          margin: const EdgeInsets.only(right: 100)),
      subtitle: Container(
          height: 12,
          width: 150,
          color: AppColors.card,
          margin: const EdgeInsets.only(right: 40)),
      trailing: Container(height: 12, width: 30, color: AppColors.card),
    );
  }
}