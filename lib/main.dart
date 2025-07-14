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

class AppColors {
  static const Color background = Color(0xFF121212);
  static const Color card = Color(0xFF1E1E1E);
  static const Color accent = Color(0xFF40D8A5);
  static const Color accentGray = Color(0xFF3B3B3B);
  static const Color textPrimary = Color(0xFFEAEAEA);
  static const Color textSecondary = Color(0xFFB0B0B0);
}

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
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            secondary: AppColors.accent,
            background: AppColors.background,
            surface: AppColors.card,
            onPrimary: Colors.black,
            onBackground: AppColors.textPrimary,
            onSurface: AppColors.textPrimary,
          ),
          useMaterial3: true,
          textTheme: const TextTheme(
              titleLarge: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              headlineMedium: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              bodyMedium: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              labelLarge: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              )
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}