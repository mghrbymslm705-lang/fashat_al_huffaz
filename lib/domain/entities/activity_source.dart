/// مرجع مصدر النشاط: يربط كل نشاط بالملف أو الكتاب الذي استُخرج منه.
///
/// هذه المعلومة إلزامية سياسيًا (سياسة إدارة المحتوى):
/// كل نشاط يحتفظ بمرجعه الأصلي ويعرضه في صفحة التفاصيل.
class ActivitySource {
  const ActivitySource({
    required this.file,
    this.name = '',
    this.page = '',
  });

  /// اسم الملف الذي جاء منه النشاط (يُعرض للمستخدم).
  final String file;

  /// اسم الكتاب أو المرجع (اختياري).
  final String name;

  /// رقم الصفحة أو المرجع (اختياري).
  final String page;

  /// هل يوجد اسم كتاب إضافي؟
  bool get hasBookName => name.trim().isNotEmpty;

  /// وصف مصدر كامل.
  String get fullLabel {
    final parts = <String>[
      if (name.trim().isNotEmpty) name.trim(),
      if (page.trim().isNotEmpty) 'صفحة ${page.trim()}',
      file.trim(),
    ];
    return parts.join(' • ');
  }

  /// هل المصدر رابط خارجي قابل للفتح والتحميل؟
  bool get isExternalUrl {
    final trimmed = file.trim().toLowerCase();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }
}
