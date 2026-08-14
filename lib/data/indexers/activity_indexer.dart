import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_text.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/category.dart';
import '../datasources/local_activity_datasource.dart';
import '../models/activity_model.dart';
import '../models/category_resolver.dart';

/// فهرس المحتوى: يبني ويحافظ على قائمة الأنشطة والأقسام في الذاكرة.
///
/// المسؤوليات:
/// - تحويل الملفات الخام إلى كيانات [Activity].
/// - منع التكرار (بنفس المعرّف مع الاحتفاظ بالإصدار الأحدث).
/// - إنشاء أقسام ديناميكية لأي قسم غير معرّف في categories.json.
/// - بناء فهارس سريعة للبحث والتصفية.
class ActivityIndexer {
  final Map<String, Activity> _byId = {};
  final Map<String, Category> _dynamicCategories = {};
  final Set<String> _knownFileNames = {};

  List<Category> _declaredCategories = const [];

  // القيم المؤقتة: تُبنى مرة واحدة عند أول طلب بعد أي تغيير.
  List<Category> _cachedCategories = const [];
  List<Activity> _cachedAll = const [];
  Map<String, Category> _categoryById = {};
  Map<String, int> _categoryCounts = {};
  Map<String, String> _normalizedSearchText = {};
  bool _dirty = true;

  // -------------------- البناء --------------------

  /// إعادة بناء كامل الفهرس من الملفات (يُستخدم عند الإقلاع).
  void rebuild({
    required List<Category> declaredCategories,
    required List<RawActivityFile> files,
  }) {
    _byId.clear();
    _dynamicCategories.clear();
    _knownFileNames.clear();
    _declaredCategories = List.of(declaredCategories);

    for (final file in files) {
      _indexFile(file);
    }
    _markDirty();
  }

  /// فهرسة ملف واحد (يُستخدم عند الاستيراد).
  void _indexFile(RawActivityFile file) {
    _knownFileNames.add(file.fileName);
    for (final raw in extract(file)) {
      _merge(_buildActivity(raw, file.fileName));
    }
  }

