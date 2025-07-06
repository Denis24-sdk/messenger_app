import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:messenger_flutter/screens/account_screen.dart';
import 'package:messenger_flutter/screens/create_group_screen.dart';
import 'package:messenger_flutter/screens/search_screen.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_flutter/screens/chat_screen.dart';


enum ChatFilter { all, private, group }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Переменная для хранения текущего фильтра
  ChatFilter _currentFilter = ChatFilter.all;

  void signOut(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await _chatService.updateUserStatus(false);
      await _auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AccountScreen()),
            );
          },
          icon: const Icon(Icons.person),
        ),
        title: const Text("Чаты"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => signOut(context),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilterButtons(),
          Expanded(
            child: _buildChatList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CreateGroupScreen()));
        },
        child: const Icon(Icons.group_add),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterButton("Все", ChatFilter.all),
          _buildFilterButton("ЛС", ChatFilter.private),
          _buildFilterButton("Группы", ChatFilter.group),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, ChatFilter filter) {
    bool isSelected = _currentFilter == filter;
    return TextButton(
      onPressed: () {
        setState(() {
          _currentFilter = filter;
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getChatRoomsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Ошибка загрузки"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Нет активных чатов."));
        }

        // фильрация: все, лс и группы
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final isGroup = data['isGroup'] ?? false;

          switch (_currentFilter) {
            case ChatFilter.all:
              return true;
            case ChatFilter.private:
              return !isGroup;
            case ChatFilter.group:
              return isGroup;
          }
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text("В этой категории нет чатов."));
        }

        return ListView(
          children: filteredDocs
              .map<Widget>((doc) => _buildChatListItem(doc, context))
              .toList(),
        );
      },
    );
  }

  Widget _buildChatListItem(DocumentSnapshot chatDoc, BuildContext context) {
    Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;
    bool isGroup = chatData['isGroup'] ?? false;

    return isGroup
        ? _buildGroupChatItem(chatDoc, context)
        : _buildPrivateChatItem(chatDoc, context);
  }

  Widget _buildGroupChatItem(DocumentSnapshot chatDoc, BuildContext context) {
    Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;
    String groupName = chatData['groupName'] ?? 'Группа';
    String? groupAvatarUrl = chatData['groupAvatarUrl'];

    String lastMessage = chatData['lastMessage'] ?? '';
    String prefix = "";
    if (chatData['lastMessageSenderId'] != 'system') {
      prefix = (chatData['lastMessageSenderId'] == _auth.currentUser!.uid)
          ? "Вы: "
          : "";
    }

    Timestamp? ts = chatData['lastMessageTimestamp'] as Timestamp?;
    String formattedTime = ts != null ? DateFormat('HH:mm').format(ts.toDate()) : "";

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: groupAvatarUrl != null ? NetworkImage(groupAvatarUrl) : null,
        child: groupAvatarUrl == null ? Icon(Icons.group, color: Colors.grey.shade800) : null,
      ),
      title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$prefix$lastMessage', maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(formattedTime),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatRoomId: chatDoc.id,
              chatName: groupName,
              isGroup: true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivateChatItem(DocumentSnapshot chatDoc, BuildContext context) {
    Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;

    List<dynamic> members = chatData['members'];
    String otherUserID = members.firstWhere((id) => id != _auth.currentUser!.uid, orElse: () => '');

    if (otherUserID.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('Users').doc(otherUserID).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
          // Показываем заглушку, пока данные грузятся, чтобы избежать прыжков
          return ListTile(
            leading: CircleAvatar(radius: 24, backgroundColor: Colors.grey.shade300),
            title: Container(height: 16, width: 100, color: Colors.grey.shade300),
            subtitle: Container(height: 12, width: 150, color: Colors.grey.shade300),
          );
        }

        Map<String, dynamic> userData = userSnapshot.data!.data() as Map<String, dynamic>;
        String chatName = userData['username'] ?? userData['email'];

        String lastMessage = chatData['lastMessage'] ?? '';
        String prefix = (chatData['lastMessageSenderId'] == _auth.currentUser!.uid) ? "Вы: " : "";
        Timestamp? ts = chatData['lastMessageTimestamp'] as Timestamp?;
        String formattedTime = ts != null ? DateFormat('HH:mm').format(ts.toDate()) : "";
        bool isOnline = userData['isOnline'] ?? false;
        String? avatarUrl = userData['avatarUrl'];

        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? Icon(Icons.person, color: Colors.grey.shade800) : null,
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
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(chatName),
          subtitle: Text('$prefix$lastMessage', maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(formattedTime),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  receiverID: userData["uid"],
                  receiverEmail: userData["email"],
                  chatName: chatName,
                  isGroup: false,
                  chatRoomId: chatDoc.id,
                ),
              ),
            );
          },
        );
      },
    );
  }
}