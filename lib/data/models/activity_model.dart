import '../../core/enums/location_type.dart';
import '../../core/enums/movement_level.dart';
import '../../core/utils/range_parser.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_source.dart';
import '../../domain/entities/range_value.dart';

/// يحوّل خريطة JSON الخاصة بنشاط واحد إلى كيان [Activity].
///
/// البارزز مرنة قدر الإمكان لتقبل ملفات محتوى بصيغ متعددة
/// دون أن يفشل التطبيق (النطاقات تُحلَّ عبر [RangeParser]).
class ActivityModel {
  const ActivityModel._();

  /// [sourceFile] اسم الملف الذي جاء منه النشاط (يُعرض كمرجع في التفاصيل).
  static Activity fromJson(Map<String, dynamic> json, {required String sourceFile}) {
    final rawTitle = json['title']?.toString().trim() ?? '';

    return Activity(
      id: _text(json['id']) ?? _generateId(rawTitle, sourceFile),
      title: rawTitle,
      category: json['category']?.toString() ?? 'other',
      types: _stringList(json['types']).isNotEmpty
          ? _stringList(json['types'])
          : _stringList(json['type']),
      image: _text(json['image']) ?? '',
      description: _text(json['description']) ?? '',
      goal: _text(json['goal']) ?? _text(json['objective']) ?? '',
      participants: RangeParser.parse(json['participants']),
      age: RangeParser.parse(json['age'], fallback: const RangeValue(0, 0)),
      duration: RangeParser.parse(json['duration']),
      movement: MovementLevel.fromRaw(json['movement']?.toString()),
      location: LocationType.fromRaw(json['location']?.toString()),
      tools: _stringList(json['tools']),
      steps: _stringList(json['steps']),
      benefits: _stringList(json['benefits']),
      tips: _stringList(json['tips']),
      tags: _stringList(json['tags']),
      videoUrl: _text(json['videoUrl']) ?? _text(json['video']) ?? '',
      source: _parseSource(json['source'], sourceFile),
      favorite: json['favorite'] == true || json['fav'] == true,
      version: _toInt(json['version']) ?? 1,
      isDemo: json['isDemo'] == true || json['demo'] == true,
    );
  }

  static String? _text(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _toInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static List<String> _stringList(Object? raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }
    final s = raw.toString().trim();
    if (s.isEmpty) return const [];
    return [s];
  }

  static ActivitySource _parseSource(Object? raw, String sourceFile) {
    if (raw is Map) {
      return ActivitySource(
        file: _text(raw['file']) ?? sourceFile,
        name: _text(raw['name']) ?? _text(raw['book']) ?? '',
        page: _text(raw['page']) ?? _text(raw['pageNumber']) ?? '',
      );
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return ActivitySource(file: sourceFile, name: raw.trim());
    }
    return ActivitySource(file: sourceFile);
  }

  /// معرّف ثابت يُولَّد من العنوان والملف عند غياب حقل id.
  ///
  /// (خوارزمية djb2 عربية بسيطة لتكون مستقرة بين عمليات التشغيل).
  static String _generateId(String title, String sourceFile) {
    final input = '$title|$sourceFile'.trim();
    var hash = 5381;
    for (final unit in input.codeUnits) {
      hash = ((hash << 5) + hash) + unit;
      hash = hash & 0x7FFFFFFF;
    }
    return 'auto_${hash.toRadixString(16)}';
  }
}
