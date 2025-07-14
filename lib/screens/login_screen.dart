import 'package:flutter/material.dart';
import 'package:messenger_flutter/main.dart';
import 'package:messenger_flutter/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:messenger_flutter/components/my_button.dart';
import 'package:messenger_flutter/components/my_textfield.dart';

class LoginScreen extends StatefulWidget {
  final void Function()? onTap;
  const LoginScreen({super.key, required this.onTap});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login(BuildContext context) async {
    final authService = context.read<AuthService>();
    try {
      await authService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMessage = "Произошла ошибка. Попробуйте снова.";
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            errorMessage = 'Некорректный формат email адреса.';
            break;
          case 'user-not-found':
            errorMessage = 'Пользователь с таким email не найден.';
            break;
          case 'wrong-password':
          case 'invalid-credential':
            errorMessage = 'Неверный пароль. Пожалуйста, попробуйте еще раз.';
            break;
          default:
            errorMessage = 'Произошла неизвестная ошибка. Попробуйте позже.';
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final bool isLoading = authService.status == AuthStatus.authenticating;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.background.withOpacity(0.9),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.person,
                  size: 80,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 20),

                Text(
                  'С возвращением!',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Войдите в свой аккаунт, чтобы продолжить',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),

                MyTextField(
                  hintText: "Email или Логин",
                  icon: Icons.alternate_email_rounded,
                  controller: emailController,
                  obscureText: false,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                MyTextField(
                  hintText: "Пароль",
                  icon: Icons.lock_outline_rounded,
                  controller: passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: 40),

                MyButton(
                  onPressed: isLoading ? null : () => login(context),
                  isLoading: isLoading,
                  text: "Войти",
                ),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Нет аккаунта? ',
                      style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        'Создать',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
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
    );
  }
}