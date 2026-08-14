/// محلّل مسابقات الأسئلة والأجوبة (س/ج) إلى أنشطة.
///
/// يكتشف الصيغ الشائعة في ملفات مسابقات وورد:
/// - أزواج `س1/ سؤال` / `ج1/ جواب` (بأي فاصل: `) : - . /`).
/// - جداول تتناوب فيها سطور السؤال والجواب (مثل "مسابقة الحروف").
/// - صيغة احتياطية: مسابقة بلا س/ج (مثل "من هو الصحابي" وملفات htm)
///   تُحوَّل إلى نشاط واحد وصفه المقدمة وخطواته فقرات الأسئلة.
///
/// المخرَج: نشاط (أو أكثر) لكل ملف مسابقة.
/// هذا الملف خالٍ من استيرادات Flutter ليمكن استخدامه أيضًا في الأدوات.
class QuizActivityParser {
  QuizActivityParser._();

  static List<Map<String, dynamic>> parse(
    List<String> lines, {
    required String sourceFile,
  }) {    final cleaned = _cleanLines(lines);
    if (cleaned.length < 3) return const [];

    final pairs = _extractQAPairs(cleaned);

    // نعيد الصياغة النهائية: نشاط واحد للملف.
    if (pairs.length < 2) {
      // صيغة احتياطية: نطابق أزواجًا بطريقة جدول الحروف، أو كتل سN،
      // أو أسئلة بلا س/ج.
      var alt = _extractAlternatingPairs(cleaned);
      if (alt.length < 2) alt = _extractSnBlocks(cleaned);
      final content = alt.isNotEmpty ? alt : pairs;
      if (content.length < 2) {
        // لا أسئلة قابلة للاستخراج: نشاط وصفي واحد إن كان ملف مسابقة.
        return _descriptive(cleaned, sourceFile);
      }
      final steps = content
          .map((p) => 'السؤال: ${p.$1}\nالجواب: ${p.$2}')
          .toList();
      return [_build(cleaned, sourceFile, steps)];
    }

    final steps = pairs
        .map((p) => 'السؤال: ${p.$1}\nالجواب: ${p.$2}')
        .toList();
    return [_build(cleaned, sourceFile, steps)];
  }

  /// صيغة نهائية احتياطية للمحتوى الوصفي (جداول مثل "المعارك"
  /// واللوائح الإدارية): نشاط معرفي واحد بخطوات فقرات المحتوى.
  static List<Map<String, dynamic>> parseFallback(
    List<String> lines, {
    required String sourceFile,
  }) {
    final cleaned = _cleanLines(lines);
    if (cleaned.length < 4) return const [];
    final text = cleaned.join(' ');

    final title = _buildTitle(sourceFile, cleaned);
    // فقرة افتتاحية قصيرة كوصف.
    var description = _shorten(
        cleaned.where((l) => l.length >= 12).take(2).join(' '), 300);
    if (description.isEmpty) {
      description = 'محتوى معرفي من ملف: ${_sourceName(sourceFile)}';
    }

    final categoryInfo = _detectCategory('$title $text');
    final steps = cleaned
        .where((l) => l.length >= 8)
        .map((l) => _cleanBodyLine(l))
        .where((l) => l.isNotEmpty)
        .toList();

    return [
      _buildActivity(
        id: 'quiz_${_hashId(title, sourceFile)}',
        title: title,
        category: categoryInfo.$1,
        types: categoryInfo.$2,
        description: description,
        steps: steps,
        sourceFile: sourceFile,
        text: text,
      ),
    ];
  }

  // -------------------- تنظيف --------------------

  static List<String> _cleanLines(List<String> lines) {
    final out = <String>[];
    for (final raw in lines) {
      var s = raw.trim();
      if (s.isEmpty) continue;

      if (RegExp(r'^www\.|^http|HYPERLINK|المفكرة الدعوية|dawahmemo|alfjr')
          .hasMatch(s.toLowerCase())) {
        continue;
      }
      if (s.startsWith('بسم الله') && s.length < 40) continue;
      if (s.startsWith('EMBED ') || RegExp(r'^[\s\d-ـ_*]+$').hasMatch(s)) {
        continue;
      }
      if (RegExp(r'^(تأليف|إعداد|اعداد|رفعه)\s*[: :].{0,40}$').hasMatch(s)) {
        continue;
      }

      s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (s.isNotEmpty && s.length >= 2) out.add(s);
    }
    return out;
  }

  // -------------------- استخراج س/ج --------------------

