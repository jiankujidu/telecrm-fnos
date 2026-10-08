import 'package:flutter/material.dart';
import '../config/constants.dart';

/// 应用主题（绿色主题，1:1 还原电销帮）
class AppTheme {
  static const Color primary = Color(Constants.primaryColorValue);
  static const Color primaryDark = Color(0xFF17A866);
  static const Color background = Color(0xFFF5F6F8);
  static const Color textPrimary = Color(0xFF222222);
  static const Color textSecondary = Color(0xFF999999);

  static ThemeData light() {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      colorScheme: ColorScheme.fromSeed(seedColor: primary),
      useMaterial3: true,
    );
  }
}
