import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  final void Function()? onTap;

  const RegisterScreen({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Экран Регистрации",
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            // Переход ко входу
            GestureDetector(
              onTap: onTap,
              child: const Text(
                "Уже есть аккаунт? Войти",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}