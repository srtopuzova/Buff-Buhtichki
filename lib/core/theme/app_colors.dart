import 'package:flutter/material.dart';

class AppColors {
  // Background
  static const Color background = Color(0xFFF0F4FF);
  static const Color surface = Color(0xFFFFFFFF);

  // Brand colors
  static const Color medShelf = Color(0xFF2563EB);
  static const Color medShelfLight = Color(0xFFEFF6FF);
  static const Color medShelfDark = Color(0xFF1D4ED8);

  static const Color redShelf = Color(0xFFDC2626);
  static const Color redShelfLight = Color(0xFFFEF2F2);
  static const Color redShelfDark = Color(0xFFB91C1C);

  static const Color pharmacy = Color(0xFF7C3AED);
  static const Color pharmacyLight = Color(0xFFF5F3FF);
  static const Color pharmacyDark = Color(0xFF6D28D9);

  static const Color aiChat = Color(0xFF0891B2);
  static const Color aiChatLight = Color(0xFFE0F2FE);

  // Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoLight = Color(0xFFF0F9FF);

  // Divider / border
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);

  // Shadow
  static const Color shadow = Color(0x14000000);
  static const Color shadowMedium = Color(0x1F000000);

  // Gradient helpers
  static LinearGradient get medShelfGradient => const LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get redShelfGradient => const LinearGradient(
        colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get pharmacyGradient => const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get aiChatGradient => const LinearGradient(
        colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get backgroundGradient => const LinearGradient(
        colors: [Color(0xFFF0F4FF), Color(0xFFE8EEFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}