  /// استخراج قائمة الخرائط الخام من ملف (يدعم عدة صيغ).
  List<Map<String, dynamic>> extract(RawActivityFile file) {
    final data = file.data;
    final list = <Object?>[];

    if (data is List) {
      list.addAll(data);
    } else if (data is Map) {
      final nested = data['activities'] ??
          data['items'] ??
          data['games'] ??
          data['الأنشطة'] ??
          data['data'];
      if (nested is List) {
        list.addAll(nested);
      } else if (data.containsKey('title')) {
        // كائن يمثل نشاطًا واحدًا.
        list.add(data);
      }
    }

    return list.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  /// إضافة أو تحديث نشاط من خريطة خام. تُرجع حالة الإضافة.
  ///
  /// - أضيف جديد: `(true, false)`
  /// - حُدّث (إصدار أحدث): `(false, true)`
  /// - مكرر/أقدم: `(false, false)`
  ({bool added, bool updated}) addOrUpdate(Map<String, dynamic> raw, String fileName) {
    final activity = _buildActivity(raw, fileName);
    final existing = _byId[activity.id];
    if (existing == null) {
      _merge(activity);
      return (added: true, updated: false);
    }
    if (activity.version > existing.version) {
      _merge(activity);
      return (added: false, updated: true);
    }
    return (added: false, updated: false);
  }

  /// حالة إضافة/تحديث نشاط دون تغيير الفهرس (للمعاينة قبل الاستيراد).
  ///
  /// تُرجع نفس معايير [addOrUpdate] لكنها لا تُدخل النشاط ولا تُنشئ
  /// أقسامًا ديناميكية، فتكون الأرقام حقيقية من الملف ودون أي أثر جانبي.
  ({bool added, bool updated}) previewStatus(
    Map<String, dynamic> raw,
    String fileName,
  ) {
    final activity = _buildActivity(raw, fileName, registerCategory: false);
    final existing = _byId[activity.id];
    if (existing == null) return (added: true, updated: false);
    if (activity.version > existing.version) return (added: false, updated: true);
    return (added: false, updated: false);
  }

  Activity _buildActivity(
    Map<String, dynamic> raw,
    String fileName, {
    bool registerCategory = true,
  }) {
    final activity = ActivityModel.fromJson(raw, sourceFile: fileName);
    final resolved = CategoryResolver.resolve(activity.category);

    // قسم غير معروف: يُنشأ قسم ديناميكي بعرض اسمه الأصلي.
    if (registerCategory && !_isDeclared(resolved)) {
      _dynamicCategories.putIfAbsent(
        resolved,
        () => Category(
          id: resolved,
          name: activity.category.trim().isNotEmpty
              ? activity.category.trim()
              : resolved,
          icon: 'star',
          color: AppColors.purple.toARGB32(),
        ),
      );
    }

    return _copyWithCategory(activity, resolved);
  }

  void _merge(Activity activity) {
    final existing = _byId[activity.id];
    if (existing == null || activity.version >= existing.version) {
      _byId[activity.id] = activity;
      _markDirty();
    }
  }

  // -------------------- القراءة --------------------

  /// إعادة بناء القيم المؤقتة عند تغيّر المحتوى (تُستدعى عند أول طلب).
  void _rebuildCaches() {
    final dynamicVals = _dynamicCategories.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    _cachedCategories = [..._declaredCategories, ...dynamicVals];

    final sorted = _byId.values.toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    _cachedAll = List.unmodifiable(sorted);

    _categoryById = {for (final c in _cachedCategories) c.id: c};
    _categoryCounts = {};
    _normalizedSearchText = {};
    for (final a in _cachedAll) {
      _categoryCounts.update(a.category, (v) => v + 1, ifAbsent: () => 1);
      _normalizedSearchText[a.id] = ArabicText.normalize(a.searchText);
    }
    _dirty = false;
  }

  List<Category> get categories {
    if (_dirty) _rebuildCaches();
    return _cachedCategories;
  }

  List<Activity> get allActivities {
    if (_dirty) _rebuildCaches();
    return _cachedAll;
  }

  Activity? byId(String id) {
    if (_dirty) _rebuildCaches();
    return _byId[id];
  }

  /// نص بحث مُطبّع جاهز لنشاط (لتسريع البحث اللحظي).
  String normalizedSearchText(String id) {
    if (_dirty) _rebuildCaches();
    return _normalizedSearchText[id] ?? '';
  }

  Category? categoryById(String id) {
    if (_dirty) _rebuildCaches();
    return _categoryById[id];
  }

  /// عدد أنشطة قسم معيّن (بدون فحص كل القائمة).
  int countByCategory(String id) {
    if (_dirty) _rebuildCaches();
    return _categoryCounts[id] ?? 0;
  }

  Set<String> get knownFileNames => Set.unmodifiable(_knownFileNames);

  bool _isDeclared(String id) =>
      _declaredCategories.any((c) => c.id == id);

  void _markDirty() {
    _dirty = true;
  }

  static Activity _copyWithCategory(Activity activity, String category) {
    // Activity كيان ثابت؛ لا يمكن تغيير category مباشرة لذا نعيد بناءه.
    return Activity(
      id: activity.id,
      title: activity.title,
      category: category,
      types: activity.types,
      image: activity.image,
      description: activity.description,
      goal: activity.goal,
      participants: activity.participants,
      age: activity.age,
      duration: activity.duration,
      movement: activity.movement,
      location: activity.location,
      tools: activity.tools,
      steps: activity.steps,
      benefits: activity.benefits,
      tips: activity.tips,
      tags: activity.tags,
      videoUrl: activity.videoUrl,
      source: activity.source,
      favorite: activity.favorite,
      version: activity.version,
      isDemo: activity.isDemo,
    );
  }
}