  /// يستخرج أزواج (سؤال، جواب) من السطور.
  static List<(String, String)> _extractQAPairs(List<String> lines) {
    final pairs = <(String, String)>[];
    final questionStart = RegExp(r'^\s*س\s*\d*\s*[).:/،]\s*(.+)');
    final answerStart = RegExp(r'^\s*ج\s*\d*\s*[).:/،]\s*(.+)');

    String? currentQuestion;
    final questionLines = <String>[];
    String? currentAnswer;

    void flushQ() {
      if (currentQuestion != null) {
        pairs.add((currentQuestion, currentAnswer ?? ''));
      }
    }

    for (final line in lines) {
      final qMatch = questionStart.firstMatch(line);
      final aMatch = answerStart.firstMatch(line);
      final jawabMatch = RegExp(
              r'^\s*(?:الجواب|الإجابة)\s*[:.].{0,2}\s*(.+)')
          .firstMatch(line);

      if (qMatch != null) {
        flushQ();
        currentQuestion = qMatch.group(1)!.trim();
        questionLines.add(currentQuestion);
        currentAnswer = null;
      } else if (aMatch != null) {
        currentAnswer = aMatch.group(1)!.trim();
      } else if (jawabMatch != null && currentQuestion != null) {
        pairs.add((questionLines.join('\n'), jawabMatch.group(1)!.trim()));
        currentQuestion = null;
        questionLines.clear();
        currentAnswer = null;
      } else {
        if (currentQuestion != null && currentAnswer == null) {
          questionLines.add(line);
          currentQuestion = questionLines.join('\n');
        } else if (currentAnswer != null) {
          currentAnswer = '$currentAnswer ${line.trim()}';
        }
      }
    }
    flushQ();

    return pairs;
  }

  /// صيغة الجدول المتناوب (الرقم/الحرف/السؤال/الجواب):
  /// بعد رأس الجدول تتناوب سطور السؤال والجواب.
  static List<(String, String)> _extractAlternatingPairs(List<String> lines) {
    // نبحث عن رأس الجدول.
    final headerIdx = lines.indexWhere((l) =>
        l.contains('الرقم') &&
        (l.contains('الحرف') || l.contains('الـسؤ') || l.contains('الجواب')));
    final headerIdx2 = lines.indexWhere(
        (l) => l.contains('الـسؤ') || l.contains('الجو ا ب') || l.contains('الجواب'));
    final start = headerIdx >= 0 ? headerIdx + 1 : (headerIdx2 >= 0 ? headerIdx2 + 1 : -1);
    if (start < 0) return const [];

    final body = lines.skip(start + 1).where((l) {
      final t = l.replaceAll(RegExp(r'\s+'), '').replaceAll('ـ', '');
      if (t == 'الرقم' || t == 'الحرف' || t == 'السؤال' || t == 'الجواب' ||
          t == 'الجواب' || RegExp(r'^(الحرف|السؤال|الجواب|الرقم)$').hasMatch(t)) {
        return false;
      }
      return true;
    }).toList();

    // أزواج متتالية: سؤال ثم جواب.
    final pairs = <(String, String)>[];
    for (var i = 0; i + 1 < body.length; i += 2) {
      final q = body[i].replaceAll(RegExp(r'\s*\(\s*$'), '').trim();
      final a = body[i + 1].replaceAll(RegExp(r'\s*\(\s*$'), '').trim();
      if (q.length >= 3 && a.isNotEmpty) pairs.add((q, a));
    }
    return pairs;
  }

  /// صيغة كتل `سN`: سطر `س1` ثم السؤال ثم الجواب ثم `س2` ... وهكذا.
  static List<(String, String)> _extractSnBlocks(List<String> lines) {
    final marker = RegExp(r'^\s*س\s*(\d+)\s*$');
    final marks = <int>[];
    for (var i = 0; i < lines.length; i++) {
      if (marker.hasMatch(lines[i])) marks.add(i);
    }
    if (marks.length < 2) return const [];

    final pairs = <(String, String)>[];
    for (var k = 0; k < marks.length; k++) {
      final start = marks[k] + 1;
      final end = k + 1 < marks.length ? marks[k + 1] : lines.length;
      if (start >= end) continue;
      final block = lines.sublist(start, end).where((l) => l.isNotEmpty).toList();
      if (block.isEmpty) continue;

      // نص السؤال ينتهي عند سطر يحوي علامة استفهام (؟)، أو عند آخر سطر.
      var qEnd = -1;
      for (var i = 0; i < block.length; i++) {
        if (block[i].contains('؟') || block[i].contains('?')) {
          qEnd = i;
          break;
        }
      }
      if (qEnd < 0) qEnd = block.length - 1;
      final question = block.take(qEnd + 1).join(' ');
      final answer = block.skip(qEnd + 1).join(' ').trim();
      if (question.length >= 3) {
        pairs.add((question, answer.isEmpty ? 'انظر الإجابة' : answer));
      }
    }
    return pairs;
  }

