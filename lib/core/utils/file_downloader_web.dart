import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// تنزيل ملف نصي عبر المتصفح.
///
/// يُنشئ Blob من المحتوى ثم ينقر رابط تحميل باسم الملف.
/// الإرجاع null يعني أن التنزيل أُسند إلى المتصفح.
Future<String?> downloadTextFile(String fileName, String content) async {
  final bytes = Uint8List.fromList(utf8.encode(content));
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return null;
}
