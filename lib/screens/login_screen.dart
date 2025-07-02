import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final void Function()? onTap;

  const LoginScreen({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Экран Входа",
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            // Переход к регистрации
            GestureDetector(
              onTap: onTap,
              child: const Text(
                "Нет аккаунта? Зарегистрироваться",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}