import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds - Modern Deep Dark SaaS
  static const Color background = Color(0xFF0B101B);
  static const Color surface = Color(0xFF141C2B);
  static const Color surfaceLight = Color(0xFF1E283D);

  // Accents matching the mockups
  static const Color primary = Color(0xFF246BFD); // Vibrant Electric Royal Blue
  static const Color secondary = Color(0xFFFF7A00); // Vivid Orange for Center FAB

  // Text Hierarchy
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF8A99AD);
  static const Color textMuted = Color(0xFF5A687D);

  // Status Colors
  static const Color success = Color(0xFF00D26A); // Fresh Emerald Green
  static const Color error = Color(0xFFFF4757); // Coral Red
  static const Color warning = Color(0xFFFF9F43); // Warm Amber Orange
  static const Color info = Color(0xFF0EA5E9); // Cyan / Sky Blue

  // Category Icon Accent Colors (Matching Screen #1)
  static const Color catAi = Color(0xFF8B5CF6); // Purple / Violet
  static const Color catTtk = Color(0xFFFF7A00); // Orange
  static const Color catMenu = Color(0xFFE67E22); // Warm Brown / Amber
  static const Color catPurchases = Color(0xFF10B981); // Emerald
  static const Color catWarehouse = Color(0xFF0EA5E9); // Sky Blue
  static const Color catSales = Color(0xFF6366F1); // Indigo
  static const Color catStaff = Color(0xFF06B6D4); // Cyan / Teal
  static const Color catFinance = Color(0xFFF59E0B); // Gold Amber
  static const Color catReports = Color(0xFF94A3B8); // Slate
  static const Color catKitchen = Color(0xFFFF5722); // Deep Orange
  static const Color catTables = Color(0xFF246BFD); // Royal Blue

  // Custom Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF246BFD), Color(0xFF00C6FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF9500), Color(0xFFFF5E00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
