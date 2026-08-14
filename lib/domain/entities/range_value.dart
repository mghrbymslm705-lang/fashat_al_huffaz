import '../../core/constants/app_constants.dart';

/// قيمة رقمية داخل نطاق [min..max] تُستخدم للأعمار وعدد المشاركين والمدة.
///
/// مرنة لدعم بيانات غير مكتملة: إذا لم يُحدَّد الحد الأقصى تُعتبر القيمة
/// "مفتوحة النهاية" حتى [AppConstants.unknownMax].
class RangeValue {
  const RangeValue(this.min, this.max);

  final int min;
  final int max;

  /// هل النطاق مفتوح النهاية (لم يُحدَّد حد أقصى)؟
  bool get isOpenEnded => max >= AppConstants.unknownMax;

  /// هل النطاق غير محدد (لا توجد بيانات في ملف المحتوى)؟
  ///
  /// نعامل النطاق غير المحدد على أنه "يناسب كل الحالات".
  bool get isUnspecified => min <= 0 && max <= 0;

  /// هل النطاق صالح (الحد الأدنى موجِب أو صفر)؟
  bool get isValid => min >= 0 && max >= min;

  /// تسمية قصيرة مثل: "6 - 12" أو "10".
  String get label {
    if (!isValid) return 'غير محدد';
    if (min == max) return '$min';
    if (isOpenEnded) return '$min فأكثر';
    return '$min - $max';
  }

  /// هل القيمة [value] داخل النطاق؟
  bool contains(int value) => value >= min && value <= max;

  /// مقدار التداخل مع نطاق آخر (0 إن لم يتداخل).
  int overlapWith(RangeValue other) {
    final start = min > other.min ? min : other.min;
    final end = max < other.max ? max : other.max;
    if (end < start) return 0;
    return end - start;
  }

  @override
  bool operator ==(Object other) =>
      other is RangeValue && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);
}
