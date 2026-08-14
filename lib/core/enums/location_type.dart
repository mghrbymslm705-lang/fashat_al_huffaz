/// مكان تنفيذ النشاط: داخل القاعة أو خارجها أو الاثنان.
enum LocationType {
  /// لا يهم (يُستخدم في الفلاتر والمساعد الذكي).
  any,

  /// داخل القاعة.
  inside,

  /// خارج القاعة.
  outside,

  /// يمكن تنفيذه داخلًا وخارجًا.
  both;

  /// التسمية العربية.
  String get label {
    switch (this) {
      case LocationType.any:
        return 'لا يهم';
      case LocationType.inside:
        return 'داخل القاعة';
      case LocationType.outside:
        return 'خارج القاعة';
      case LocationType.both:
        return 'داخل أو خارج';
    }
  }

  /// أيقونة الموقع.
  String get icon {
    switch (this) {
      case LocationType.any:
        return 'tune';
      case LocationType.inside:
        return 'meeting_room';
      case LocationType.outside:
        return 'park';
      case LocationType.both:
        return 'public';
    }
  }

  /// تحويل نص من ملف JSON إلى القيمة المقابلة.
  ///
  /// يدعم الصيغ العربية والإنجليزية:
  /// داخل / خارج / الاثنان / inside / outside / both ...
  static LocationType fromRaw(String? raw) {
    if (raw == null) return LocationType.inside;
    final r = raw.trim();
    final lower = r.toLowerCase();

    final hasInside = r.contains('داخل') || lower.contains('inside') || lower.contains('in');
    final hasOutside = r.contains('خارج') || lower.contains('outside') || lower.contains('out');

    if (hasInside && hasOutside) return LocationType.both;
    if (hasInside) return LocationType.inside;
    if (hasOutside) return LocationType.outside;
    if (lower.contains('both') || lower.contains('any')) return LocationType.both;
    return LocationType.inside;
  }
}
