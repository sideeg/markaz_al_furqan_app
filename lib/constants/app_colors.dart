import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2D5016); // Deep Forest Green
  static const Color primaryVariant = Color(0xFF87A96B); // Sage Green
  static const Color secondary = Color(0xFFD4AF37); // Gold Accent
  
  // Background Colors
  static const Color background = Color(0xFFF5F1E8); // Warm Beige
  static const Color surface = Color(0xFFFEFCF7); // Cream White
  static const Color surfaceVariant = Color(0xFFF0EDE6);
  
  // Text Colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onBackground = Color(0xFF1C1B1F);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF6B7280);
  
  // Status Colors
  static const Color success = Color(0xFF059669);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // Neutral Colors
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);
  
  // Islamic Theme Colors
  static const Color islamicGreen = Color(0xFF00A86B);
  static const Color islamicGold = Color(0xFFFFD700);
  static const Color mosqueBlue = Color(0xFF4A90E2);
  
  // Progress Colors
  static const Color progressBackground = Color(0xFFE5E7EB);
  static const Color progressFill = Color(0xFF10B981);
  
  // Card Colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color cardShadow = Color(0x1A000000);
  
  // Input Colors
  static const Color inputBackground = Color(0xFFF9FAFB);
  static const Color inputBorder = Color(0xFFD1D5DB);
  static const Color inputFocusedBorder = Color(0xFF2D5016);
  static const Color inputErrorBorder = Color(0xFFDC2626);
  
  // Evaluation Colors
  static const Color excellent = Color(0xFF10B981);
  static const Color veryGood = Color(0xFF059669);
  static const Color good = Color(0xFF34D399);
  static const Color needsImprovement = Color(0xFFF59E0B);
  static const Color poor = Color(0xFFEF4444);
  
  // Create Material Color Swatch
  static MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    
    for (double strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    
    return MaterialColor(color.value, swatch);
  }
  
  static MaterialColor get primarySwatch => createMaterialColor(primary);
}

// Extension for evaluation colors
extension EvaluationColors on String {
  Color get evaluationColor {
    switch (this) {
      case 'excellent':
        return AppColors.excellent;
      case 'very_good':
        return AppColors.veryGood;
      case 'good':
        return AppColors.good;
      case 'needs_improvement':
        return AppColors.needsImprovement;
      case 'poor':
        return AppColors.poor;
      default:
        return AppColors.neutral500;
    }
  }
}

