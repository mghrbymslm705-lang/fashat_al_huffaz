import 'dart:convert';
import 'dart:io';

import 'package:fashat_al_huffaz/core/utils/word_text_extractor.dart';
import 'package:fashat_al_huffaz/data/importers/quiz_activity_parser.dart';

void main() {
  for (final file in [
    r'C:\Users\mj\Documents\ألعاب_للإدراج\45- مسابقة رمضانية (بحثية).doc',
    r'C:\Users\mj\Documents\ألعاب_للإدراج\مسابقة على اللغات والعملات.htm',
    r'C:\Users\mj\Documents\ألعاب_للإدراج\أهم المعارك والفتوحات الإسلامية.htm',
  ]) {
    final name = file.split('\\').last;
    final bytes = File(file).readAsBytesSync();
    List<String> lines;
    if (name.endsWith('.htm') || name.endsWith('.html')) {
      String text;
      try {
        text = utf8.decode(bytes);
      } catch (_) {
        text = latin1.decode(bytes);
      }
      text = text.replaceAll(RegExp(r'<style.*?</style>', dotAll: true), ' ');
      text = text.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), ' ');
      text = text.replaceAll(
          RegExp(r'</p>|</div>|<br\s*/?>', caseSensitive: false), '\n');
      text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
      text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)));
      lines = text
          .split(RegExp(r'\r\n|\r|\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
    } else {
      lines = WordTextExtractor.extract(name, bytes);
    }
    print('===== $name (${lines.length} سطر) =====');
    for (var i = 0; i < lines.length && i < 14; i++) {
      print('$i: ${lines[i]}');
    }
    if (name.startsWith('45')) {
      final clean = lines
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s.length >= 2)
          .where((s) => !s.startsWith('EMBED'))
          .where((s) => !RegExp(r'^www\.|^http|المفكرة|dawahmemo').hasMatch(s))
          .toList();
      print('>>> cleaned: ${clean.length}');
      clean.take(12).forEach((l) => print('  - $l'));
    }
    final acts = QuizActivityParser.parse(lines, sourceFile: name);
    print('>>> أنشطة: ${acts.length}');
    print('');
  }
}
