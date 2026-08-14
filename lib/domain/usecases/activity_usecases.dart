import '../entities/activity.dart';
import '../entities/activity_filter.dart';
import '../entities/category.dart';
import '../entities/suggestion.dart';
import '../repositories/activity_repository.dart';

/// حِزمة حالات الاستخدام (Use Cases) التي تنظم تدفق العمليات
/// من طبقة العرض إلى المستودع وفق Clean Architecture.

/// تحميل كل المحتوى مرة واحدة عند تشغيل التطبيق.
class LoadContent {
  final ActivityRepository repository;
  const LoadContent(this.repository);

  Future<void> call() => repository.loadContent();
}

/// جلب كل الأقسام.
class GetCategories {
  final ActivityRepository repository;
  const GetCategories(this.repository);

  List<Category> call() => repository.getCategories();
}

/// جلب أنشطة قسم معيّن.
class GetActivitiesByCategory {
  final ActivityRepository repository;
  const GetActivitiesByCategory(this.repository);

  List<Activity> call(String categoryId) =>
      repository.getActivitiesByCategory(categoryId);
}

/// بحث لحظي.
class SearchActivities {
  final ActivityRepository repository;
  const SearchActivities(this.repository);

  List<Activity> call(String query) => repository.search(query);
}

/// تطبيق الفلاتر الذكية.
class FilterActivities {
  final ActivityRepository repository;
  const FilterActivities(this.repository);

  List<Activity> call(ActivityFilter filter) =>
      repository.applyFilter(filter);
}

/// اقتراح الأنشطة الأنسب (المساعد الذكي - يعمل داخل قاعدة البيانات فقط).
class SuggestActivities {
  final ActivityRepository repository;
  const SuggestActivities(this.repository);

  List<Suggestion> call(ActivityFilter filter) => repository.suggest(filter);
}

/// إضافة/إزالة من المفضلة.
class ToggleFavorite {
  final ActivityRepository repository;
  const ToggleFavorite(this.repository);

  Future<void> call(String id) => repository.toggleFavorite(id);
}

/// استيراد ملفات محتوى جديدة.
class ImportContent {
  final ActivityRepository repository;
  const ImportContent(this.repository);

  Future<ImportResult> call(String filePath) =>
      repository.importJsonFile(filePath);

  Future<ImportResult> fromDocuments() => repository.importFromDocuments();

  Future<String> exportTemplate() => repository.exportTemplateToDocuments();
}
