import 'package:flutter/material.dart';

/// لوحة ألوان "فسحة الحفّاظ" — هوية ترفيهية تربوية حديثة.
///
/// تجمع بين الحيوية والهدوء: أخضر زمردي أساسي، ألوان مساعدة متناسقة،
/// وخلفيات عاجية دافئة تمنح الشعور بالمرح والراحة والهوية القرآنية.
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════
  //  الألوان الأساسية
  // ═══════════════════════════════════════════════════════

  /// الأخضر الزمردي الأساسي — حيوية وهدوء.
  static const Color primary = Color(0xFF2E9E6E);

  /// أخضر أغمق للنصوص والعناصر النشطة.
  static const Color primaryDark = Color(0xFF1F7A52);

  /// أخضر فاتح جدًا للخلفيات الخفيفة.
  static const Color primaryLight = Color(0xFFE6F7EF);

  // ═══════════════════════════════════════════════════════
  //  ألوان الأقسام (12 قسمًا — كل قسم لون مميز)
  // ═══════════════════════════════════════════════════════

  /// تركوازي — التثبيت والمراجعة.
  static const Color teal = Color(0xFF3AAFA9);

  /// أزرق سماوي — المسابقات القرآنية.
  static const Color blue = Color(0xFF4A90D9);

  /// ذهبي — السيرة والفقه والعقيدة.
  static const Color gold = Color(0xFFD4A843);

  /// بنفسجي — ألعاب الذاكرة والألغاز.
  static const Color purple = Color(0xFF7C6FBF);

  /// وردي مرجاني — الأنشطة الجماعية.
  static const Color pink = Color(0xFFD4789A);

  /// برتقالي مشمشي — الأنشطة الحركية.
  static const Color orange = Color(0xFFD98E4A);

  /// أحمر مطفأ — المسابقات السريعة.
  static const Color red = Color(0xFFD4645C);

  /// أخضر زمردي فاتح — الإبداع والتعبير.
  static const Color greenLight = Color(0xFF4DB6A0);

  /// أزرق فاتح — البحث والاكتشاف.
  static const Color blueLight = Color(0xFF5B9BD5);

  /// بني ذهبي — القراءة والمكتبة.
  static const Color brown = Color(0xFFB89B5E);

  /// بنفسجي فاتح — الاستماع والإنصات.
  static const Color purpleLight = Color(0xFF9B8CC4);

  /// خطأ / أحمر.
  static const Color error = Color(0xFFD4645C);

  // ═══════════════════════════════════════════════════════
  //  الخلفيات والأسطح
  // ═══════════════════════════════════════════════════════

  /// خلفية عاجية دافئة — main background.
  static const Color background = Color(0xFFF9F6F1);

  /// خلفية البطاقات في الوضع الفاتح: أبيض عاجي دافئ.
  static const Color surface = Color(0xFFFEFDFB);

  /// خلفية البطاقات في الوضع الليلي.
  static const Color surfaceDark = Color(0xFF1C2028);

  /// خلفية الشريط السفلي.
  static const Color navBackground = Color(0xFFFEFDFB);

  // ═══════════════════════════════════════════════════════
  //  النصوص
  // ═══════════════════════════════════════════════════════

  /// نص أساسي: بني غامق (أرقى من الأسود النقي).
  static const Color textPrimary = Color(0xFF2C2417);

  /// نص ثانوي: رمادي بني.
  static const Color textSecondary = Color(0xFF8A7E72);

  /// نص على خلفيات ملونة.
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ═══════════════════════════════════════════════════════
  //  الفواصل والحدود
  // ═══════════════════════════════════════════════════════

  /// فواصل ناعمة.
  static const Color divider = Color(0xFFE8E2DA);

  /// حدود البطاقات.
  static const Color border = Color(0xFFE0D8CE);

  // ═══════════════════════════════════════════════════════
  //  مساعدة: ألوان الأقسام حسب المعرّف
  // ═══════════════════════════════════════════════════════

  /// يُرجع لون القسم حسب المعرّف (id).
  static Color categoryColor(String id) {
    switch (id) {
      case 'hifdh':
        return primary;
      case 'murajaa':
        return teal;
      case 'quranic':
        return blue;
      case 'islamic':
        return gold;
      case 'memory':
        return purple;
      case 'group':
        return pink;
      case 'kinetic':
        return orange;
      case 'quick':
        return red;
      case 'creative':
        return greenLight;
      case 'research':
        return blueLight;
      case 'reading':
        return brown;
      case 'listen':
        return purpleLight;
      default:
        return primary;
    }
  }
}
