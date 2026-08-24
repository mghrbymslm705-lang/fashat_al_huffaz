import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// إعدادات التصميم العام: Material 3 + خط IBM Plex Sans Arabic + RTL.
///
/// ثيم حيوي أنيق يجمع بين المرح والتربية والهوية القرآنية.
class AppTheme {
  AppTheme._();

  /// اسم خط التطبيق (مُضمّن، يعمل دون إنترنت).
  static const String fontFamily = 'IBMPlexSansArabic';

  /// نصف قطر البطاقات الكبيرة.
  static const double cardRadius = 20;

  /// نصف قطر البطاقات الصغيرة.
  static const double chipRadius = 12;

  /// نصف قطر الأزرار.
  static const double buttonRadius = 14;

  // ─────────── الثيم النهاري ───────────

  static ThemeData light() => _base(Brightness.light);

  // ─────────── الثيم الليلي ───────────

  static ThemeData dark() => _base(Brightness.dark);

  // ─────────── البنية الأساسية ───────────

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final seed = isDark ? const Color(0xFF6BAF92) : AppColors.primary;

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      primary: AppColors.primary,
      secondary: AppColors.teal,
      surface: isDark ? AppColors.surfaceDark : AppColors.surface,
      error: AppColors.error,
    );

    final bg = isDark ? const Color(0xFF14171C) : AppColors.background;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: bg,
    );

    return base.copyWith(
      // ── النصوص ──
      textTheme: _textTheme(base, isDark),

      // ── شريط العنوان ──
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white70 : AppColors.textSecondary,
          size: 22,
        ),
      ),

      // ── البطاقات ──
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.divider.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── الشرايح ──
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(chipRadius),
        ),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),

      // ── الأزرار المرفوعة ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      // ── الأزرار المملوءة ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      // ── الأزرار المحيطية ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.primary.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      // ── حقول الإدخال ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF222730) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.7),
          fontFamily: fontFamily,
        ),
      ),

      // ── شريط التنقل السفلي ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.95)
            : AppColors.navBackground.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontFamily: fontFamily,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              fontSize: selected ? 12 : 11,
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary,
            );
          },
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 24,
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.7),
            );
          },
        ),
      ),

      // ── الفواصل ──
      dividerTheme: DividerThemeData(
        thickness: 0.8,
        space: 1,
        color: AppColors.divider.withValues(alpha: 0.7),
      ),

      // ── المفاتيح المنزلقة ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : null,
        ),
      ),

      // ── مؤشرات التقدم ──
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.divider,
      ),

      // ── التنبيهات ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // ─────────── النصوص المُحسّنة ───────────

  static TextTheme _textTheme(ThemeData base, bool isDark) {
    final onBg = isDark ? Colors.white : AppColors.textPrimary;
    final onBgSec = isDark ? Colors.white60 : AppColors.textSecondary;

    return base.textTheme.copyWith(
      // العناوين الرئيسية
      headlineLarge: TextStyle(
        color: onBg,
        fontWeight: FontWeight.w700,
        fontSize: 24,
        height: 1.4,
      ),
      headlineMedium: TextStyle(
        color: onBg,
        fontWeight: FontWeight.w700,
        fontSize: 20,
        height: 1.4,
      ),
      headlineSmall: TextStyle(
        color: onBg,
        fontWeight: FontWeight.w700,
        fontSize: 18,
        height: 1.4,
      ),

      // العناوين الفرعية
      titleLarge: TextStyle(
        color: onBg,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        color: onBg,
        fontWeight: FontWeight.w700,
        fontSize: 15,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        color: onBg,
        fontWeight: FontWeight.w700,
        fontSize: 13.5,
        height: 1.4,
      ),

      // النصوص
      bodyLarge: TextStyle(
        color: onBg,
        fontWeight: FontWeight.w400,
        fontSize: 15,
        height: 1.7,
      ),
      bodyMedium: TextStyle(
        color: onBg,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.65,
      ),
      bodySmall: TextStyle(
        color: onBgSec,
        fontWeight: FontWeight.w400,
        fontSize: 12.5,
        height: 1.5,
      ),

      // التسميات
      labelLarge: TextStyle(
        color: onBg,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      labelMedium: TextStyle(
        color: onBg,
        fontWeight: FontWeight.w400,
        fontSize: 12.5,
      ),
      labelSmall: TextStyle(
        color: onBgSec,
        fontWeight: FontWeight.w400,
        fontSize: 11,
      ),
    );
  }
}
