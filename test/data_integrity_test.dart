import 'package:fashat_al_huffaz/data/datasources/local_activity_datasource.dart';
import 'package:fashat_al_huffaz/data/datasources/prefs_datasource.dart';
import 'package:fashat_al_huffaz/data/repositories/activity_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ActivityRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PrefsDatasource();
    repository = ActivityRepositoryImpl(LocalActivityDatasource(prefs));
    await repository.loadContent();
  });

  test('تحميل المحتوى الحقيقي: 310 نشاطًا بأرقام صحيحة', () {
    expect(repository.isLoaded, isTrue);
    expect(repository.getAllActivities().length, 310);
    expect(repository.getCategories().length, greaterThan(0));
  });

  test('كل نشاط له عنوان غير فارغ وغير مشوّه', () {
    for (final a in repository.getAllActivities()) {
      expect(a.title.trim().isNotEmpty, isTrue,
          reason: 'نشاط بلا عنوان: ${a.id}');
      expect(a.title.contains('مسابقة مختارة من'), isFalse,
          reason: 'عنوان مقطوع: ${a.id}');
      expect(RegExp(r'[\uFB50-\uFDFF\uFE70-\uFEFF]').hasMatch(a.title), isFalse,
          reason: 'عنوان يحتوي محارف عربية مشوّهة: ${a.id}');
    }
  });

  test('لا نشاط بدون خطوات (steps)', () {
    for (final a in repository.getAllActivities()) {
      expect(a.steps, isNotEmpty, reason: 'نشاط بلا خطوات: ${a.id}');
    }
  });

  test('لا بقايا OLE/Word ثنائية في الخطوات', () {
    const ole = [
      'Root Entry', 'Data', '1Table', 'WordDocument',
      'SummaryInformation', 'DocumentSummaryInformation', 'CompObj',
    ];
    for (final a in repository.getAllActivities()) {
      for (final step in a.steps) {
        expect(ole.contains(step.trim()), isFalse,
            reason: 'خطوة من بقايا OLE في ${a.id}');
      }
    }
  });

  test('لا تكرار في معرّفات الأنشطة', () {
    final ids = repository.getAllActivities().map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('البحث يعمل على المحتوى الحقيقي ويُرجع نتائج', () {
    final all = repository.getAllActivities();
    final first = all.first.title.trim();
    final term = first.length > 3 ? first.substring(0, 3) : first;
    final results = repository.search(term);
    expect(results, isNotEmpty);
    expect(results.first.title, first);
  });
}
