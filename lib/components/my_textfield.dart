import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final bool? autofocus;
  final TextInputAction? textInputAction;

  const MyTextField({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.controller,
    this.autofocus,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      autofocus: autofocus ?? false,
      textInputAction: textInputAction,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        border: InputBorder.none,
        fillColor: HSLColor.fromColor(Colors.white).withAlpha(0.2).toColor(),
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            width: 2,
          ),
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: HSLColor.fromColor(Colors.black).withAlpha(0.9).toColor(),
        ),
      ),
    );
  }
}