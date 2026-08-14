import 'dart:typed_data';

import '../../core/constants/app_constants.dart';
import '../../core/enums/location_type.dart';
import '../../core/enums/movement_level.dart';
import '../../core/enums/suggest_type.dart';
import '../../core/utils/arabic_text.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_filter.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/range_value.dart';
import '../../domain/entities/suggestion.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/local_activity_datasource.dart';
import '../indexers/activity_indexer.dart';

/// التنفيذ الفعلي لمستودع الأنشطة.
///
/// يجمع بين:
/// - الفهرس المحلي (بحث/تصفية/اقتراح داخل قاعدة البيانات فقط).
/// - إعدادات المفضلة المحفوظة.
/// - استيراد ملفات JSON جديدة.
class ActivityRepositoryImpl implements ActivityRepository {
  ActivityRepositoryImpl(this.datasource);

  final LocalActivityDatasource datasource;
  final ActivityIndexer _indexer = ActivityIndexer();

  Set<String> _favorites = {};
  bool _loaded = false;

  // -------------------- التحميل --------------------

  @override
  Future<void> loadContent() async {
    final categories = await datasource.loadCategories();
    final assetFiles = await datasource.loadActivityFilesFromAssets();
    final docFiles = await datasource.loadActivityFilesFromDocuments();

    _indexer.rebuild(
      declaredCategories: categories,
      files: [...assetFiles, ...docFiles],
    );

    await _loadFavorites();
    _loaded = true;
  }

  @override
  bool get isLoaded => _loaded;

  Future<void> _loadFavorites() async {
    final saved = await datasource.prefs.loadFavoriteIds();

    if (saved.isEmpty && !await datasource.prefs.isFavoritesInitialized()) {
      // أول تشغيل: تهيئة المفضلة من القيمة الافتراضية داخل الملفات.
      _favorites = _indexer.allActivities
          .where((a) => a.favorite)
          .map((a) => a.id)
          .toSet();
      await datasource.prefs.saveFavoriteIds(_favorites);
      await datasource.prefs.markFavoritesInitialized();
    } else {
      _favorites = saved;
    }
  }

  // -------------------- القراءة --------------------

  @override
  List<Category> getCategories() => _indexer.categories;

  @override
  List<Activity> getAllActivities() => _indexer.allActivities;

  @override
  Category? categoryById(String id) => _indexer.categoryById(id);

  @override
  int countByCategory(String categoryId) => _indexer.countByCategory(categoryId);

  @override
  List<Activity> getActivitiesByCategory(String categoryId) =>
      _indexer.allActivities.where((a) => a.category == categoryId).toList();

  // -------------------- البحث --------------------

  @override
  List<Activity> search(String query) {
    final terms = ArabicText.tokens(query);
    if (terms.isEmpty) return _indexer.allActivities;

    final results = _indexer.allActivities.where((a) {
      final text = _indexer.normalizedSearchText(a.id);
      return terms.every(text.contains);
    }).toList();

    results.sort((x, y) {
      final xTitle = _indexer.normalizedSearchText(x.id);
      final yTitle = _indexer.normalizedSearchText(y.id);
      final xIsTitle = terms.every(xTitle.contains) ? 0 : 1;
      final yIsTitle = terms.every(yTitle.contains) ? 0 : 1;
      if (xIsTitle != yIsTitle) return xIsTitle.compareTo(yIsTitle);
      return x.title.compareTo(y.title);
    });

    return results;
  }

  // -------------------- الفلاتر والمساعد الذكي --------------------

  @override
  List<Activity> applyFilter(ActivityFilter filter) {
    if (!filter.hasCriteria) return _indexer.allActivities;
    return _indexer.allActivities
        .where((a) => _strictMatches(a, filter))
        .toList();
  }

  @override
  List<Suggestion> suggest(ActivityFilter filter) {
    final results = <Suggestion>[];
    for (final activity in _indexer.allActivities) {
      final suggestion = _scoreSuggestion(activity, filter);
      if (suggestion.isValid) results.add(suggestion);
    }
    results.sort((x, y) {
      final score = y.score.compareTo(x.score);
      if (score != 0) return score;
      return x.activity.title.compareTo(y.activity.title);
    });
    return results.take(AppConstants.maxSuggestions).toList();
  }

