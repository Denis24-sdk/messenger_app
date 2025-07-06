import 'package:flutter/material.dart';
import 'package:messenger_flutter/providers/create_group_provider.dart';
import 'package:provider/provider.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _createGroup() async {
    final provider = context.read<CreateGroupProvider>();
    try {
      await provider.createGroup(_groupNameController.text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreateGroupProvider>();
    final isLoading = provider.isLoading;

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
              child: Text("Выберите участников:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: provider.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Ошибка"));
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final uid = user['uid'];
                    final isSelected = provider.selectedUsers.containsKey(uid);
                    final avatarUrl = user['avatarUrl'];

                    return CheckboxListTile(
                      title: Text(user['username'] ?? user['email']),
                      secondary: CircleAvatar(
                        backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        provider.toggleUserSelection(uid, user);
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
        onPressed: isLoading ? null : _createGroup,
        icon: isLoading ? const SizedBox.shrink() : const Icon(Icons.check),
        label: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Создать"),
      ),
    );
  }
}