import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// مساعد فتح الروابط الخارجية.
///
/// السياسة: يُستخدم هذا المساعد حصريًا لفتح روابط الشرح
/// التي يضيفها صاحب المحتوى في ملفات JSON، وعناصر التواصل.
class AppLauncher {
  AppLauncher._();

  /// فتح رابط خارجي بأمان مع رسالة عند الفشل.
  ///
  /// [context] يُستخدم لعرض رسالة خطأ إن تعذر الفتح.
  static Future<void> openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.hasScheme)) {
      _showError(context, 'الرابط غير صالح.');
      return;
    }

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) _showError(context, 'تعذر فتح الرابط.');
    } catch (_) {
      if (context.mounted) _showError(context, 'تعذر فتح الرابط.');
    }
  }

  /// فتح بريد تواصل.
  static Future<void> openEmail(BuildContext context, String email) =>
      openUrl(context, 'mailto:$email');

  /// فتح محادثة واتساب (اختياري، يعمل إن أُدخل رقم).
  static Future<void> openWhatsApp(BuildContext context, String number) =>
      openUrl(context, 'https://wa.me/$number');

  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
