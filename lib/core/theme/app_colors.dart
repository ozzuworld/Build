import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors (Netflix-inspired)
  static const Color primary = Color(0xFFE50914);
  static const Color primaryDark = Color(0xFFB20710);
  static const Color secondary = Color(0xFF564D4D);

  // Background Colors
  static const Color background = Color(0xFF141414);
  static const Color surface = Color(0xFF1F1F1F);
  static const Color cardBackground = Color(0xFF2F2F2F);
  static const Color inputBackground = Color(0xFF333333);

  // Gradient Colors
  static const Color gradientStart = Color(0xFF141414);
  static const Color gradientEnd = Colors.transparent;

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF757575);

  // Status Colors
  static const Color success = Color(0xFF46D369);
  static const Color warning = Color(0xFFF5C518);
  static const Color error = Color(0xFFE50914);
  static const Color info = Color(0xFF0080FF);

  // Focus Colors (for TV navigation)
  static const Color focusBorder = Colors.white;
  static const Color focusGlow = Color(0x40FFFFFF);

  // Category Colors
  static const Color action = Color(0xFFE50914);
  static const Color comedy = Color(0xFFF5C518);
  static const Color drama = Color(0xFF6B5B95);
  static const Color horror = Color(0xFF2C3E50);
  static const Color sciFi = Color(0xFF00D4FF);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x80141414),
      Color(0xFF141414),
    ],
    stops: [0.0, 0.7, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0xCC000000),
    ],
  );

  static const LinearGradient sideGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF141414),
      Colors.transparent,
    ],
  );
}
