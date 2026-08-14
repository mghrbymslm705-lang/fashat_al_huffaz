import '../../core/enums/location_type.dart';
import '../../core/enums/movement_level.dart';
import '../../core/enums/suggest_type.dart';
import 'activity_source.dart';
import 'range_value.dart';

/// كيان النشاط (اللعبة / المسابقة / البرنامج).
///
/// يُبنى حصريًا من ملفات JSON التي يضيفها صاحب المحتوى،
/// ولا يقوم التطبيق بإنشاء أو تعديل محتوى أي نشاط.
class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.category,
    required this.types,
    this.image = '',
    this.description = '',
    this.goal = '',
    required this.participants,
    required this.age,
    required this.duration,
    this.movement = MovementLevel.quiet,
    this.location = LocationType.inside,
    this.tools = const [],
    this.steps = const [],
    this.benefits = const [],
    this.tips = const [],
    this.tags = const [],
    this.videoUrl = '',
    this.source = const ActivitySource(file: ''),
    this.favorite = false,
    this.version = 1,
    this.isDemo = false,
  });

  /// معرّف فريد للنشاط (يُستخدم للتمييز ومنع التكرار).
  final String id;

  /// اسم النشاط.
  final String title;

  /// معرّف القسم (category id).
  final String category;

  /// أنواع النشاط للمساعد الذكي (تسميات عربية مثل: قرآني، حركي...).
  final List<String> types;

  /// مسار صورة اختياري (ضمن الأصول) أو رابط خارجي أو فارغ للاعتماد على الأيقونة.
  final String image;

  /// وصف مختصر.
  final String description;

  /// الهدف التربوي.
  final String goal;

  /// عدد المشاركين.
  final RangeValue participants;

  /// العمر المناسب.
  final RangeValue age;

  /// المدة بالدقائق.
  final RangeValue duration;

  /// مستوى الحركة.
  final MovementLevel movement;

  /// مكان التنفيذ.
  final LocationType location;

  /// الأدوات المطلوبة.
  final List<String> tools;

  /// خطوات التنفيذ.
  final List<String> steps;

  /// فوائد النشاط.
  final List<String> benefits;

  /// نصائح للمشرف.
  final List<String> tips;

  /// كلمات مساعدة للبحث (اختياري).
  final List<String> tags;

  /// رابط شرح النشاط (يُفتح فقط عند ضغط "مشاهدة الشرح").
  final String videoUrl;

  /// مرجع المصدر الأصلي.
  final ActivitySource source;

  /// هل هو من المفضلة؟ (القيمة الأولية من الملف، والتفضيل الفعلي في الإعدادات).
  final bool favorite;

  /// رقم إصدار النشاط (لمنع التكرار عند الاستيراد وتحديث الأحدث).
  final int version;

  /// هل هو نموذج تجريبي (من ملف القالب)؟
  final bool isDemo;

  /// هل يحتاج النشاط إلى أدوات؟
  bool get needsTools => tools.isNotEmpty;

  /// هل يوجد رابط شرح؟
  bool get hasVideo => videoUrl.trim().isNotEmpty;

  /// هل يطابق أحد أنواعه [type]؟
  bool matchesType(SuggestType type) {
    if (type == SuggestType.any) return true;
    return types.any((t) => SuggestType.fromRaw(t) == type);
  }

  /// نص البحث الموحّد المستخدم في فهرس البحث.
  String get searchText {
    final parts = <String>[
      title,
      description,
      goal,
      category,
      ...types,
      ...tags,
      ...tools,
    ];
    return parts.join(' ');
  }
}