  /// مطابقة صارمة تُستخدم في صفحة الفلاتر الذكية.
  bool _strictMatches(Activity a, ActivityFilter f) {
    if (f.categoryIds.isNotEmpty && !f.categoryIds.contains(a.category)) {
      return false;
    }
    if (f.location != LocationType.any &&
        a.location != LocationType.both &&
        f.location != a.location) {
      return false;
    }
    if (f.movement != MovementLevel.any && f.movement != a.movement) {
      return false;
    }
    // إذا لم تتوفر أدوات فلا يمكن عرض نشاط يحتاج أدوات.
    if (f.hasTools == false && a.needsTools) return false;
    if (f.age.min > 0 && !_filterMatchesRange(a.age, f.age)) return false;
    if (f.participants.min > 0 &&
        !_filterMatchesRange(a.participants, f.participants)) {
      return false;
    }
    if (f.duration.min > 0 &&
        !_filterMatchesRange(a.duration, f.duration)) {
      return false;
    }
    return true;
  }

  /// مطابقة نطاق نشاط مع نطاق مرشّح.
  ///
  /// النطاقات غير المحددة (0،0) في النشاط تُعامَل كأنها "تطابق أي قيمة".
  bool _filterMatchesRange(RangeValue activity, RangeValue filter) {
    if (filter.min <= 0 && filter.max <= 0) return true;
    if (activity.isUnspecified) return true;
    return activity.max >= filter.min && activity.min <= filter.max;
  }

  /// حساب درجة ملاءمة نشاط لمعايير المساعد الذكي.
  Suggestion _scoreSuggestion(Activity a, ActivityFilter f) {
    var score = 0;
    final reasons = <String>[];

    if (f.categoryIds.isNotEmpty && !f.categoryIds.contains(a.category)) {
      return Suggestion.zero(a);
    }

    if (f.location != LocationType.any) {
      if (a.location == LocationType.both || f.location == a.location) {
        score += 15;
        reasons.add('يُقدَّم ${a.location.label}');
      } else {
        return Suggestion.zero(a);
      }
    }

    if (f.hasTools == false && a.needsTools) {
      return Suggestion.zero(a);
    }
    if (f.hasTools == true) {
      score += 4;
      reasons.add(a.needsTools ? 'بأدوات متوفرة لديك' : 'لا يحتاج أدوات');
    }

    if (f.type != SuggestType.any) {
      if (a.matchesType(f.type)) {
        score += 50;
        reasons.add('يناسب النوع المطلوب (${f.type.label})');
      } else {
        return Suggestion.zero(a);
      }
    }

    if (f.age.min > 0) {
      if (a.age.isUnspecified) {
        score += 8;
        reasons.add('يناسب كل الأعمار');
      } else {
        final overlap = a.age.overlapWith(f.age);
        if (overlap == 0) return Suggestion.zero(a);
        score += overlap.clamp(0, 20);
        reasons.add('مناسب لأعمار طلابك');
      }
    }

    if (f.participants.min > 0) {
      if (a.participants.isUnspecified) {
        score += 15;
        reasons.add('عدد المشاركين مرن');
      } else {
        if (!_fitsParticipants(a.participants, f.participants)) {
          return Suggestion.zero(a);
        }
        score += 25;
        reasons.add('يتسع لعدد طلابك (${a.participants.label})');
      }
    }

    if (f.duration.min > 0) {
      final userMin = f.duration.min;
      final userMax = f.duration.max > 0 ? f.duration.max : userMin;

      if (a.duration.isUnspecified) {
        score += 15;
        reasons.add('مدة مرنة');
      } else {
        final aMin = a.duration.min;
        final aMax = a.duration.max;

        if (userMax < aMin) {
          // الوقت المتاح أقل من الحد الأدنى: نقبل نسخة أقصر إن كان قريبًا.
          if (userMax >= (aMin * 0.5) + 1) {
            score += 8;
            reasons.add('يمكن تنفيذه في وقت أقصر');
          } else {
            return Suggestion.zero(a);
          }
        } else if (userMax >= aMax) {
          score += 25;
          reasons.add('مدة مناسبة (${a.duration.label} دقيقة)');
        } else {
          score += 15;
          reasons.add('مدة مناسبة (${a.duration.label} دقيقة)');
        }
      }
    }

    if (f.movement != MovementLevel.any && f.movement == a.movement) {
      score += 8;
      reasons.add('نشاط ${a.movement.label}');
    }

    if (score <= 0) return Suggestion.zero(a);
    return Suggestion(activity: a, score: score, reasons: reasons);
  }

