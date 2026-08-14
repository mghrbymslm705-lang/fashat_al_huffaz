import 'package:flutter/foundation.dart' hide Category;

import '../../data/datasources/prefs_datasource.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_filter.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/suggestion.dart';
import '../../domain/repositories/activity_repository.dart';

/// المزوّد المركزي للمحتوى.
///
/// يربط صفحة العرض بمستودع الأنشطة ويحتفظ بحالة:
/// البحث، الفلاتر، المفضلة، ونتائج المساعد الذكي.
class ActivityProvider extends ChangeNotifier {
  ActivityProvider(this._repository, this._prefs);

  final ActivityRepository _repository;
  final PrefsDatasource _prefs;

  bool _isLoading = false;
  String? _error;

  ActivityFilter _activeFilter = const ActivityFilter();
  String _searchQuery = '';
  List<Suggestion> _suggestions = const [];

  String? _lastActivityId;
  DateTime? _lastActivityAt;

  // -------------------- الحالة العامة --------------------

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// تحميل كل المحتوى عند إقلاع التطبيق.
  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.loadContent();
    } catch (e) {
      _error = 'تعذر تحميل المحتوى: $e';
    } finally {
      _isLoading = false;
      _invalidateDerived();
      notifyListeners();
    }
  }

  // -------------------- المحتوى --------------------

  List<Category> get categories => _repository.getCategories();

  List<Activity> get allActivities => _repository.getAllActivities();

  int get totalCount => _totalCountCache ??= _repository.getAllActivities().length;

  Category? categoryFor(String id) => _repository.categoryById(id);

  int categoryCount(String categoryId) => _repository.countByCategory(categoryId);

  List<Activity> activitiesFor(String categoryId) =>
      _repository.getActivitiesByCategory(categoryId);

  // -------------------- البحث --------------------

  String get searchQuery => _searchQuery;

  List<Activity> get searchResults => _repository.search(_searchQuery);

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // -------------------- الفلاتر --------------------

  ActivityFilter get activeFilter => _activeFilter;

  bool get hasActiveFilter => _activeFilter.hasCriteria;

  int get activeFilterCount => _activeFilter.activeCount;

  List<Activity> get filteredResults => _repository.applyFilter(_activeFilter);

  void setFilter(ActivityFilter filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  void clearFilter() {
    _activeFilter = const ActivityFilter();
    notifyListeners();
  }

  // -------------------- المساعد الذكي --------------------

  List<Suggestion> get suggestions => _suggestions;

  bool get hasSuggestions => _suggestions.isNotEmpty;

  /// تشغيل الاقتراح داخل قاعدة البيانات المحلية فقط.
  void runSuggest(ActivityFilter filter) {
    _suggestions = _repository.suggest(filter);
    notifyListeners();
  }

  void clearSuggestions() {
    _suggestions = const [];
    notifyListeners();
  }

  // -------------------- المفضلة --------------------

  bool isFavorite(String id) => _repository.isFavorite(id);

  /// تبديل حالة المفضلة. تُرجع الحالة الجديدة (true = أُضيف).
  Future<bool> toggleFavorite(String id) async {
    final wasFavorite = _repository.isFavorite(id);
    await _repository.toggleFavorite(id);
    _favoritesCache = null;
    notifyListeners();
    return !wasFavorite;
  }

  List<Activity>? _favoritesCache;

  /// أنشطة المفضلة الحالية (تُحسب مرة واحدة وتُخزَّن حتى التبديل).
  List<Activity> get favoriteActivities => _favoritesCache ??=
      _repository.getAllActivities().where((a) => _repository.isFavorite(a.id)).toList();

  int get favoriteCount => favoriteActivities.length;

  // -------------------- آخر نشاط مستخدم --------------------

  /// تهيئة آخر نشاط فُتح (يُستدعى مرة واحدة عند إقلاع التطبيق).
  Future<void> initLastActivity() async {
    _lastActivityId = await _prefs.loadLastActivityId();
    final rawAt = await _prefs.loadLastActivityAt();
    _lastActivityAt = rawAt == null ? null : DateTime.tryParse(rawAt);
    notifyListeners();
  }

  /// آخر نشاط فتحه المستخدم، أو null إن لم يُستخدم أي نشاط بعد.
  Activity? get lastUsedActivity {
    final id = _lastActivityId;
    if (id == null || id.isEmpty) return null;
    for (final activity in _repository.getAllActivities()) {
      if (activity.id == id) return activity;
    }
    return null;
  }

  DateTime? get lastUsedAt => _lastActivityAt;

  /// تسجيل أن النشاط [id] هو آخر نشاط استخدمه المستخدم.
  Future<void> markActivityUsed(String id) async {
    await _prefs.saveLastActivity(id);
    _lastActivityId = id;
    _lastActivityAt = DateTime.now();
    notifyListeners();
  }

  // -------------------- اقتراحات الصفحة الرئيسية --------------------

  Activity? _dailyPickCache;
  int _dailyPickDay = -1;
  List<Activity>? _suggestedCache;
  int? _totalCountCache;

  /// إبطال القيم المشتقة بعد تغيّر المحتوى (تحميل/استيراد/مفضلة).
  void _invalidateDerived() {
    _dailyPickCache = null;
    _dailyPickDay = -1;
    _suggestedCache = null;
    _totalCountCache = null;
    _favoritesCache = null;
  }

  /// نشاط "اختيار اليوم": اختيار بسيط ثابت لكل يوم من التاريخ.
  ///
  /// لا يستخدم ذكاءً اصطناعيًا؛ يُختار من قاعدة البيانات المحلية فقط.
  Activity? get activityOfTheDay {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    if (_dailyPickCache != null && _dailyPickDay == dayOfYear) {
      return _dailyPickCache;
    }
    final all = _repository.getAllActivities();
    _dailyPickCache = all.isEmpty ? null : all[dayOfYear % all.length];
    _dailyPickDay = dayOfYear;
    return _dailyPickCache;
  }

  /// أنشطة مقترحة للصفحة الرئيسية (حتى 4): المفضلة أولًا
  /// مع تنويع الأقسام، ثم البقية حتى اكتمال العدد.
  List<Activity> get suggestedActivities => _suggestedCache ??= _buildSuggested();

  List<Activity> _buildSuggested() {
    final all = _repository.getAllActivities();
    if (all.isEmpty) return const [];

    final favorites = <Activity>[];
    final others = <Activity>[];
    for (final activity in all) {
      if (_repository.isFavorite(activity.id)) {
        favorites.add(activity);
      } else {
        others.add(activity);
      }
    }

    final picked = <Activity>[];
    final seenCategories = <String>{};
    for (final activity in [...favorites, ...others]) {
      if (picked.length >= 4) break;
      if (!seenCategories.add(activity.category)) continue;
      picked.add(activity);
    }
    for (final activity in [...favorites, ...others]) {
      if (picked.length >= 4) break;
      if (picked.contains(activity)) continue;
      picked.add(activity);
    }
    return picked;
  }

  // -------------------- الاستيراد --------------------

  Future<ImportResult> importFile(String filePath) async {
    final result = await _repository.importJsonFile(filePath);
    _invalidateDerived();
    notifyListeners();
    return result;
  }

  Future<ImportResult> importBytes(String fileName, List<int> bytes) async {
    final result = await _repository.importBytes(fileName, bytes);
    _invalidateDerived();
    notifyListeners();
    return result;
  }

  /// استيراد ملف وورد وتصنيف ألعابه تلقائيًا في الأقسام المناسبة.
  Future<ImportResult> importWordBytes(String fileName, List<int> bytes) async {
    final result = await _repository.importWordBytes(fileName, bytes);
    _invalidateDerived();
    notifyListeners();
    return result;
  }

  Future<ImportResult> importFromDocuments() async {
    final result = await _repository.importFromDocuments();
    _invalidateDerived();
    notifyListeners();
    return result;
  }

  // -------------------- المعاينة قبل الاستيراد --------------------

  /// معاينة ملف JSON دون استيراده (تحليل فقط دون تعديل المكتبة).
  Future<ImportPreview> previewJsonBytes(String fileName, List<int> bytes) =>
      _repository.previewJsonBytes(fileName, bytes);

  /// معاينة ملف وورد دون استيراده.
  Future<ImportPreview> previewWordBytes(String fileName, List<int> bytes) =>
      _repository.previewWordBytes(fileName, bytes);

  /// معاينة محتوى مجلد الاستيراد دون استيراده.
  Future<ImportPreview> previewFromDocuments() =>
      _repository.previewFromDocuments();

  Future<String> exportTemplate() =>
      _repository.exportTemplateToDocuments();

  /// مسار مجلد الاستيراد (داخل مستندات التطبيق).
  Future<String> get importFolderPath async =>
      _repository.getImportFolderPath();

  /// المحتوى الخام الأصلي لكل ملف أنشطة (للتنزيل).
  Future<Map<String, String>> loadActivitySourceFiles() =>
      _repository.loadActivitySourceFiles();

  /// محتوى ملف قالب النشاط (للتنزيل).
  Future<String> readTemplate() => _repository.readTemplateContent();
}
