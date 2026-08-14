/// أنواع الأنشطة التي يستخدمها المساعد الذكي "اقترح لي نشاطًا".
///
/// ملاحظة: هذه مجرد تصنيفات للمطابقة داخل قاعدة البيانات فقط،
/// ولا ينتج التطبيق أي نشاط من تلقاء نفسه.
enum SuggestType {
  /// قرآني.
  quranic,

  /// حركي.
  kinetic,

  /// ثقافي.
  cultural,

  /// ترفيهي.
  entertainment,

  /// جماعي.
  group,

  /// لا يهم.
  any;

  /// التسمية العربية.
  String get label {
    switch (this) {
      case SuggestType.quranic:
        return 'قرآني';
      case SuggestType.kinetic:
        return 'حركي';
      case SuggestType.cultural:
        return 'ثقافي';
      case SuggestType.entertainment:
        return 'ترفيهي';
      case SuggestType.group:
        return 'جماعي';
      case SuggestType.any:
        return 'لا يهم';
    }
  }

  /// أيقونة النوع.
  String get icon {
    switch (this) {
      case SuggestType.quranic:
        return 'menu_book';
      case SuggestType.kinetic:
        return 'directions_run';
      case SuggestType.cultural:
        return 'emoji_events';
      case SuggestType.entertainment:
        return 'celebration';
      case SuggestType.group:
        return 'groups';
      case SuggestType.any:
        return 'shuffle';
    }
  }

  /// تحويل نص عربي أو إنجليزي إلى النوع المقابل.
  static SuggestType fromRaw(String? raw) {
    if (raw == null) return SuggestType.any;
    final r = raw.trim();
    final lower = r.toLowerCase();

    if (r.contains('قرآن')) return SuggestType.quranic;
    if (r.contains('حرك') || lower == 'kinetic' || lower == 'physical') {
      return SuggestType.kinetic;
    }
    if (r.contains('ثقاف')) return SuggestType.cultural;
    if (r.contains('ترف') || lower.contains('entertain') || lower.contains('fun')) {
      return SuggestType.entertainment;
    }
    if (r.contains('جماع')) return SuggestType.group;
    return SuggestType.any;
  }
}
