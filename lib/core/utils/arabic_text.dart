/// أدوات معالجة النصوص العربية لتقوية البحث.
///
/// يعمل التطبيق بالعربية لذا نحتاج تطبيعًا بسيطًا:
/// إزالة التشكيل وتوحيد الألف والهاء والياء ليطابق البحث
/// "مدرسة" مع "مَدْرَسة" و"إسلام" مع "اسلام" مثلًا.
class ArabicText {
  ArabicText._();

  /// تطبيع نص عربي: إزالة التشكيل والتطويل وتوحيد الحروف.
  static String normalize(String input) {
    var s = input.toLowerCase().trim();

    // إزالة التشكيل والمدّة والتطويل.
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');

    // توحيد الألف.
    s = s.replaceAll('أ', 'ا');
    s = s.replaceAll('إ', 'ا');
    s = s.replaceAll('آ', 'ا');
    s = s.replaceAll('ٱ', 'ا');

    // تاء مربوطة -> هاء.
    s = s.replaceAll('ة', 'ه');

    // ألف مقصورة -> ياء.
    s = s.replaceAll('ى', 'ي');

    return s;
  }

  /// تقطيع النص إلى كلمات مفيدة (بعد التطبيع).
  static List<String> tokens(String input) => normalize(input)
      .split(RegExp('[\\s,،.؛;:()\\[\\]{}"\'!؟]+'))
      .where((t) => t.isNotEmpty)
      .toList();
}
