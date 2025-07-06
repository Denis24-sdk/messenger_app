import 'package:flutter/material.dart';
import 'package:messenger_flutter/components/my_button.dart';
import 'package:messenger_flutter/components/my_textfield.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:messenger_flutter/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    final authService = context.read<AuthService>();
    try {
      await authService.register(
        usernameController.text,
        emailController.text,
        passwordController.text,
        confirmPasswordController.text,
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = "Произошла ошибка.";
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          errorMessage = 'Этот email уже зарегистрирован.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Пароль слишком слабый.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Некорректный формат email.';
        }
      } else if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final isLoading = authService.status == AuthStatus.authenticating;

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
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
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
                      MyButton(
                        text: "Зарегистрироваться",
                        onTap: isLoading ? null : _handleRegister,
                        child: isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Уже есть аккаунт? ',
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 15),
                          GestureDetector(
                            onTap: widget.onTap,
                            child: Text(
                              'Войти',
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
        ));
  }
}