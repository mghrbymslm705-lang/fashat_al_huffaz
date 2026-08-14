import 'dart:convert';
import 'dart:io';

import 'package:fashat_al_huffaz/core/utils/word_text_extractor.dart';
import 'package:fashat_al_huffaz/data/importers/quiz_activity_parser.dart';
import 'package:fashat_al_huffaz/data/importers/word_activity_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// أداة استيراد ملفات المسابقات والألعاب من مجلد
/// `ألعاب_للإدراج` إلى مجلد الأنشطة.
///
/// التشغيل (أداة اختيارية: لا تُنفَّذ ضمن `flutter test` العادي حتى لا
/// تُعيد توليد ملفات المحتوى المُلَقَّمة وتمسح أي تنظيف يدوي):
///   flutter test test/tool/import_games_folder.dart
///
/// القواعد:
/// - يُتخطى `.exe/.zip` (برامج أرشفة لا تُستورد كأنشطة).
/// - تُتخطى ملفات الألعاب الخمسة المستوردة سابقًا ونسخها المكررة "(1)".
/// - ملفات `.doc` تُستخرج بواسطة WordTextExtractor.
/// - ملفات `.htm/.html` تُفكك يدويًا (فك windows-1256 + نزع الوسوم + فك
///   كيانات العدد، مثل `&#1605;`).
/// - يُجرَّب أولًا محلّل المسابقات (س/ج)، فإن لم يجد محتوى
///   نُجرب محلّل الألعاب.
///
/// الناتج: ملفات JSON باسم quiz_<hash>.json داخل
///   assets/data/activities/
void main() {
  testWidgets('استيراد ملفات المسابقات من مجلد ألعاب_للإدراج', (tester) async {
    const inDir = r'C:\Users\mj\Documents\ألعاب_للإدراج';
    const outDir = 'assets/data/activities';

    // ملفات الألعاب المستوردة سابقًا (لا نكررها ولا نسخها "(1)").
    const alreadyImported = [
      'موسوعة الألعاب الحركية',
      'برامج والعاب للمدارس والمخيمات والمراكز وغيرها',
      '44 لعبة شيقة للأطفال',
      'المسابقة الثقافية الحركية',
      'أفكار لمسابقات المراكز الصيفية',
    ];

    final dir = Directory(inDir);
    if (!dir.existsSync()) {
      throw StateError('مجلد غير موجود: $inDir');
    }

    final out = Directory(outDir);
    if (!out.existsSync()) out.createSync(recursive: true);

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => _isTarget(f, alreadyImported))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    // ignore: avoid_print
    print('الملفات المستهدفة: ${files.length}');

    var totalActivities = 0;
    var skippedEmpty = 0;
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final bytes = file.readAsBytesSync();

      final lines = _extractLines(name, bytes);
      if (lines.isEmpty) {
        // ignore: avoid_print
        print('[فارغ] $name');
        skippedEmpty++;
        continue;
      }

      var activities = QuizActivityParser.parse(lines, sourceFile: name);
      if (activities.isEmpty) {
        activities = WordActivityParser.parse(lines, sourceFile: name);
      }
      if (activities.isEmpty) {
        activities = QuizActivityParser.parseFallback(lines, sourceFile: name);
      }
      if (activities.isEmpty) {
        // ignore: avoid_print
        print('[فارغ] $name');
        skippedEmpty++;
        continue;
      }

      final base = name
          .replaceAll(RegExp(r'\.(docx?|txt|htm|html)$'), '')
          .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '_');
      final shortName = _shortName(base);
      final jsonFile = File('$outDir\\quiz_$shortName.json');
      const encoder = JsonEncoder.withIndent('  ');
      jsonFile.writeAsStringSync(
        encoder.convert({'activities': activities}),
        encoding: utf8,
      );

      totalActivities += activities.length;

      // ignore: avoid_print
      print('[$name] → ${activities.length} نشاطًا → quiz_$shortName.json');
      for (final a in activities.take(3)) {
        // ignore: avoid_print
        print('   • ${a['title']} (${a['category']})');
      }
    }

    // ignore: avoid_print
    print('=====================');
    // ignore: avoid_print
    print('إجمالي الأنشطة المستوردة: $totalActivities');
    // ignore: avoid_print
    print('ملفات فارغة/مُتخطاة: $skippedEmpty');
  });
}

/// هل الملف مرشح للاستيراد؟
bool _isTarget(File file, List<String> alreadyImported) {
  final name = file.uri.pathSegments.last.toLowerCase();
  final ext = name.contains('.') ? name.split('.').last : '';
  if (ext == 'exe' || ext == 'zip') return false;

  final base = name
      .replaceAll(RegExp(r'\.(docx?|txt|htm|html)$'), '')
      .replaceAll(RegExp(r'\s*\(1\)\s*$'), '')
      .trim();

  // نتجاهل الألعاب المستوردة سابقًا (الأصل ونسخته "(1)").
  for (final imp in alreadyImported) {
    if (base == imp.toLowerCase()) return false;
  }
  return true;
}

/// استخراج الأسطر حسب نوع الملف (doc أو htm).
List<String> _extractLines(String name, List<int> bytes) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.htm') || lower.endsWith('.html')) {
    return _extractHtmlLines(bytes);
  }
  return WordTextExtractor.extract(name, bytes);
}

