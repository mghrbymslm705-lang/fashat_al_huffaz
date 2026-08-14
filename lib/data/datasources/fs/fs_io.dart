import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// تنفيذ عمليات الملفات على المنصات الأصلية (نظام ملفات حقيقي).
Future<String> appDocsPath() async {
  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
}

Future<String> importsDirPath() async =>
    '${await appDocsPath()}${Platform.pathSeparator}imports';

Future<void> ensureImportsDir() async {
  final dir = Directory(await importsDirPath());
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}

/// قائمة مسارات ملفات JSON داخل مجلد الاستيراد.
Future<List<String>> jsonFilePathsInImports() async {
  await ensureImportsDir();
  return Directory(await importsDirPath())
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.json'))
      .map((f) => f.path)
      .toList();
}

Future<String> readText(String path) => File(path).readAsString();

Future<Uint8List> readBytes(String path) => File(path).readAsBytes();

Future<void> writeText(String path, String content) =>
    File(path).writeAsString(content);

/// نسخ ملف خارجي إلى مجلد الاستيراد (يبقى محمّلًا بعد إعادة التشغيل).
Future<String> copyToImports(String sourcePath) async {
  await ensureImportsDir();
  final target =
      '${await importsDirPath()}${Platform.pathSeparator}${fileNameOf(sourcePath)}';
  await File(sourcePath).copy(target);
  return target;
}

/// كتابة محتوى مستورد إلى مجلد الاستيراد.
Future<String> writeBytesToImports(String name, Uint8List bytes) async {
  await ensureImportsDir();
  final target =
      '${await importsDirPath()}${Platform.pathSeparator}$name';
  await File(target).writeAsBytes(bytes);
  return target;
}

String fileNameOf(String path) => path.split(RegExp(r'[\\/]')).last;
