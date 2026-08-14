import 'dart:convert';
import 'dart:typed_data';

import 'package:fashat_al_huffaz/data/datasources/fs/fs_web.dart' as fs_web;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('تخزين الويب (fs_web) — حفظ الاستيراد بعد إعادة التشغيل', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('يحفظ ملفًا مستوردًا ويقرؤه ويعيد سرده (يبقى في التخزين)', () async {
      const content = '{"activities":[{"id":"game_1","title":"لعبة الذاكرة"}]}';
      final bytes = Uint8List.fromList(utf8.encode(content));

      // استيراد ملف أثناء "الجلسة الأولى".
      final savedPath = await fs_web.writeBytesToImports('memory.json', bytes);
      expect(savedPath, '/imports/memory.json');

      // أي قراءة لاحقة عبر getInstance() جديدة تقرأ من نفس التخزين الدائم
      // (على الويب localStorage يبقى بعد إعادة تحميل الصفحة).
      final paths = await fs_web.jsonFilePathsInImports();
      expect(paths, contains('/imports/memory.json'));

      final read = await fs_web.readText('/imports/memory.json');
      expect(read, content);

      final name = fs_web.fileNameOf('/imports/memory.json');
      expect(name, 'memory.json');
    });

    test('لا يسرد إلا ملفات JSON داخل مجلد الاستيراد', () async {
      await fs_web.writeText('/documents/notes.txt', 'hello');
      await fs_web.writeBytesToImports('quiz.json', Uint8List.fromList(utf8.encode('{}')));

      final paths = await fs_web.jsonFilePathsInImports();
      expect(paths, ['/imports/quiz.json']);
      expect(await fs_web.importsDirPath(), '/imports');
      expect(await fs_web.appDocsPath(), '/documents');
    });

    test('يعيد خطأ واضحًا عند قراءة ملف غير محفوظ', () async {
      expect(
        () => fs_web.readText('/imports/unknown.json'),
        throwsStateError,
      );
    });
  });
}
