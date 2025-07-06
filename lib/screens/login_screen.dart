import 'package:flutter/material.dart';
import 'package:messenger_flutter/components/my_button.dart';
import 'package:messenger_flutter/components/my_textfield.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:messenger_flutter/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  final void Function()? onTap;

  const LoginScreen({super.key, required this.onTap});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void login(BuildContext context) async {
    final authService = context.read<AuthService>();

    try {
      await authService.login(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = "Произошла ошибка. Попробуйте снова.";
      if (e is FirebaseAuthException) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          errorMessage = 'Неверный пароль.';
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      } else if (e.toString().contains('Пользователь с таким логином не найден')) {
        errorMessage = 'Пользователь с таким логином не найден.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final bool isLoading = authService.status == AuthStatus.authenticating;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
            height: 500,
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Снова с нами?",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Войдите, чтобы продолжить общение",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    MyTextField(
                      hintText: "Логин",
                      obscureText: false,
                      controller: usernameController,
                    ),
                    const SizedBox(height: 15),
                    MyTextField(
                      hintText: "Пароль",
                      obscureText: true,
                      controller: passwordController,
                    ),
                    const SizedBox(height: 40),
                    MyButton(
                      text: "Войти",
                      onTap: isLoading ? null : () => login(context),
                      child: isLoading ? const CircularProgressIndicator(color: Colors.white) : null,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Впервые здесь? ',
                          style: TextStyle(
                              color: Colors.grey[900],
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Text(
                            'Создать аккаунт',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: HSLColor.fromColor(Colors.white)
                                  .withAlpha(0.7)
                                  .toColor(),
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
      ),
    );
  }
}