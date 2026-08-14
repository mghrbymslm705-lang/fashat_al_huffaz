import '../../core/enums/location_type.dart';
import '../../core/enums/movement_level.dart';
import '../../core/enums/suggest_type.dart';
import 'range_value.dart';

/// مجموعة معايير التصفية التي يستخدمها كلٌّ من:
/// 1) صفحة الفلاتر الذكية.
/// 2) المساعد الذكي "اقترح لي نشاطًا".
///
/// القيم الافتراضية تعني "لا يهم / كل النتائج".
class ActivityFilter {
  const ActivityFilter({
    this.categoryIds = const [],
    this.location = LocationType.any,
    this.movement = MovementLevel.any,
    this.hasTools,
    this.age = const RangeValue(0, 0),
    this.participants = const RangeValue(0, 0),
    this.duration = const RangeValue(0, 0),
    this.type = SuggestType.any,
  });

  /// معرّفات الأقسام المطلوبة (فارغ = كل الأقسام).
  final List<String> categoryIds;

  /// مكان التنفيذ.
  final LocationType location;

  /// مستوى الحركة.
  final MovementLevel movement;

  /// هل تتوفر أدوات؟ (null = لا يهم).
  final bool? hasTools;

  /// نطاق العمر المطلوب (0،0 = لا يهم).
  final RangeValue age;

  /// نطاق عدد المشاركين (0،0 = لا يهم).
  final RangeValue participants;

  /// نطاق المدة بالدقائق (0،0 = لا يهم).
  final RangeValue duration;

  /// نوع النشاط للمساعد الذكي.
  final SuggestType type;

  static const RangeValue _empty = RangeValue(0, 0);

  /// حارس لتمييز "لم يُمرَّر" عن "مُرِّر null صراحةً".
  static const Object _unset = Object();

  /// هل المعايير محددة (يوجد على الأقل شرط واحد فعال)؟
  bool get hasCriteria =>
      categoryIds.isNotEmpty ||
      location != LocationType.any ||
      movement != MovementLevel.any ||
      hasTools != null ||
      age != _empty ||
      participants != _empty ||
      duration != _empty ||
      type != SuggestType.any;

  /// عدد الشروط الفعّالة.
  int get activeCount {
    var count = 0;
    if (categoryIds.isNotEmpty) count++;
    if (location != LocationType.any) count++;
    if (movement != MovementLevel.any) count++;
    if (hasTools != null) count++;
    if (age != _empty) count++;
    if (participants != _empty) count++;
    if (duration != _empty) count++;
    if (type != SuggestType.any) count++;
    return count;
  }

  /// نسخة من الفلتر مع تغيير قيمة واحدة (تستخدمها واجهة الفلاتر).
  ActivityFilter copyWith({
    List<String>? categoryIds,
    LocationType? location,
    MovementLevel? movement,
    Object? hasTools = _unset,
    RangeValue? age,
    RangeValue? participants,
    RangeValue? duration,
    SuggestType? type,
  }) {
    return ActivityFilter(
      categoryIds: categoryIds ?? this.categoryIds,
      location: location ?? this.location,
      movement: movement ?? this.movement,
      hasTools: hasTools == _unset ? this.hasTools : hasTools as bool?,
      age: age ?? this.age,
      participants: participants ?? this.participants,
      duration: duration ?? this.duration,
      type: type ?? this.type,
    );
  }
}