  /// صيغة احتياطية وصفية: نشاط واحد من مقدمة الملف وفقراته.
  static List<Map<String, dynamic>> _descriptive(
      List<String> lines, String sourceFile) {
    // نتأكد أنها مسابقة فعلاً.
    final text = lines.join(' ');
    final hasQuizSignal = RegExp(r'مسابق|سؤال|من هو|ما هي|الأوائل|أذكار|الحروف|أسئلة')
        .hasMatch(text);
    if (!hasQuizSignal) {
      return const [];
    }

    // العنوان من اسم الملف أو أول سطر مناسب.
    final title = _buildTitle(sourceFile, lines);
    final intro = _buildIntro(lines, 300);

    final categoryInfo = _detectCategory('$title $text');

    // الخطوات: فقرات الملف (بدون المقدمة) مع ترقيم تلقائي.
    final introStart = _introEndIndex(lines);
    var body = lines.skip(introStart).toList();
    if (body.isEmpty) {
      // إن لم نجد حدًا واضحًا للمقدمة نستخدم كل السطور ذات الطول المعقول.
      body = lines.where((l) => l.length >= 8).toList();
    }
    final steps = body.map((l) => _cleanBodyLine(l)).where((l) => l.isNotEmpty).toList();
    if (steps.isEmpty) return const [];

    return [
      _buildActivity(
        id: 'quiz_${_hashId(title, sourceFile)}',
        title: title,
        category: categoryInfo.$1,
        types: categoryInfo.$2,
        description: intro,
        steps: steps,
        sourceFile: sourceFile,
        text: text,
      ),
    ];
  }

  static String _cleanBodyLine(String l) {
    var s = l.trim();
    s = s.replaceAll(RegExp(r'^\s*\(\s*$'), '').trim();
    return s;
  }

