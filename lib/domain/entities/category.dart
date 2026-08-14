import 'package:flutter/material.dart' show Color;

/// كيان القسم (التصنيف الرئيسي) مثل: الأنشطة القرآنية، الألعاب الحركية...
///
/// الأقسام قابلة للتعديل عبر ملف categories.json دون تعديل الكود.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.description = '',
  });

  /// معرّف فريد للقسم.
  final String id;

  /// اسم القسم.
  final String name;

  /// اسم أيقونة Material (يُحلَّ في IconResolver).
  final String icon;

  /// لون القسم.
  final int color;

  /// وصف قصير للقسم (اختياري).
  final String description;

  /// Color من القيمة الرقمية.
  Color get colorValue => Color(color);
}