  bool _fitsParticipants(RangeValue activity, RangeValue need) {
    final min = need.min;
    final max = need.max > 0 ? need.max : min;
    if (activity.max < min) return false;
    if (activity.min > max) return false;
    return true;
  }

  // -------------------- المفضلة --------------------

  @override
  Set<String> getFavoriteIds() => Set.unmodifiable(_favorites);

  @override
  bool isFavorite(String id) => _favorites.contains(id);

  @override
  Future<void> toggleFavorite(String id) async {
    if (!_favorites.remove(id)) {
      _favorites.add(id);
    }
    await datasource.prefs.saveFavoriteIds(_favorites);
  }

  // -------------------- الاستيراد --------------------

  @override
  Future<ImportResult> importJsonFile(String filePath) async {
    try {
      final raw = await datasource.readJsonFile(filePath);
      final result = await _processRaw(raw);

      // نسخ الملف إلى مجلد الاستيراد ليبقى محمّلًا بعد إعادة التشغيل.
      if (result.added + result.updated > 0) {
        await datasource.copyFileToImports(filePath);
      }
      return result;
    } catch (e) {
      return const ImportResult(
        errors: 1,
        messages: ['تعذر قراءة الملف. تأكد أنه ملف JSON صالح.'],
      );
    }
  }

  @override
  Future<ImportResult> importBytes(String fileName, List<int> bytes) async {
    try {
      final raw = datasource.fromBytes(fileName, Uint8List.fromList(bytes));
      final result = await _processRaw(raw);

      // حفظ نسخة في مجلد الاستيراد لتبقى محمّلة بعد إعادة التشغيل
      // (على الويب في التخزين الدائم للمتصفح).
      if (result.added + result.updated > 0) {
        try {
          await datasource.writeBytesToImports(
            fileName,
            Uint8List.fromList(bytes),
          );
        } catch (_) {
          // إن تعذر الحفظ نكتفي بالاستيراد في الذاكرة دون إيقاف العملية.
        }
      }
      return result;
    } catch (e) {
      return const ImportResult(
        errors: 1,
        messages: ['تعذر قراءة الملف. تأكد أنه ملف JSON صالح.'],
      );
    }
  }

  @override
  Future<ImportResult> importWordBytes(String fileName, List<int> bytes) async {
    try {
      final activities =
          datasource.wordBytesToActivities(fileName, Uint8List.fromList(bytes));

      if (activities.isEmpty) {
        return const ImportResult(
          errors: 1,
          messages: ['تعذر استخراج أنشطة من ملف وورد. تأكد من صحة الملف.'],
        );
      }

      var added = 0, updated = 0, skipped = 0;
      for (final map in activities) {
        final status = _indexer.addOrUpdate(map, 'word/$fileName');
        if (status.added) {
          added++;
        } else if (status.updated) {
          updated++;
        } else {
          skipped++;
        }
      }

      return ImportResult(
        added: added,
        updated: updated,
        skipped: skipped,
        messages: [
          'تم تحويل ${activities.length} لعبة من ملف وورد وتصنيفها تلقائيًا.',
        ],
      );
    } catch (_) {
      return const ImportResult(
        errors: 1,
        messages: ['تعذر قراءة ملف وورد.'],
      );
    }
  }

  @override
  Future<ImportResult> importFromDocuments() async {
    final paths = await datasource.jsonFilePathsInImports();

    if (paths.isEmpty) {
      return const ImportResult(messages: ['لا توجد ملفات في مجلد الاستيراد.']);
    }

    var added = 0, updated = 0, skipped = 0, errors = 0;
    final messages = <String>[];

    for (final path in paths) {
      try {
        final raw = await datasource.readJsonFile(path);
        final r = await _processRaw(raw);
        added += r.added;
        updated += r.updated;
        skipped += r.skipped;
        messages.add('${raw.fileName}: أُضيف ${r.added}، حُدّث ${r.updated}، مكرر ${r.skipped}');
      } catch (_) {
        errors++;
        messages.add('$path: ملف غير صالح.');
      }
    }

    return ImportResult(
      added: added,
      updated: updated,
      skipped: skipped,
      errors: errors,
      messages: messages,
    );
  }

