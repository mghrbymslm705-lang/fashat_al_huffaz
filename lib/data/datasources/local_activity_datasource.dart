import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../../core/constants/asset_paths.dart';
import '../../core/utils/word_text_extractor.dart';
import '../../domain/entities/category.dart';
import '../importers/word_activity_parser.dart';
import '../models/category_model.dart';
import 'fs/fs.dart' as fs;
import 'prefs_datasource.dart';

/// ملف محتوى خام (اسم الملف + بيانات JSON المُفكَّكة).
class RawActivityFile {
  const RawActivityFile({required this.fileName, required this.data});

  /// اسم الملف (يُعرض كمرجع للمحتوى).
  final String fileName;

  /// البيانات المُفكَّكة (قائمة أنشطة أو كائن واحد أو كائن ذو قائمة).
  final Object? data;
}

/// مصدر البيانات المحلي: قراءة ملفات JSON من الأصول المضمّنة
/// ومن مجلد الاستيراد (للملفات المستوردة).
///
/// هذا هو المصدر الوحيد للمحتوى: لا يتصل التطبيق بأي خدمة خارجية.
/// عمليات الملفات تمر عبر طبقة [fs] لدعم الويب حيث لا يوجد نظام ملفات.
class LocalActivityDatasource {
  const LocalActivityDatasource(this.prefs);

  final PrefsDatasource prefs;

  // -------------------- الأقسام --------------------

  Future<List<Category>> loadCategories() async {
    final raw = await rootBundle.loadString(AssetPaths.categoriesFile);
    return CategoryModel.fromJsonString(raw);
  }

  // -------------------- ملفات الأنشطة --------------------

  /// قراءة كل ملفات JSON داخل مجلد الأنشطة المضمّن.
  ///
  /// تُستخدم قائمة الأصول (AssetManifest) بدلًا من قائمة ثابتة،
  /// لذلك أي ملف يُضاف إلى المجلد يظهر تلقائيًا دون تعديل الكود.
  Future<List<RawActivityFile>> loadActivityFilesFromAssets() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    final paths = manifest
        .listAssets()
        .where((p) => p.startsWith(AssetPaths.activitiesFolder))
        .where((p) => p.endsWith('.json'))
        .where((p) => p != AssetPaths.templateFile)
        .toList();

    // تحميل الملفات بالتوازي بدلًا من التسلسل لتسريع الإقلاع.
    final loaded = await Future.wait(paths.map((path) async {
      try {
        final content = await rootBundle.loadString(path);
        return RawActivityFile(
          fileName: _fileNameOf(path),
          data: json.decode(content),
        );
      } catch (_) {
        // تجاهل الملفات التالفة دون إيقاف التطبيق.
        return null;
      }
    }));

    return loaded.whereType<RawActivityFile>().toList();
  }

  /// قراءة كل ملفات JSON في مجلد الاستيراد (الملفات المستوردة يدويًا).
  ///
  /// على الويب يقرأ من التخزين الدائم للمتصفح (SharedPreferences).
  Future<List<RawActivityFile>> loadActivityFilesFromDocuments() async {
    final result = <RawActivityFile>[];
    try {
      for (final path in await fs.jsonFilePathsInImports()) {
        try {
          final content = await fs.readText(path);
          result.add(RawActivityFile(
            fileName: fs.fileNameOf(path),
            data: json.decode(content),
          ));
        } catch (_) {
          // تجاهل الملفات التالفة.
        }
      }
    } catch (_) {
      // لا نظام ملفات (الويب) → قائمة فارغة.
    }
    return result;
  }

  /// مسار مجلد الاستيراد (المستندات/imports) أو يرمي خطأ على الويب.
  Future<String> importFolderPath() => fs.importsDirPath();

  // -------------------- قراءة وكتابة الملفات --------------------

  /// قراءة ملف JSON خارجي (من اختيار المستخدم على المنصات الأصلية).
  Future<RawActivityFile> readJsonFile(String filePath) async {
    final content = await fs.readText(filePath);
    return RawActivityFile(
      fileName: fs.fileNameOf(filePath),
      data: json.decode(content),
    );
  }

  /// بناء ملف خام من بايتات الملف المختار (يعمل على الويب أيضًا).
  RawActivityFile fromBytes(String fileName, Uint8List bytes) {
    return RawActivityFile(
      fileName: fileName,
      data: json.decode(utf8.decode(bytes)),
    );
  }

  /// تحويل ملف وورد إلى قائمة خرائط أنشطة.
  ///
  /// يستخرج النص حسب الصيغة (docx/doc/txt) ثم يحلّله ويصنّف كل لعبة
  /// تلقائيًا في قسمها المناسب. يعمل على الويب أيضًا.
  List<Map<String, dynamic>> wordBytesToActivities(
    String fileName,
    Uint8List bytes,
  ) {
    final lines = WordTextExtractor.extract(fileName, bytes);
    return WordActivityParser.parse(
      lines,
      sourceFile: fileName,
    );
  }

  /// نسخ ملف مستورد إلى مجلد الاستيراد ليُحمَّل تلقائيًا بعد إعادة التشغيل.
  Future<void> copyFileToImports(String sourcePath) async {
    await fs.copyToImports(sourcePath);
  }

  /// حفظ محتوى مستورد إلى مجلد الاستيراد.
  Future<void> writeBytesToImports(String name, Uint8List bytes) async {
    await fs.writeBytesToImports(name, bytes);
  }

  /// قائمة مسارات ملفات JSON داخل مجلد الاستيراد.
  Future<List<String>> jsonFilePathsInImports() =>
      fs.jsonFilePathsInImports();

  /// قراءة محتوى ملف القالب المضمّن.
  Future<String> readTemplateAsset() =>
      rootBundle.loadString(AssetPaths.templateFile);

  /// قراءة المحتوى الخام الأصلي لكل ملف أنشطة (اسم الملف ← المحتوى JSON).
  ///
  /// تُستخدم في صفحة الاستيراد لتنزيل النسخ الأصلية من الملفات.
  Future<Map<String, String>> loadActivitySourceFiles() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    final paths = manifest
        .listAssets()
        .where((p) => p.startsWith(AssetPaths.activitiesFolder))
        .where((p) => p.endsWith('.json'))
        .where((p) => p != AssetPaths.templateFile)
        .toList();

    final result = <String, String>{};
    for (final path in paths) {
      try {
        result[_fileNameOf(path)] = await rootBundle.loadString(path);
      } catch (_) {
        // تجاهل الملفات غير القابلة للقراءة.
      }
    }
    return result;
  }

  /// كتابة نسخة من القالب في مجلد المستندات (لا تتوفر على الويب).
  Future<String> exportTemplate() async {
    final content = await readTemplateAsset();
    final target = '${await fs.appDocsPath()}/fashat_template.json';
    await fs.writeText(target, content);
    return target;
  }

  static String _fileNameOf(String path) {
    final segments = path.split('/');
    return segments.isEmpty ? path : segments.last;
  }
}
