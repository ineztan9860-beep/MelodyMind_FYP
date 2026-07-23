import 'package:flutter/material.dart';

class AppColors {
  static const Color navy = Color(0xFF1E3A8A);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color background = Color(0xFFF8FAFC);
  static const Color slate = Color(0xFF0F172A);
  static const Color muted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color white = Colors.white;
  
  // Difficulty levels
  static const Color easyBadgeBg = Color(0xFFD1FAE5);
  static const Color easyBadgeText = Color(0xFF10B981);
  static const Color mediumBadgeBg = Color(0xFFFEF3C7);
  static const Color mediumBadgeText = Color(0xFFF59E0B);
  static const Color hardBadgeBg = Color(0xFFFFE4E6);
  static const Color hardBadgeText = Color(0xFFEF4444);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [navy, Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