/// فك HTML: يجرّب UTF-8 ثم windows-1256، يزيل الوسوم،
/// ويفك كيانات العدد والرموز الشائعة.
List<String> _extractHtmlLines(List<int> bytes) {
  String text;
  try {
    text = utf8.decode(bytes);
  } catch (_) {
    text = _decodeWindows1256(bytes);
  }

  // نتجاهل رأس HTML والوسوم والستايلات والنصوص الإنجليزية الداخلية.
  text = text.replaceFirst(RegExp(r'<!DOCTYPE.*?>', dotAll: true), '');
  text = text.replaceAll(RegExp(r'<style.*?</style>', dotAll: true), ' ');
  text = text.replaceAll(RegExp(r'<script.*?</script>', dotAll: true), ' ');
  text = text.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), ' ');

  // تحويل فواصل الفقرات إلى أسطر جديدة.
  text = text.replaceAll(RegExp(r'</p>|</div>|<br\s*/?>', caseSensitive: false),
      '\n');
  text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');

  // فك كيانات العدد والأسماء الشائعة.
  text = _decodeEntities(text);
  text = text.replaceAll(RegExp(r'&nbsp;|&lt;|&gt;|&amp;', caseSensitive: false),
      ' ');

  return text
      .split(RegExp(r'\r\n|\r|\n'))
      .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((l) => l.isNotEmpty && l.length >= 2)
      .toList();
}

/// فك ترميز windows-1256 (المستخدم في ملفات وورد htm القديمة) إلى Unicode.
String _decodeWindows1256(List<int> bytes) {
  final buffer = StringBuffer();
  for (final b in bytes) {
    if (b >= 0x80) {
      buffer.writeCharCode(_cp1256[b - 0x80]);
    } else {
      buffer.writeCharCode(b);
    }
  }
  return buffer.toString();
}

/// جدول تحويل windows-1256 للبايتات 0x80..0xFF.
const _cp1256 = <int>[
  0x20AC, 0x067E, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, // 80-87
  0x02C6, 0x2030, 0x0679, 0x2039, 0x0152, 0x0686, 0x0698, 0x0688, // 88-8F
  0x06AF, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, // 90-97
  0x06A9, 0x2122, 0x0691, 0x203A, 0x0153, 0x200C, 0x200D, 0x06BA, // 98-9F
  0x00A0, 0x060C, 0x00A2, 0x00A3, 0x00A4, 0x00A5, 0x00A6, 0x00A7, // A0-A7
  0x00A8, 0x00A9, 0x06BE, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x00AF, // A8-AF
  0x00B0, 0x00B1, 0x00B2, 0x00B3, 0x00B4, 0x00B5, 0x00B6, 0x00B7, // B0-B7
  0x00B8, 0x00B9, 0x061B, 0x00BB, 0x00BC, 0x00BD, 0x00BE, 0x061F, // B8-BF
  0x06C1, 0x0621, 0x0622, 0x0623, 0x0624, 0x0625, 0x0626, 0x0627, // C0-C7
  0x0628, 0x0629, 0x062A, 0x062B, 0x062C, 0x062D, 0x062E, 0x062F, // C8-CF
  0x0630, 0x0631, 0x0632, 0x0633, 0x0634, 0x0635, 0x0636, 0x00D7, // D0-D7
  0x0637, 0x0638, 0x0639, 0x063A, 0x0640, 0x0641, 0x0642, 0x0643, // D8-DF
  0x0644, 0x0645, 0x0646, 0x0647, 0x0648, 0x0649, 0x064A, 0x064B, // E0-E7
  0x064C, 0x064D, 0x064E, 0x064F, 0x0650, 0x0651, 0x0652, 0x0653, // E8-EF
  0x0654, 0x0655, 0x0656, 0x0657, 0x0658, 0x0659, 0x00F6, 0x065A, // F0-F7
  0x065B, 0x065C, 0x065D, 0x065E, 0x00FC, 0x200E, 0x200F, 0x06D2, // F8-FF
];

/// فك كيانات HTML العددية مثل `&#1605;` و `&#x627;`.
String _decodeEntities(String input) {
  final buffer = StringBuffer();
  final regex = RegExp(r'&#(x?[0-9a-fA-F]+);');
  var last = 0;
  for (final m in regex.allMatches(input)) {
    buffer.write(input.substring(last, m.start));
    final code = m.group(1)!.startsWith('x') || m.group(1)!.startsWith('X')
        ? int.parse(m.group(1)!.substring(1), radix: 16)
        : int.parse(m.group(1)!);
    buffer.write(String.fromCharCode(code));
    last = m.end;
  }
  buffer.write(input.substring(last));
  return buffer.toString();
}

/// اسم ملف قصير لتفادي أسماء طويلة غير صالحة على ويندوز.
String _shortName(String base) {
  var hash = 5381;
  for (final unit in base.codeUnits) {
    hash = ((hash << 5) + hash) + unit;
    hash = hash & 0x7FFFFFFF;
  }
  return 'folder_${hash.toRadixString(16)}';
}
