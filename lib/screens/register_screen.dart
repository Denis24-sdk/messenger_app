import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger_flutter/components/my_button.dart';
import 'package:messenger_flutter/components/my_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  final void Function()? onTap;

  const RegisterScreen({super.key, required this.onTap});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Метод для регистрации
  void register() async {
    // Показываем индикатор загрузки
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Проверяем, совпадают ли пароли
    if (passwordController.text != confirmPasswordController.text) {
      // Прячем индикатор
      Navigator.pop(context);
      // Показываем ошибку
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пароли не совпадают!")),
      );
      return; // Прерываем выполнение
    }

    try {
      // Прячем индикатор
      if (mounted) Navigator.pop(context);

      // Пытаемся создать пользователя
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // После создания пользователя, создаем для него документ в Firestore
      await _firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': emailController.text,
      });


    } on FirebaseAuthException catch (e) {
      // Прячем индикатор
      Navigator.pop(context);
      // Показываем ошибку
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Произошла ошибка")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const Icon(Icons.message, size: 100),
                const SizedBox(height: 50),
                const Text("Давайте создадим аккаунт для вас!"),
                const SizedBox(height: 25),
                MyTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Пароль',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: 'Подтвердите пароль',
                  obscureText: true,
                ),
                const SizedBox(height: 25),
                MyButton(onTap: register, text: "Зарегистрироваться"),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Уже есть аккаунт?'),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Войти',
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