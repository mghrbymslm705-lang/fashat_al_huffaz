import '../../data/datasources/fs/fs.dart' as fs;

/// تنزيل ملف نصي على المنصات الأصلية: يُحفظ في مجلد مستندات التطبيق
/// ويُرجَع مساره ليُعرض للمستخدم.
Future<String?> downloadTextFile(String fileName, String content) async {
  final docs = await fs.appDocsPath();
  final target = '$docs/$fileName';
  await fs.writeText(target, content);
  return target;
}
