import '../entities/activity.dart';
import '../entities/activity_filter.dart';
import '../entities/category.dart';
import '../entities/suggestion.dart';

  /// نتيجة استيراد ملف محتوى جديد.
class ImportResult {
  const ImportResult({
    this.added = 0,
    this.updated = 0,
    this.skipped = 0,
    this.errors = 0,
    this.messages = const [],
  });

  final int added;
  final int updated;
  final int skipped;
  final int errors;

  /// رسائل توضيحية للمستخدم.
  final List<String> messages;

  int get totalTouched => added + updated + skipped + errors;
}

/// نوع مصدر الاستيراد (يُستخدم لتوضيح سلوك المعاينة).
enum ImportKind { json, word, folder }

/// معاينة محتوى مصدر قبل استيراده.
///
/// تحلل الملف وتُحسب أرقام حقيقية (جديد / تحديث / مكرر) دون تعديل
/// المكتبة أو إنشاء أقسام، ليعرضها المستخدم ثم يؤكد الاستيراد.
class ImportPreview {
  const ImportPreview({
    this.activityCount = 0,
    this.newCount = 0,
    this.updateCount = 0,
    this.duplicateCount = 0,
    this.kind = ImportKind.json,
    this.error,
  });

  /// عدد الأنشطة القابلة للقراءة في المصدر.
  final int activityCount;

  /// ستصبح أنشطة جديدة (لا توجد في المكتبة حاليًا).
  final int newCount;

  /// ستصبح تحديثًا لإصدار أحدث من نشاط موجود.
  final int updateCount;

  /// مكررة/أقدم من الموجودة وسيتم تجاهلها.
  final int duplicateCount;

  /// نوع المصدر المُعايَن.
  final ImportKind kind;

  /// رسالة خطأ عند فشل التحليل (غير فارغ = معاينة فاشلة).
  final String? error;

  bool get hasError => error != null;
}

/// واجهة مستودع الأنشطة (بوابة البيانات الوحيدة للتطبيق).
///
/// تفصل طبقة العرض عن تفاصيل مصادر البيانات (أصول مضمّنة + مجلدات محلية).
abstract class ActivityRepository {
  /// تحميل كل المحتوى (الأقسام + الأنشطة + المفضلة) مرة واحدة.
  Future<void> loadContent();

  /// هل اكتمل التحميل؟
  bool get isLoaded;

  /// كل الأقسام.
  List<Category> getCategories();

  /// قسم بمعرّفه أو null.
  Category? categoryById(String id);

  /// عدد أنشطة قسم معيّن (أسرع من جلب القائمة الكاملة).
  int countByCategory(String categoryId);

  /// كل الأنشطة.
  List<Activity> getAllActivities();

  /// أنشطة قسم معيّن.
  List<Activity> getActivitiesByCategory(String categoryId);

  /// بحث لحظي بالنص داخل كل الأنشطة.
  List<Activity> search(String query);

  /// تطبيق الفلاتر الذكية (منطق مطابقة صارم).
  List<Activity> applyFilter(ActivityFilter filter);

  /// اقتراح أفضل الأنشطة وفق معايير المساعد الذكي (مرتّبة حسب الملاءمة).
  List<Suggestion> suggest(ActivityFilter filter);

  /// المفضلة الحالية.
  Set<String> getFavoriteIds();

  /// هل النشاط في المفضلة؟
  bool isFavorite(String id);

  /// إضافة/إزالة من المفضلة (تُحفظ محليًا).
  Future<void> toggleFavorite(String id);

  /// استيراد ملف JSON (من اختيار المستخدم أو من مجلد الاستيراد).
  Future<ImportResult> importJsonFile(String filePath);

  /// استيراد محتوى ملف JSON من بايتاته (يعمل على الويب أيضًا).
  Future<ImportResult> importBytes(String fileName, List<int> bytes);

  /// استيراد ملف وورد (doc/docx/txt): يستخرج النصوص ويحلّلها ويصنّف
  /// الألعاب تلقائيًا ثم يضيفها في أقسامها المناسبة.
  Future<ImportResult> importWordBytes(String fileName, List<int> bytes);

  /// استيراد كل ملفات JSON الموجودة في مجلد الاستيراد المحلي.
  Future<ImportResult> importFromDocuments();

  /// معاينة ملف JSON من بايتاته دون استيراده (يعمل على الويب أيضًا).
  Future<ImportPreview> previewJsonBytes(String fileName, List<int> bytes);

  /// معاينة ملف وورد (doc/docx/txt) دون استيراده.
  Future<ImportPreview> previewWordBytes(String fileName, List<int> bytes);

  /// معاينة محتوى مجلد الاستيراد دون استيراده (متاح على الأجهزة فقط).
  Future<ImportPreview> previewFromDocuments();

  /// مسار مجلد الاستيراد (داخل مستندات التطبيق).
  Future<String> getImportFolderPath();

  /// تصدير نسخة من قالب النشاط إلى مجلد المستندات.
  Future<String> exportTemplateToDocuments();

  /// المحتوى الخام الأصلي لكل ملف أنشطة (اسم الملف ← محتواه JSON).
  Future<Map<String, String>> loadActivitySourceFiles();

  /// محتوى ملف قالب النشاط المضمّن.
  Future<String> readTemplateContent();
}
