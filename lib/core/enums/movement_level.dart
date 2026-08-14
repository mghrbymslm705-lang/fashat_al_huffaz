/// مستوى حركة النشاط: هادئة أم حركية.
enum MovementLevel {
  /// لا يهم (يُستخدم في الفلاتر فقط).
  any,

  /// نشاط هادئ.
  quiet,

  /// نشاط حركي.
  active;

  /// التسمية العربية.
  String get label {
    switch (this) {
      case MovementLevel.any:
        return 'لا يهم';
      case MovementLevel.quiet:
        return 'هادئة';
      case MovementLevel.active:
        return 'حركية';
    }
  }

  /// أيقونة المستوى.
  String get icon {
    switch (this) {
      case MovementLevel.any:
        return 'tune';
      case MovementLevel.quiet:
        return 'self_improvement';
      case MovementLevel.active:
        return 'directions_run';
    }
  }

  /// تحويل نص من ملف JSON (عربي أو إنجليزي) إلى القيمة المقابلة.
  ///
  /// يدعم الصيغ: حركية / حَرَكِيّ / active / 1 ... وإلا عاد هادئًا.
  static MovementLevel fromRaw(String? raw) {
    if (raw == null) return MovementLevel.quiet;
    final r = raw.trim();
    final lower = r.toLowerCase();
    if (r.contains('حرك') || lower == 'active' || lower == '1' || lower == 'high') {
      return MovementLevel.active;
    }
    return MovementLevel.quiet;
  }
}
