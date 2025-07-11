  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import 'package:messenger_flutter/providers/account_provider.dart';
  import 'package:messenger_flutter/screens/account_screen.dart';
  import 'package:messenger_flutter/services/storage/storage_service.dart';
  import 'package:provider/provider.dart';

  class AccountScreenWrapper extends StatelessWidget {
    const AccountScreenWrapper({super.key});

    @override
    Widget build(BuildContext context) {
      return ChangeNotifierProvider(
        create: (context) => AccountProvider(
          auth: context.read<FirebaseAuth>(),
          firestore: context.read<FirebaseFirestore>(),
          storageService: context.read<StorageService>(),
        ),
        child: const AccountScreen(),
      );
    }
  }