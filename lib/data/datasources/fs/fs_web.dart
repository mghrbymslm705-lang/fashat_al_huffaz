import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// تنفيذ عمليات الملفات على الويب.
///
/// لا يملك المتصفح نظام ملفات محليًا، لذلك تُخزَّن الملفات المستوردة داخل
/// التخزين الدائم للمتصفح (SharedPreferences → localStorage) بصيغة base64.
/// بذلك تبقى الأنشطة المستوردة محفوظة وتُحمَّل تلقائيًا بعد كل تشغيل.
const String _storeKey = 'imported_files_v1';

/// المسار الافتراضي لمجلد الاستيراد (مسار رمزي داخل التخزين الدائم).
const String _importsPath = '/imports';

/// المسار الافتراضي لمجلد المستندات (مسار رمزي داخل التخزين الدائم).
const String _docsPath = '/documents';

/// قراءة خريطة الملفات المخزّنة (المسار ← محتوى base64).
Future<Map<String, String>> _loadStore() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_storeKey);
  if (raw == null || raw.isEmpty) return {};
  try {
    final decoded = json.decode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    }
  } catch (_) {
    // تجاهل أي تلف في التخزين والعودة لقائمة فارغة.
  }
  return {};
}

Future<void> _saveStore(Map<String, String> store) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_storeKey, json.encode(store));
}

/// حفظ بايتات تحت مفتاح (مسار) معيّن.
Future<void> _putBytes(String key, Uint8List bytes) async {
  final store = await _loadStore();
  store[key] = base64.encode(bytes);
  await _saveStore(store);
}

/// قراءة بايتات مفتاح مخزّن أو رمي خطأ إن لم يوجد.
Future<Uint8List> _getBytes(String key) async {
  final store = await _loadStore();
  final encoded = store[key];
  if (encoded == null) {
    throw StateError('الملف غير موجود: $key');
  }
  return base64.decode(encoded);
}

/// المسار الرمزي لمجلد المستندات داخل التخزين الدائم.
Future<String> appDocsPath() async => _docsPath;

/// المسار الرمزي لمجلد الاستيراد داخل التخزين الدائم.
Future<String> importsDirPath() async => _importsPath;

Future<void> ensureImportsDir() async {
  // لا حاجة لإنشاء مجلد؛ التخزين يُدار عبر SharedPreferences.
}

/// قائمة مسارات ملفات JSON المخزّنة داخل مجلد الاستيراد.
Future<List<String>> jsonFilePathsInImports() async {
  final store = await _loadStore();
  const prefix = '$_importsPath/';
  return store.keys
      .where((k) => k.startsWith(prefix) && k.toLowerCase().endsWith('.json'))
      .toList()
    ..sort();
}

/// قراءة محتوى نصي لملف مخزّن.
Future<String> readText(String path) async =>
    utf8.decode(await _getBytes(path));

/// قراءة بايتات ملف مخزّن.
Future<Uint8List> readBytes(String path) async => _getBytes(path);

/// كتابة محتوى نصي إلى التخزين الدائم.
Future<void> writeText(String path, String content) async {
  await _putBytes(path, Uint8List.fromList(utf8.encode(content)));
}

/// نسخ ملف مخزّن إلى مجلد الاستيراد (يُستخدم عند إعادة الاستيراد).
Future<String> copyToImports(String sourcePath) async {
  final bytes = await _getBytes(sourcePath);
  final target = '$_importsPath/${fileNameOf(sourcePath)}';
  await _putBytes(target, bytes);
  return target;
}

/// حفظ بايتات الملف المختار في مجلد الاستيراد لتبقى بعد إعادة التشغيل.
Future<String> writeBytesToImports(String name, Uint8List bytes) async {
  final target = '$_importsPath/$name';
  await _putBytes(target, bytes);
  return target;
}

String fileNameOf(String path) => path.split(RegExp(r'[\\/]')).last;
