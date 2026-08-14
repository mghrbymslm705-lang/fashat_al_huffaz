import 'dart:io';

import 'package:fashat_al_huffaz/core/utils/word_text_extractor.dart';

void main() {
  final dir = Directory(r'C:\Users\mj\Documents\ألعاب_للإدراج');
  final files = dir.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  var sMarker = 0, jawabMarker = 0, htm = 0, exe = 0;
  for (final f in files) {
    final name = f.path.split('\\').last;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    if (ext == 'exe' || ext == 'zip') {
      exe++;
      continue;
    }
    if (ext == 'htm' || ext == 'html') {
      htm++;
      continue;
    }
    final lines = WordTextExtractor.extract(name, f.readAsBytesSync());
    final joined = lines.take(4000).join(' ');
    final hasS = joined.contains('س)') || joined.contains('س.') || joined.contains('س :');
    final hasJawab = joined.contains('الجواب') || joined.contains('الإجابة');
    if (hasS) sMarker++;
    if (hasJawab) jawabMarker++;
  }
  print('doc files: ${files.length}');
  print('exe/zip skipped: $exe');
  print('htm/html: $htm');
  print('doc files with س) marker: $sMarker');
  print('doc files with الجواب marker: $jawabMarker');
}
