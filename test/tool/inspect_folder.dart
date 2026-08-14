import 'dart:convert';
import 'dart:io';

import 'package:fashat_al_huffaz/core/utils/word_text_extractor.dart';

void main() {
  for (final file in [
    r'C:\Users\mj\Documents\ألعاب_للإدراج\45- مسابقة رمضانية (بحثية).doc',
    r'C:\Users\mj\Documents\ألعاب_للإدراج\أنظمة ولوائح العمل بالمركز.htm',
    r'C:\Users\mj\Documents\ألعاب_للإدراج\مسابقة على اللغات والعملات.htm',
  ]) {
    final bytes = File(file).readAsBytesSync();
    final name = file.split('\\').last;
    if (name.endsWith('.htm')) {
      final html = utf8.decode(bytes, allowMalformed: true);
      final text = html
          .replaceAll(RegExp(r'<[^>]+>'), ' ')
          .replaceAll(RegExp(r'&nbsp;|&lt;|&gt;|&amp;', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      print('===== $name (HTML, ${text.length} حرف) =====');
      print(text.length > 1200 ? text.substring(0, 1200) : text);
      print('');
      continue;
    }
    final lines = WordTextExtractor.extract(name, bytes);
    print('===== $name (${lines.length} سطر) =====');
    for (var i = 0; i < lines.length && i < 30; i++) {
      final t = lines[i].trim();
      print('$i: ${t.length > 90 ? t.substring(0, 90) : t}');
    }
    print('');
  }
}
