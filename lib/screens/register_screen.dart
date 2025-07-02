import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger_flutter/components/my_button.dart';
import 'package:messenger_flutter/components/my_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glassmorphism/glassmorphism.dart';

class RegisterScreen extends StatefulWidget {
  final void Function()? onTap;

  const RegisterScreen({super.key, required this.onTap});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController usernameController = TextEditingController();
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
      builder: (context) =>
      const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Проверяем, совпадают ли пароли
    if (passwordController.text != confirmPasswordController.text) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пароли не совпадают!")),
      );
      return; // Прерываем выполнение
    }

    try {
      // Прячем индикатор
      if (mounted) Navigator.pop(context);

      // Пытаемся создать пользователя
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // После создания пользователя, создаем для него документ в Firestore
      await _firestore.collection("Users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': emailController.text,
        'username': usernameController.text,
      });
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Произошла ошибка")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/background.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: GlassmorphicContainer(
              width: 350,
              height: 570,
              borderRadius: 20,
              blur: 0,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  HSLColor.fromColor(Colors.white).withAlpha(0.9).toColor(),
                  HSLColor.fromColor(Colors.black12).withAlpha(1).toColor(),
                ],
                stops: const [0.1, 1],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  HSLColor.fromColor(Colors.white).withAlpha(0.4).toColor(),
                  HSLColor.fromColor(Colors.white).withAlpha(0.1).toColor(),
                ],
              ),
              // Содержимое контейнера для регистрации
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Создать аккаунт",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Заполните поля, чтобы начать",
                        style: TextStyle(
                          fontSize: 16, // И этот
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      // Поля ввода
                      MyTextField(
                        hintText: "Логин",
                        obscureText: false,
                        controller: usernameController,
                      ),
                      const SizedBox(height: 15),
                      MyTextField(
                        hintText: "Email",
                        obscureText: false,
                        controller: emailController,
                      ),
                      const SizedBox(height: 15),
                      MyTextField(
                        hintText: "Пароль",
                        obscureText: true,
                        controller: passwordController,
                      ),
                      const SizedBox(height: 15),
                      MyTextField(
                        hintText: "Подтвердите пароль",
                        obscureText: true,
                        controller: confirmPasswordController,
                      ),
                      const SizedBox(height: 30),

                      // Кнопка регистрации
                      MyButton(
                        text: "Зарегистрироваться",
                        onTap: register,
                      ),
                      const SizedBox(height: 20),

                      // Ссылка на вход
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Уже есть аккаунт? ',
                            style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold,),
                          ),
                          const SizedBox(width: 15),
                          GestureDetector(
                            onTap: widget.onTap,
                            child: Text(
                              'Войти',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: HSLColor.fromColor(Colors.white).withAlpha(0.7).toColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
    );
  }
}