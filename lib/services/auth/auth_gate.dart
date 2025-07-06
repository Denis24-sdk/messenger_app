import 'package:flutter/material.dart';
import 'package:messenger_flutter/screens/home_screen.dart';
import 'package:messenger_flutter/screens/login_or_register_screen.dart';
import 'package:messenger_flutter/services/auth_service.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        switch (authService.status) {
          case AuthStatus.uninitialized:
          case AuthStatus.authenticating:
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          case AuthStatus.authenticated:
            return const HomeScreen();
          case AuthStatus.unauthenticated:
            return const LoginOrRegisterScreen();
        }
      },
    );
  }
}