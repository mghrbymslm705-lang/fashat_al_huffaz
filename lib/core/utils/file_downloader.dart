/// تنزيل ملف نصي إلى جهاز المستخدم.
///
/// - على الويب: يُطلق تنزيلًا عبر المتصفح (Blob + رابط).
/// - على المنصات الأصلية: يُحفظ الملف في مجلد مستندات التطبيق.
library;
export 'file_downloader_io.dart' if (dart.library.js_interop) 'file_downloader_web.dart';
