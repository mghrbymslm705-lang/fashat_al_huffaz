import '../../domain/entities/range_value.dart';
import '../constants/app_constants.dart';

/// أدوات تحويل النطاقات من الصيغ المرنة في ملفات JSON إلى [RangeValue].
///
/// يدعم المحلل هذه الصيغ:
/// 1) رقم صحيح:         `"participants": 10`
/// 2) سلسلة مفردة:      `"participants": "10"`
/// 3) سلسلة نطاق:       `"participants": "6-12"` أو `"6 - 12"`
/// 4) كائن صريح:        `"participants": {"min": 6, "max": 12}`
/// 5) كائن بمفاتيح بديلة: `{"from": 6, "to": 12}` أو `{"start": 6, "end": 12}`
class RangeParser {
  RangeParser._();

  /// تحليل أي قيمة إلى نطاق، مع قيمة افتراضية عند عدم وجود بيانات.
  static RangeValue parse(Object? value, {RangeValue fallback = const RangeValue(0, 0)}) {
    if (value == null) return fallback;

    // 1) رقم صحيح.
    if (value is num) {
      final v = value.toInt();
      return RangeValue(v, v);
    }

    if (value is String) {
      return _parseString(value);
    }

    if (value is Map) {
      return _parseMap(value, fallback);
    }

    return fallback;
  }

  static RangeValue _parseString(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return const RangeValue(0, 0);

    // نطاق مثل "6-12" أو "6 - 12" أو "6..12".
    final match = RegExp(r'(\d+)\s*(?:[-–:.]{1,3}|\s+إلى\s+|\s+الى\s+)\s*(\d+)').firstMatch(s);
    if (match != null) {
      final min = int.parse(match.group(1)!);
      final max = int.parse(match.group(2)!);
      return RangeValue(min, max < min ? min : max);
    }

    // "12 فأكثر" أو "12+" = نطاق مفتوح.
    final openMatch = RegExp(r'(\d+)\s*(?:\+|فأكثر|فما فوق)').firstMatch(s);
    if (openMatch != null) {
      final min = int.parse(openMatch.group(1)!);
      return RangeValue(min, AppConstants.unknownMax);
    }

    // رقم مفرد.
    final single = int.tryParse(s);
    if (single != null) return RangeValue(single, single);

    return const RangeValue(0, 0);
  }

  static RangeValue _parseMap(Map value, RangeValue fallback) {
    final min = _readInt(value, const ['min', 'from', 'start', 'أقل']);
    final max = _readInt(value, const ['max', 'to', 'end', 'أكثر']);

    if (min == null && max == null) return fallback;
    if (min == null) return RangeValue(max!, max);
    if (max == null) return RangeValue(min, AppConstants.unknownMax);
    return RangeValue(min, max < min ? min : max);
  }

  static int? _readInt(Map map, List<String> keys) {
    for (final key in keys) {
      final raw = map[key];
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw.trim());
    }
    return null;
  }
}
