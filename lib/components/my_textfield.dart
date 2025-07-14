import 'package:flutter/material.dart';
import 'package:messenger_flutter/main.dart';

class MyTextField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextEditingController controller;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;


  const MyTextField({
    Key? key,
    required this.hintText,
    required this.icon,
    required this.controller,
    required this.obscureText,
    this.autofocus = false,
    this.onChanged,
    this.keyboardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      autofocus: autofocus,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.card,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 22,),
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.accentGray,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}