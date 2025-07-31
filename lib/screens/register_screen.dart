import 'package:flutter/material.dart';
import 'package:messenger_flutter/components/my_button.dart';
import 'package:messenger_flutter/components/my_textfield.dart';
import 'package:messenger_flutter/main.dart';
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
  final TextEditingController confirmPasswordController =
  TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void register(BuildContext context) async {
    final authService = context.read<AuthService>();

    try {
      await authService.register(
        usernameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
        confirmPasswordController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMessage = "Произошла неизвестная ошибка.";
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'Этот email уже зарегистрирован.';
            break;
          case 'weak-password':
            errorMessage = 'Пароль слишком слабый (минимум 6 символов).';
            break;
          case 'invalid-email':
            errorMessage = 'Некорректный формат email адреса.';
            break;
          default:
            errorMessage = 'Произошла ошибка регистрации. Попробуйте позже.';
        }
      } else if (e is Exception) {
        // кастомные ошибки
        errorMessage = e.toString().replaceFirst('Exception: ', '');
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
                const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 80,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 20),
                Text(
                  'Создание аккаунта',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Заполните поля ниже, чтобы начать',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Icon(
                          Icons.privacy_tip_outlined,
                          color: AppColors.accent.withOpacity(0.8),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Это некоммерческий проект, поэтому, пожалуйста, НЕ используйте настоящие почту и пароль.",
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                MyTextField(
                  hintText: "Логин",
                  icon: Icons.person_outline_rounded,
                  controller: usernameController,
                  obscureText: false,
                ),
                const SizedBox(height: 20),
                MyTextField(
                  hintText: "Email",
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
                const SizedBox(height: 20),
                MyTextField(
                  hintText: "Подтвердите пароль",
                  icon: Icons.lock_clock_rounded,
                  controller: confirmPasswordController,
                  obscureText: true,
                ),
                const SizedBox(height: 40),
                MyButton(
                  onPressed: isLoading ? null : () => register(context),
                  isLoading: isLoading,
                  text: "Создать аккаунт",
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Уже есть аккаунт? ',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        'Войти',
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