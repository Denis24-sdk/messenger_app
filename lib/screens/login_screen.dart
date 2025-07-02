import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger_flutter/components/my_button.dart';
import 'package:messenger_flutter/components/my_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class LoginScreen extends StatefulWidget {
  final void Function()? onTap;

  const LoginScreen({super.key, required this.onTap});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  // Метод для входа пользователя
  void login() async {

// Показываем индикатор загрузки
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // Найти email по логину
      QuerySnapshot querySnapshot = await _firestore
          .collection('Users')
          .where('username', isEqualTo: usernameController.text)
          .limit(1)
          .get();

      // Проверяем, нашелся ли пользователь
      if (querySnapshot.docs.isEmpty) {
        // Пользователь с таким логином не найден
        throw Exception('Пользователь с таким логином не найден');
      }

      // 2. Извлечь email
      String userEmail = querySnapshot.docs.first['email'];

      // 3. Выполнить вход по найденному email и паролю
      await _auth.signInWithEmailAndPassword(
        email: userEmail,
        password: passwordController.text,
      );

    } catch (e) {
      // Обрабатываем любые ошибки (от Firestore или Auth)
      String errorMessage = "Произошла ошибка. Попробуйте снова.";
      if (e is FirebaseAuthException) {
        // Конкретные ошибки Firebase Auth
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          errorMessage = 'Неверный пароль.';
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      } else if (e.toString().contains('Пользователь с таким логином не найден')) {
        errorMessage = 'Пользователь с таким логином не найден.';
      }

      // Показываем ошибку
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      // В любом случае прячем индикатор загрузки
      // Проверяем, что виджет все еще на экране
      if (mounted) {
        Navigator.pop(context);
      }
    }

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