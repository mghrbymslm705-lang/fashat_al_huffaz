import 'dart:convert';

import '../../core/utils/arabic_text.dart';
import '../../domain/entities/category.dart';

/// يحوّل ملف الأقسام (categories.json) إلى كائنات [Category].
///
/// الصيغ المدعومة:
/// - كائن يحتوي قائمة:  `{"categories": [...]}`
/// - قائمة مباشرة:       `[...]`
class CategoryModel {
  const CategoryModel._();

  static List<Category> fromJsonString(String raw) => parse(json.decode(raw));

  static List<Category> parse(Object? data) {
    final dynamic list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      list = data['categories'] ?? data['cats'] ?? data['sections'] ?? const [];
    } else {
      list = const [];
    }

    return (list as List).map(fromJson).toList();
  }

  static Category fromJson(Object? raw) {
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

    return Category(
      id: _text(map['id']) ?? 'other',
      name: _text(map['name']) ?? _text(map['title']) ?? 'غير مصنف',
      icon: _text(map['icon']) ?? 'star',
      color: _parseColor(map['color']),
      description: _text(map['description']) ?? '',
    );
  }

  static String? _text(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int _parseColor(Object? raw) {
    if (raw is int) return raw;

    if (raw is String) {
      final s = raw.trim();
      if (s.startsWith('#')) {
        final hex = s.substring(1);
        try {
          if (hex.length == 6) return int.parse('FF$hex', radix: 16);
          if (hex.length == 8) return int.parse(hex, radix: 16);
        } catch (_) {
          // تجاهل القيمة غير الصالحة.
        }
      }
      final named = _namedColors[ArabicText.normalize(s)];
      if (named != null) return named;
    }

    return 0xFF9CA3AF; // رمادي محايد.
  }

  static const Map<String, int> _namedColors = {
    'green': 0xFF22C55E,
    'blue': 0xFF3B82F6,
    'gold': 0xFFFBBF24,
    'yellow': 0xFFFBBF24,
    'orange': 0xFFF97316,
    'purple': 0xFF8B5CF6,
    'pink': 0xFFEC4899,
    'teal': 0xFF06B6D4,
    'red': 0xFFEF4444,
    'grey': 0xFF9CA3AF,
    'gray': 0xFF9CA3AF,
  };
}
