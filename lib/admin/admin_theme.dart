import 'package:flutter/material.dart';

class AdminTheme {
  const AdminTheme._();

  static const background = Color(0xFFF7F5FA);
  static const surface = Colors.white;
  static const text = Color(0xFF2F3341);
  static const muted = Color(0xFF7D8393);
  static const pink = Color(0xFFE94B9A);
  static const purple = Color(0xFF8458FF);
  static const shadow = Color(0x12000000);

  static const heroGradient = LinearGradient(
    colors: [pink, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
