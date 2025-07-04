import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:messenger_flutter/screens/search_screen.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger_flutter/screens/chat_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      body: _buildChatList(),
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
        return ListView(
          children: snapshot.data!.docs
              .map<Widget>((doc) => _buildChatListItem(doc, context))
              .toList(),
        );
      },
    );
  }


  Widget _buildChatListItem(DocumentSnapshot chatDoc, BuildContext context) {
    Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;

    // Определяем ID собеседника.
    List<dynamic> members = chatData['members'];
    String otherUserID = members.firstWhere((id) =>
    id != _auth.currentUser!.uid);

    // Асинхронно получаем данные собеседника.
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('Users').doc(otherUserID).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const ListTile();

        Map<String, dynamic> userData = userSnapshot.data!.data() as Map<
            String,
            dynamic>;

        String lastMessage = chatData['lastMessage'] ?? '';
        String prefix = (chatData['lastMessageSenderId'] ==
            _auth.currentUser!.uid) ? "Вы: " : "";
        Timestamp ts = chatData['lastMessageTimestamp'];
        String formattedTime = DateFormat('HH:mm').format(ts.toDate());

        bool isOnline = userData['isOnline'] ?? false;

        return ListTile(
          leading: Stack(
            children: [
              const CircleAvatar(radius: 24, child: Icon(Icons.person)),
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
                      border: Border.all(color: Theme
                          .of(context)
                          .scaffoldBackgroundColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(userData['username'] ?? userData['email']),
          subtitle: Text('$prefix$lastMessage', maxLines: 1,
              overflow: TextOverflow.ellipsis),
          trailing: Text(formattedTime),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChatScreen(
                      receiverEmail: userData["username"] ?? userData["email"],
                      receiverID: userData["uid"],
                    ),
              ),
            );
          },
        );
      },
    );
  }
}