  Future<ImportResult> _processRaw(RawActivityFile raw) async {
    var added = 0, updated = 0, skipped = 0;
    final parsed = _indexer.extract(raw);

    if (parsed.isEmpty) {
      return const ImportResult(messages: ['الملف لا يحتوي على أنشطة قابلة للقراءة.']);
    }

    for (final map in parsed) {
      final status = _indexer.addOrUpdate(map, raw.fileName);
      if (status.added) {
        added++;
      } else if (status.updated) {
        updated++;
      } else {
        skipped++;
      }
    }

    return ImportResult(
      added: added,
      updated: updated,
      skipped: skipped,
      messages: [
        'تمت معالجة ${parsed.length} نشاطًا من ${raw.fileName}.',
      ],
    );
  }

  // -------------------- المعاينة قبل الاستيراد --------------------

  @override
  Future<ImportPreview> previewJsonBytes(String fileName, List<int> bytes) async {
    try {
      final raw = datasource.fromBytes(fileName, Uint8List.fromList(bytes));
      return _previewRaw(raw, ImportKind.json);
    } catch (_) {
      return const ImportPreview(
        error: 'تعذر قراءة الملف. تأكد أنه ملف JSON صالح.',
      );
    }
  }

  @override
  Future<ImportPreview> previewWordBytes(String fileName, List<int> bytes) async {
    try {
      final activities =
          datasource.wordBytesToActivities(fileName, Uint8List.fromList(bytes));

      if (activities.isEmpty) {
        return const ImportPreview(
          error: 'تعذر استخراج أنشطة من ملف وورد. تأكد من صحة الملف.',
        );
      }

      var added = 0, updated = 0, skipped = 0;
      for (final map in activities) {
        final status = _indexer.previewStatus(map, 'word/$fileName');
        if (status.added) {
          added++;
        } else if (status.updated) {
          updated++;
        } else {
          skipped++;
        }
      }

      return ImportPreview(
        kind: ImportKind.word,
        activityCount: activities.length,
        newCount: added,
        updateCount: updated,
        duplicateCount: skipped,
      );
    } catch (_) {
      return const ImportPreview(
        error: 'تعذر قراءة ملف وورد.',
      );
    }
  }

  @override
  Future<ImportPreview> previewFromDocuments() async {
    try {
      final paths = await datasource.jsonFilePathsInImports();
      if (paths.isEmpty) {
        return const ImportPreview(
          error: 'لا توجد ملفات في مجلد الاستيراد.',
        );
      }

      var fileCount = 0;
      var activityCount = 0, added = 0, updated = 0, skipped = 0;
      for (final path in paths) {
        try {
          final raw = await datasource.readJsonFile(path);
          final preview = _previewRaw(raw, ImportKind.folder);
          if (preview.hasError) continue;
          fileCount++;
          activityCount += preview.activityCount;
          added += preview.newCount;
          updated += preview.updateCount;
          skipped += preview.duplicateCount;
        } catch (_) {
          // تجاهل الملفات غير الصالحة في المعاينة.
        }
      }

      if (fileCount == 0) {
        return const ImportPreview(
          error: 'لا توجد ملفات صالحة في مجلد الاستيراد.',
        );
      }

      return ImportPreview(
        kind: ImportKind.folder,
        activityCount: activityCount,
        newCount: added,
        updateCount: updated,
        duplicateCount: skipped,
      );
    } catch (_) {
      return const ImportPreview(
        error: 'تعذر فحص مجلد الاستيراد.',
      );
    }
  }

  /// تحليل ملف خام وحساب أرقام المعاينة دون أي أثر على الفهرس.
  ImportPreview _previewRaw(RawActivityFile raw, ImportKind kind) {
    final parsed = _indexer.extract(raw);
    if (parsed.isEmpty) {
      return const ImportPreview(
        error: 'الملف لا يحتوي على أنشطة قابلة للقراءة.',
      );
    }

    var added = 0, updated = 0, skipped = 0;
    for (final map in parsed) {
      final status = _indexer.previewStatus(map, raw.fileName);
      if (status.added) {
        added++;
      } else if (status.updated) {
        updated++;
      } else {
        skipped++;
      }
    }

    return ImportPreview(
      kind: kind,
      activityCount: parsed.length,
      newCount: added,
      updateCount: updated,
      duplicateCount: skipped,
    );
  }
  @override
  Future<String> exportTemplateToDocuments() =>
      datasource.exportTemplate();

  @override
  Future<Map<String, String>> loadActivitySourceFiles() =>
      datasource.loadActivitySourceFiles();

  @override
  Future<String> readTemplateContent() => datasource.readTemplateAsset();

  @override
  Future<String> getImportFolderPath() =>
      datasource.importFolderPath();
}
