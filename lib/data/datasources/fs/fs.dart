/// واجهة موحّدة لعمليات الملفات مع تنفيذ حسب المنصة.
///
/// على المنصات الأصلية (Android/iOS/desktop) تُستخدم [fs_io] عبر dart:io.
/// على الويب لا يوجد نظام ملفات محلي، لذا تُقدَّم [fs_web] برسائل مناسبة.
library;
export 'fs_web.dart' if (dart.library.io) 'fs_io.dart';
