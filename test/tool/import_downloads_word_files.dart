import 'dart:convert';
import 'dart:io';

import 'package:fashat_al_huffaz/core/utils/word_text_extractor.dart';
import 'package:fashat_al_huffaz/data/importers/word_activity_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// أداة استيراد ملفات الألعاب من مجلد التنزيلات إلى مجلد الأنشطة.
///
/// التشغيل (أداة اختيارية: لا تُنفَّذ ضمن `flutter test` العادي حتى لا
/// تُعيد توليد ملفات المحتوى وتمسح أي تنظيف يدوي):
///   flutter test test/tool/import_downloads_word_files.dart
///
/// الملفات المعالجة (ألعاب فقط، يُستثنى المكرر بـ "(1)"):
///   C:\Users\mj\Downloads\*.doc
///
/// الناتج: ملفات JSON باسم word_<ملف>.json داخل
///   assets/data/activities/
/// فيظهر محتواها تلقائيًا في التطبيق بعد إعادة البناء.
void main() {
  testWidgets('استيراد ملفات الألعاب من التنزيلات', (tester) async {
    const downloadsDir = r'C:\Users\mj\Downloads';
    const outDir = 'assets/data/activities';

    final dir = Directory(downloadsDir);
    if (!dir.existsSync()) {
      throw StateError('مجلد التنزيلات غير موجود: $downloadsDir');
    }

    // ملفات الألعاب المستهدفة (بدون النسخ المكررة "(1)").
    final targets = [
      'موسوعة الألعاب الحركية.doc',
      'برامج والعاب للمدارس والمخيمات والمراكز وغيرها.doc',
      '44 لعبة شيقة للأطفال.doc',
      'المسابقة الثقافية الحركية.doc',
      'أفكار لمسابقات المراكز الصيفية.doc',
    ];

    final out = Directory(outDir);
    if (!out.existsSync()) out.createSync(recursive: true);

    var totalGames = 0;
    for (final target in targets) {
      final path = '$downloadsDir\\$target';
      if (!File(path).existsSync()) {
        // ignore: avoid_print
        print('[تحذير] غير موجود: $path');
        continue;
      }

      final bytes = File(path).readAsBytesSync();
      final lines = WordTextExtractor.extract(target, bytes);
      final activities = WordActivityParser.parse(
        lines,
        sourceFile: target,
      );

      if (activities.isEmpty) {
        // ignore: avoid_print
        print('[فارغ] $target');
        continue;
      }

      final base = target
          .replaceAll(RegExp(r'\.docx?$'), '')
          .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '_');
      final shortName = _shortName(base);
      final jsonFile = File('$outDir\\word_$shortName.json');
      const encoder = JsonEncoder.withIndent('  ');
      jsonFile.writeAsStringSync(
        encoder.convert({'activities': activities}),
        encoding: utf8,
      );

      totalGames += activities.length;

      // ملخص قصير لكل ملف.
      // ignore: avoid_print
      print('[$target] → ${activities.length} لعبة → word_$shortName.json');
      final cats = <String>{};
      for (final a in activities) {
        cats.add(a['category'] as String? ?? '?');
      }
      // ignore: avoid_print
      print('   الأقسام: ${cats.join('، ')}');
      for (final a in activities.take(3)) {
        // ignore: avoid_print
        print('   • ${a['title']} (${a['category']})');
      }
    }

    // ignore: avoid_print
    print('=====================');
    // ignore: avoid_print
    print('إجمالي الألعاب المستوردة: $totalGames');
  });
}

/// اسم ملف قصير لتفادي أسماء طويلة غير صالحة على ويندوز.
String _shortName(String base) {
  var hash = 5381;
  for (final unit in base.codeUnits) {
    hash = ((hash << 5) + hash) + unit;
    hash = hash & 0x7FFFFFFF;
  }
  return 'games_${hash.toRadixString(16)}';
}
