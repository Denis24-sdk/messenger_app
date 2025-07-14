import 'package:flutter/material.dart';
import 'package:messenger_flutter/components/my_textfield.dart';
import 'package:messenger_flutter/main.dart';
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
      await provider.createGroup(_groupNameController.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreateGroupProvider>();
    final isLoading = provider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Новая группа"),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textSecondary,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: MyTextField(
              controller: _groupNameController,
              hintText: "Название группы",
              icon: Icons.group_add_rounded,
              obscureText: false,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text("Выберите участников:",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary)),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: provider.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Ошибка загрузки"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
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
                      title: Text(user['username'] ?? user['email'],
                          style: const TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text(user['email'],
                          style:
                          const TextStyle(color: AppColors.textSecondary)),
                      secondary: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.card,
                        backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? const Icon(Icons.person, color: AppColors.textSecondary,)
                            : null,
                      ),
                      activeColor: AppColors.accent,
                      checkColor: AppColors.background,
                      tileColor: isSelected ? AppColors.accent.withOpacity(0.1) : Colors.transparent,
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
        icon: isLoading ? null : const Icon(Icons.check),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        label: isLoading
            ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2.5,))
            : const Text("Создать группу"),
      ),
    );
  }
}