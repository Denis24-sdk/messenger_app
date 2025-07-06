import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger_flutter/providers/create_group_provider.dart';
import 'package:messenger_flutter/screens/create_group_screen.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:provider/provider.dart';

class CreateGroupScreenWrapper extends StatelessWidget {
  const CreateGroupScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CreateGroupProvider(
        chatService: context.read<ChatService>(),
        auth: context.read<FirebaseAuth>(),
      ),
      child: const CreateGroupScreen(),
    );
  }
}