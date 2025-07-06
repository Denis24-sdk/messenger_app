import 'package:flutter/material.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _groupNameController = TextEditingController();

  final Map<String, Map<String, dynamic>> _selectedUsers = {};
  bool _isLoading = false;

  void _toggleUserSelection(String uid, Map<String, dynamic> userData) {
    setState(() {
      if (_selectedUsers.containsKey(uid)) {
        _selectedUsers.remove(uid);
      } else {
        _selectedUsers[uid] = userData;
      }
    });
  }

  void _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Введите название группы")),
      );
      return;
    }
    if (_selectedUsers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Выберите хотя бы двух участников")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> memberIds = _selectedUsers.keys.toList();
      await _chatService.createGroupChat(_groupNameController.text.trim(), memberIds);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка создания группы: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Новая группа"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: "Название группы",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Выберите участников:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Ошибка"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final users = snapshot.data!
                    .where((user) => user['uid'] != _auth.currentUser!.uid)
                    .toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final uid = user['uid'];
                    final isSelected = _selectedUsers.containsKey(uid);

                    return CheckboxListTile(
                      title: Text(user['username'] ?? user['email']),
                      secondary: CircleAvatar(
                        backgroundImage: user['avatarUrl'] != null ? NetworkImage(user['avatarUrl']) : null,
                        child: user['avatarUrl'] == null ? const Icon(Icons.person) : null,
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        _toggleUserSelection(uid, user);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _createGroup,
        icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.check),
        label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Создать"),
      ),
    );
  }
}