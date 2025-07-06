import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:messenger_flutter/firebase_options.dart';
import 'package:messenger_flutter/providers/home_provider.dart';
import 'package:messenger_flutter/services/auth/auth_gate.dart';
import 'package:messenger_flutter/services/auth_service.dart';
import 'package:messenger_flutter/services/chat/chat_service.dart';
import 'package:messenger_flutter/services/storage/storage_service.dart';
import 'package:messenger_flutter/providers/account_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseAuth>(create: (_) => FirebaseAuth.instance),
        Provider<FirebaseFirestore>(create: (_) => FirebaseFirestore.instance),
        Provider<StorageService>(create: (_) => StorageService()),

        Provider<ChatService>(
          create: (context) => ChatService(
            firestore: context.read<FirebaseFirestore>(),
            auth: context.read<FirebaseAuth>(),
          ),
        ),

        ChangeNotifierProvider<AuthService>(
          create: (context) => AuthService(
            auth: context.read<FirebaseAuth>(),
            firestore: context.read<FirebaseFirestore>(),
          ),
        ),

        ChangeNotifierProvider<HomeProvider>(
          create: (context) => HomeProvider(
            chatService: context.read<ChatService>(),
          ),
        ),

        ChangeNotifierProvider<AccountProvider>(
          create: (context) => AccountProvider(
            auth: context.read<FirebaseAuth>(),
            firestore: context.read<FirebaseFirestore>(),
            storageService: context.read<StorageService>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Messenger',
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}