import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  const MyTextField({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.controller,
    this.autofocus = false,
    this.textInputAction,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      autofocus: autofocus,
      textInputAction: textInputAction,
      onChanged: onChanged,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _buildInputDecoration(context),
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context) {
    const enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(15)),
      borderSide: BorderSide.none,
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(15)),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
        width: 2,
      ),
    );

    return InputDecoration(
      border: InputBorder.none,
      fillColor: Colors.black.withOpacity(0.05),
      filled: true,
      enabledBorder: enabledBorder,
      focusedBorder: focusedBorder,
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey.shade600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}