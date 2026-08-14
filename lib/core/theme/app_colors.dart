import 'package:flutter/material.dart';

/// لوحة الألوان المعتمدة في هوية التطبيق.
///
/// أخضر للنمو والقرآن، أزرق للمرح، أصفر ذهبي للجوائز والحماس،
/// مع خلفية بيضاء مائلة للرمادي الفاتح.
class AppColors {
  AppColors._();

  /// الأخضر الرئيسي (النمو والقرآن).
  static const Color primary = Color(0xFF22C55E);

  /// درجة أغمق من الأخضر للتفاصيل والتباين.
  static const Color primaryDark = Color(0xFF16A34A);

  /// الأزرق (المرح والنشاط).
  static const Color blue = Color(0xFF3B82F6);

  /// الأصفر الذهبي (الجوائز والحماس).
  static const Color gold = Color(0xFFFBBF24);

  /// برتقالي للحركة والنشاط.
  static const Color orange = Color(0xFFF97316);

  /// بنفسجي للعب الجماعية.
  static const Color purple = Color(0xFF8B5CF6);

  /// وردي للأطفال.
  static const Color pink = Color(0xFFEC4899);

  /// سماوي للبرامج التربوية.
  static const Color teal = Color(0xFF06B6D4);

  /// خلفية فاتحة مائلة للرمادي.
  static const Color backgroundLight = Color(0xFFF4F6F8);

  /// نص أساسي.
  static const Color textPrimary = Color(0xFF1F2937);

  /// نص ثانوي.
  static const Color textSecondary = Color(0xFF6B7280);

  /// خلفية البطاقات في الوضع الفاتح.
  static const Color surface = Colors.white;

  /// خلفية البطاقات في الوضع الليلي.
  static const Color surfaceDark = Color(0xFF1E2430);
}
