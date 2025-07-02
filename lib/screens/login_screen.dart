import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger_flutter/components/my_button.dart';
import 'package:messenger_flutter/components/my_textfield.dart';

class LoginScreen extends StatefulWidget {
  final void Function()? onTap;

  const LoginScreen({super.key, required this.onTap});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Метод для входа пользователя
  void login() async {



  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea( // Добавил SafeArea
        child: Center(
          child: SingleChildScrollView( // Добавил SingleChildScrollView
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ... logo, welcome message ...
                const SizedBox(height: 50),
                const Icon(Icons.message, size: 100),
                const SizedBox(height: 50),
                const Text("С возвращением, мы скучали!"),
                const SizedBox(height: 25),

                // --- ИЗМЕНЕНИЕ: поле для логина ---
                MyTextField(
                  hintText: "Логин",
                  obscureText: false,
                  controller: usernameController,
                ),

                const SizedBox(height: 10),

                // password textfield
                MyTextField(
                  hintText: "Пароль",
                  obscureText: true,
                  controller: passwordController,
                ),

                const SizedBox(height: 25),

                // login button
                MyButton(
                  text: "Войти",
                  onTap: login,
                ),

                const SizedBox(height: 25),

                // ... register now ...
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Не зарегистрированы?'),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Создать аккаунт',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}