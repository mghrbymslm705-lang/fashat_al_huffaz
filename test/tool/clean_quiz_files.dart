import 'dart:convert';
import 'dart:io';

/// أداة تنظيف ملفات quiz_folder_*.json المولّدة آليًا من ملفات Word.
///
/// تحذف من الخطوات (steps) بقايا بنية ملف OLE/Word الثنائية وأسماء أنماط
/// Word والمقاطع المشوّهة، وتزيل التكرار، وتصلح العناوين الفارغة.
void main() {
  final dir = Directory('assets/data/activities');
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.split(RegExp(r'[\\/]')).last.startsWith('quiz_folder_') &&
          f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    stdout.writeln('لا توجد ملفات quiz_folder_*.json');
    return;
  }

  var totalBefore = 0;
  var totalAfter = 0;
  var droppedByOle = 0;
  var droppedByStyle = 0;
  var droppedByGarbled = 0;
  var droppedByShort = 0;
  var droppedByDup = 0;
  var fixedTitles = 0;

  for (final file in files) {
    final raw = file.readAsStringSync(encoding: utf8);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final activities = decoded['activities'] as List<dynamic>;

    for (final act in activities) {
      final map = act as Map<String, dynamic>;
      final steps = (map['steps'] as List<dynamic>).cast<String>();
      totalBefore += steps.length;

      final seen = <String>{};
      final cleaned = <String>[];
      for (final rawStep in steps) {
        final step = rawStep.trim();
        if (step.isEmpty) {
          droppedByShort++;
          continue;
        }
        if (_isOlePart(step)) {
          droppedByOle++;
          continue;
        }
        if (_isWordStyle(step)) {
          droppedByStyle++;
          continue;
        }
        if (!_hasArabicWord(step)) {
          droppedByGarbled++;
          continue;
        }
        if (step.length < 3) {
          droppedByShort++;
          continue;
        }
        if (!seen.add(step.toLowerCase())) {
          droppedByDup++;
          continue;
        }
        cleaned.add(step);
      }
      map['steps'] = cleaned;
      totalAfter += cleaned.length;

      final title = (map['title'] as String? ?? '').trim();
      if (title.isEmpty || title == 'مسابقة مختارة من') {
        final source = map['source'] as Map<String, dynamic>?;
        final sourceName = (source?['name'] as String? ?? '').trim();
        if (sourceName.isNotEmpty) {
          map['title'] = sourceName;
          fixedTitles++;
        } else if (cleaned.isNotEmpty) {
          map['title'] = cleaned.first;
          fixedTitles++;
        }
      }
    }

    final out = const JsonEncoder.withIndent('  ').convert(decoded);
    file.writeAsStringSync('$out\n', encoding: utf8);
    stdout.writeln('${file.path.split(RegExp(r'[\\/]')).last}: ${_countSteps(decoded)} خطوة');
  }

  stdout.writeln('=====================');
  stdout.writeln('الملفات المعالجة: ${files.length}');
  stdout.writeln('الخطوات قبل: $totalBefore');
  stdout.writeln('الخطوات بعد: $totalAfter');
  stdout.writeln('محذوفة (أجزاء OLE ثنائية): $droppedByOle');
  stdout.writeln('محذوفة (أسماء أنماط Word): $droppedByStyle');
  stdout.writeln('محذوفة (مشوّهة بلا كلمات عربية): $droppedByGarbled');
  stdout.writeln('محذوفة (قصيرة/فارغة): $droppedByShort');
  stdout.writeln('محذوفة (تكرار): $droppedByDup');
  stdout.writeln('عناوين تم إصلاحها: $fixedTitles');
}

int _countSteps(Map<String, dynamic> decoded) {
  final activities = decoded['activities'] as List<dynamic>;
  var n = 0;
  for (final act in activities) {
    final steps = (act as Map<String, dynamic>)['steps'] as List<dynamic>;
    n += steps.length;
  }
  return n;
}

bool _isOlePart(String s) {
  return s == 'Root Entry' ||
      s == 'Data' ||
      s == '1Table' ||
      s == 'WordDocument' ||
      s == 'SummaryInformation' ||
      s == 'DocumentSummaryInformation' ||
      s == 'CompObj';
}

final _stylePatterns = [
  RegExp(r'^عادي$'),
  RegExp(r'^عنوان \d+$'),
  RegExp(r'^عنوان جانبي \d+$'),
  RegExp(r'^عنوان$'),
  RegExp(r'^خط الفقرة الافتراضي$'),
  RegExp(r'^جدول عادي$'),
  RegExp(r'^بلا قائمة$'),
  RegExp(r'^نص حاشية سفلية$'),
  RegExp(r'^نمط الشعر$'),
  RegExp(r'^ترقيم نقطي$'),
  RegExp(r'^ترقيم بحروف بمستويين$'),
  RegExp(r'^ترقيم بثلاثة مستويات$'),
  RegExp(r'^تسمية توضيحية$'),
  RegExp(r'^ارتباط تشعبي متبع$'),
];

bool _isWordStyle(String s) => _stylePatterns.any((p) => p.hasMatch(s));

final _arabicWord = RegExp(r'[\u0621-\u063A\u0641-\u064A]{3,}');

bool _hasArabicWord(String s) => _arabicWord.hasMatch(s);