  static int _introEndIndex(List<String> lines) {
    // نهاية المقدمة عند أول سطر يبدو سؤالاً (يبدأ برقم، أو ينتهي بعلامة؟،
    // أو يحتوي "من هو/ما هي/اذكر").
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      if (RegExp(r'^\d+[\s).:-]|من هو|ما هي|من هي|اذكر|الرئيسية|المسابقة').hasMatch(l) &&
          i > 2) {
        return i;
      }
    }
    return lines.length;
  }

  // -------------------- البناء --------------------

  static Map<String, dynamic> _build(
      List<String> lines, String sourceFile, List<String> steps) {
    final title = _buildTitle(sourceFile, lines);
    final intro = _buildIntro(lines, 300);
    final categoryInfo = _detectCategory('$title ${lines.join(' ')}');
    return _buildActivity(
      id: 'quiz_${_hashId(title, sourceFile)}',
      title: title,
      category: categoryInfo.$1,
      types: categoryInfo.$2,
      description: intro,
      steps: steps,
      sourceFile: sourceFile,
      text: lines.join(' '),
    );
  }

  static Map<String, dynamic> _buildActivity({
    required String id,
    required String title,
    required String category,
    required List<String> types,
    required String description,
    required List<String> steps,
    required String sourceFile,
    required String text,
  }) {
    return {
      'id': id,
      'title': title,
      'category': category,
      'types': types,
      'description': _shorten(description.isEmpty
          ? 'مسابقة أسئلة وأجوبة من ملف: ${_sourceName(sourceFile)}'
          : description, 400),
      'participants': const {'min': 0, 'max': 0},
      'duration': const {'min': 0, 'max': 0},
      'movement': 'ساكنة',
      'location': 'داخل',
      'tools': const [],
      'steps': steps,
      'benefits': const [],
      'tips': const [],
      'tags': _tagsFromText('$title $text'),
      'source': {
        'file': 'word/$sourceFile',
        'name': _sourceName(sourceFile),
        'page': '',
      },
      'favorite': false,
      'version': 1,
      'isDemo': false,
    };
  }

  // -------------------- العنوان والنبذة --------------------

  static String _buildTitle(String sourceFile, List<String> lines) {
    for (final line in lines.take(14)) {
      final t = _cleanTitleLine(line);
      if (t.length >= 4 && t.length <= 70) return t;
    }
    return _sourceName(sourceFile);
  }

  static String _cleanTitleLine(String raw) {
    var s = raw.trim();
    if (RegExp(r'^(سلسلة|الحمد لله|أما بعد|بسم الله|مقدمة|http)').hasMatch(s)) {
      return '';
    }
    s = s.replaceFirst(RegExp(r'^\s*\d+\s*[-.)ـ]\s*'), '').trim();
    s = s.replaceAll(RegExp(r'[:\-—_*]+\s*$'), '').trim();
    return s;
  }

  static String _buildIntro(List<String> lines, int max) {
    final start = lines.indexWhere((l) =>
        RegExp(r'^\s*س\s*\d*\s*[).:/،]|^\s*الجواب|^\s*الإجابة|^س\s*\d*\s*/')
            .hasMatch(l));
    if (start <= 0) return '';
    final intro = lines.take(start).join(' ');
    return _shorten(intro, max);
  }

  // -------------------- التصنيف --------------------

  static (String, List<String>) _detectCategory(String text) {
    if (RegExp(r'فقه|صلاة|وضوء|غسل|زكاة|صيام|حج|فتوى|طهارة|أذكار|أوراد')
        .hasMatch(text)) {
      return ('islamic', ['ذكي']);
    }
    if (RegExp(r'قرآن|سورة|آية|تفسير|حفظ|جزء\s?\d+|تجويد|مقرئ|قراء|ترتيب السور')
        .hasMatch(text)) {
      return ('quranic', ['قرآني', 'ذكي']);
    }
    if (RegExp(r'حديث|سيرة|صحيح|رواة|إسناد|محدث|الأربعون|البخاري|مسلم|الهدية')
        .hasMatch(text)) {
      return ('islamic', ['ذكي']);
    }
    if (RegExp(r'توحيد|أسماء الله|عقيدة|شرك|عبادة|اعتقاد').hasMatch(text)) {
      return ('islamic', ['ذكي']);
    }
    if (RegExp(r'لغة|نحو|صرف|بلاغة|أدب|شعر|عربية|إملاء|لغات|عملات')
        .hasMatch(text)) {
      return ('culture', ['ذكي']);
    }
    if (RegExp(r'تاريخ|غزوة|معركة|خلافة|جاهلية|صليبية|أعلام|تراجم|حروب')
        .hasMatch(text)) {
      return ('culture', ['ذكي']);
    }
    if (RegExp(r'ثقاف|معلومة|أسئلة عامة|أوائل|بدايات|منوع|مجلة|أديان')
        .hasMatch(text)) {
      return ('culture', ['ذكي']);
    }
    if (RegExp(r'الحروف|أبجدية|سهمك|النملة|الطاقات').hasMatch(text)) {
      return ('intelligence', ['ذكي']);
    }
    return ('culture', ['ذكي']);
  }

  static List<String> _tagsFromText(String text) {
    final tags = <String>[];
    if (text.contains('قرآن') || text.contains('سورة') || text.contains('حفظ')) {
      tags.add('قرآني');
    }
    if (text.contains('فقه') || text.contains('توحيد') || text.contains('عقيدة')) {
      tags.add('فقهي');
    }
    if (text.contains('سيرة') || text.contains('حديث')) {
      tags.add('شرعي');
    }
    if (text.contains('لغة')) {
      tags.add('لغوي');
    }
    if (text.contains('تاريخ')) {
      tags.add('تاريخي');
    }
    if (text.contains('مسابقة') || text.contains('سؤال')) {
      tags.add('مسابقة');
    }
    return tags.take(3).toList();
  }

  static String _sourceName(String sourceFile) {
    var s = sourceFile
        .replaceAll(RegExp(r'\.(docx?|txt|htm|html)$'), '')
        .replaceFirst(RegExp(r'^\s*\d+\s*[-.)ـ]\s*'), '')
        .replaceAll(RegExp(r'[\s_-]+'), ' ')
        .trim();
    return s.isEmpty ? sourceFile : s;
  }

  static String _shorten(String s, int max) {
    if (s.length <= max) return s;
    final cut = s.substring(0, max).replaceFirst(RegExp(r'\s+\S*$'), '');
    return '$cut…';
  }

  static String _hashId(String title, String sourceFile) {
    final input = '$title|$sourceFile';
    var hash = 5381;
    for (final unit in input.codeUnits) {
      hash = ((hash << 5) + hash) + unit;
      hash = hash & 0x7FFFFFFF;
    }
    return hash.toRadixString(16);
  }
}
