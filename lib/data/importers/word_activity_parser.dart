/// محلّل نصوص وورد إلى أنشطة.
///
/// يأخذ سطور النص المستخرجة من ملف وورد ويحوّلها إلى قائمة خرائط
/// أنشطة بصيغة ActivityModel، مع:
/// - اكتشاف عنوان كل لعبة/مسابقة (مرقّمة أو بعنوان نصي).
/// - استخراج الحقول المألوفة (المشاركين، الزمن، الأدوات، الشرح، الخطوات).
/// - تصنيف تلقائي للقسم المناسب بناءً على كلمات مفتاحية في العنوان والمحتوى.
///
/// هذا الملف خالٍ من استيرادات Flutter ليمكن استخدامه أيضًا
/// في أدوات تحويل الملفات خارج بيئة الواجهة.
class WordActivityParser {
  WordActivityParser._();

  /// يحوّل سطور النص إلى قائمة خرائط أنشطة.
  static List<Map<String, dynamic>> parse(
    List<String> lines, {
    required String sourceFile,
  }) {
    final cleaned = _cleanLines(lines, sourceFile);
    final sections = _splitSections(cleaned);

    final result = <Map<String, dynamic>>[];
    for (final section in sections) {
      final activity = _buildActivity(section, sourceFile);
      if (activity != null) result.add(activity);
    }
    return result;
  }

  // -------------------- تنظيف --------------------

  /// إزالة السطور التمهيدية والضوضاء والمواقع والروابط.
  static List<String> _cleanLines(List<String> lines, String sourceFile) {
    final out = <String>[];
    for (final raw in lines) {
      var s = raw.trim();
      if (s.isEmpty) continue;

      // تجاهل الترويسات الثابتة والمواقع والروابط.
      if (s.startsWith('بسم الله') && s.length < 40) continue;
      if (RegExp(r'^www\.|^http|HYPERLINK|المفكرة الدعوية').hasMatch(s)) {
        continue;
      }
      if (s == 'رفعه  للمفكرة الدعوية') continue;

      // أسماء المؤلفين في الترويسة.
      if (RegExp(r'^(تأليف|إعداد|اعداد|رفعه)\s*[: :].{0,40}$').hasMatch(s) &&
          out.isEmpty) {
        continue;
      }

      s = s.replaceAll(RegExp(r'^[\s\d-ـ_*]+$'), '').trim();
      if (s.isEmpty) continue;

      out.add(s);
    }
    return out;
  }

  // -------------------- تقسيم الأقسام --------------------

  /// تقسيم السطور إلى أقسام، كل قسم يبدأ بسطر عنوان.
  static List<List<String>> _splitSections(List<String> lines) {
    final sections = <List<String>>[];
    List<String>? current;

    for (final line in lines) {
      if (_isTitle(line)) {
        current = [line];
        sections.add(current);
      } else {
        if (current == null) {
          // نص تمهيدي قبل أول عنوان: لا نعتبره قسمًا (مقدمة الملف).
          current = null;
          continue;
        }
        current.add(line);
      }
    }

    // قسم بلا عنوان بعده (مقدمة فقط) → نتجاهله.
    return sections.where((s) => s.length >= 2 || _isTitle(s.first)).toList();
  }

  /// هل هذا السطر عنوان لعبة/مسابقة؟
  static bool _isTitle(String line) {
    if (line.length > 120) return false;
    final trimmed = line.trim();

    // نتجاهل جمل التمهيد والترويسة والمواقع.
    if (RegExp(r'(www\.|http|HYPERLINK|المفكرة الدعوية|المتعة مع البرامج|تأليف|إعداد|بسم الله|رفعه|أبو فيصل)')
        .hasMatch(trimmed)) {
      return false;
    }
    if (RegExp(r'^(هذه|وهذه|من|بعض|وهو|وهي|يمكن|يتم|ويمكن|تجد|ستتسابق|وهناك|ثم|أما|وقد)\b').hasMatch(trimmed) &&
        trimmed.length > 30) {
      return false;
    }

    // أرقام متسلسلة: "1- معركة الأكتاف" أو "1) ..." أو "1-لائحة التسوق".
    if (RegExp(r'^\s*\d+\s*[-.)ـ]').hasMatch(trimmed)) {
      // نتجاهل سطر "1-" وحده أو سطور الشرح الطويلة (خطوات داخل مسابقة).
      final textAfterNumber =
          trimmed.replaceFirst(RegExp(r'^\s*\d+\s*[-.)ـ]'), '').trim();
      if (textAfterNumber.length < 3 || textAfterNumber.length > 45) {
        return false;
      }
      // نتجاهل العبارات التي تبدأ بفعل/اسم يشير إلى هدف أو فائدة لا عنوانًا.
      if (RegExp(
        r'^(مساعدة|اكتساب|تكسبه|تدفعه|تجعل|توصيل|الإرشاد|تقوية|حث|سهولة|دعم|التعرف|موعظة|خطوة|طلاقة|القدرة|أهداف|فهمها|ستدفعين|إن المتسابقة)(\s|$)',
      ).hasMatch(textAfterNumber)) {
        return false;
      }
      return true;
    }

    // عناوين نصية: "المسابقة الأولى:- البحث عن الإجابة".
    if (RegExp(r'^(المسابقة|مسابقة)\s+(الأولى|الثانية|الثالثة|الرابعة|الخامسة|السادسة|السابعة|الثامنة|التاسعة|العاشرة)').hasMatch(trimmed)) {
      return true;
    }

    // "فكرة *- مسابقة ...".
    if (RegExp(r'^فكرة\s*\*?\s*[-:—]').hasMatch(trimmed)) {
      return true;
    }

    // كلمات مفتاحية في بداية سطر قصير تدل على عنوان لعبة/برنامج.
    if (RegExp(r'^(لعبة|اللعبة|برنامج|مهرجان|نشاط|فكرة|مسابقة)\b').hasMatch(trimmed) &&
        trimmed.length <= 70) {
      return true;
    }

    return false;
  }

  // -------------------- بناء النشاط --------------------

  static Map<String, dynamic>? _buildActivity(
    List<String> section,
    String sourceFile,
  ) {
    final title = _cleanTitle(section.first);
    if (title.isEmpty) return null;

    final rawBody = section.skip(1).join(' ');

    // المشاركين/الزمن إن وُجدت في سطور منفصلة أيضًا.
    String? participantsLine;
    String? durationLine;
    for (final line in section) {
      if (line.contains('المشاركين') || line.contains('المشاركون')) {
        participantsLine = line;
      }
      if (line.contains('الزمن') || line.contains('المدة')) {
        durationLine = line;
      }
    }

    final categoryInfo = _detectCategory(title, '$rawBody $sourceFile');

    final body = _stripLeadingFields(rawBody);

    final fields = _extractFields(body);
    final steps = _extractSteps(body)
        .map(_stripLeadingFields)
        .where((s) => s.length >= 5)
        .toList();

    final description = fields.description ??
        (steps.isEmpty
            ? body.trim()
            : fields.preIntro?.trim() ?? body.trim());

    // عناوين بلا محتوى (قوائم فرعية داخل البرامج) → نتجاهلها،
    // إلا إذا حمل العنوان نفسه شرحًا (نقطتان ثم نص) أو كان طويلًا.
    final hasInlineContent =
        title.contains(' : ') || title.endsWith(':') || title.length >= 40;
    if (description.trim().isEmpty &&
        steps.isEmpty &&
        fields.tools.isEmpty &&
        !hasInlineContent) {
      return null;
    }

    return {
      'id': 'word_${_hashId(title, sourceFile)}',
      'title': title,
      'category': categoryInfo.category,
      'types': categoryInfo.types,
      'description': _shorten(description, 400),
      'participants': participantsLine != null
          ? _rangeFromLine(participantsLine)
          : const {'min': 0, 'max': 0},
      'duration': durationLine != null
          ? _rangeFromLine(durationLine)
          : const {'min': 0, 'max': 0},
      'movement': _movementLabel(categoryInfo.category),
      'location': 'داخل',
      'tools': fields.tools,
      'steps': steps.isNotEmpty ? steps : _fallbackSteps(body),
      'benefits': const [],
      'tips': const [],
      'tags': _tagsFromText('$title $body'),
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

  /// إزالة الحقول الوصفية من بداية نص (المشاركين/الزمن/الأدوات...) حتى
  /// يبقى المحتوى الفعلي للعبة فقط.
  static String _stripLeadingFields(String raw) {
    var s = raw.trim();

    // علامات المحتوى: بعضها يُشطب (labels) والبعض يُحتفظ بكلمته (أفعال).
    final labelMatch = RegExp(
      r'^\s*(?:شرح\s*(?:طريقة)?\s*اللعبة|طريقة اللعبة|طريقة المسابقة|الشرح)\s*[::]?\s*',
    ).matchAsPrefix(s);
    if (labelMatch != null) {
      s = s.substring(labelMatch.end).trim();
      s = s.replaceFirst(RegExp(r'^(أن|بأن|على أن)\s+'), '').trim();
      return s;
    }

    // كتلة الحقول الوصفية في البداية: نُبقي النص بعدها.
    final fieldMatch = RegExp(
      r'^\s*(?:عدد المشاركين|المشاركين|المشاركون|الزمن المتوقع|الوقت المتوقع|'
      r'المدة الزمنية|المواد المطلوبة|الأدوات المطلوبة)\s*[::]?\s*[^.:]{0,80}?\s*[-:]\s*',
    ).matchAsPrefix(s);
    if (fieldMatch != null) {
      return s.substring(fieldMatch.end).trim();
    }

    return s;
  }

  static String _cleanTitle(String raw) {
    var s = raw
        .replaceFirst(RegExp(r'^\s*\d+\s*[.-ـ]'), '')
        .replaceFirst(RegExp(r'^فكرة\s*\*?\s*[-:—]'), '')
        .replaceFirst(RegExp(r'^[\s\d-ـ_*]+'), '')
        .trim();
    s = s.replaceAll(RegExp(r'[:\-—_*.]+\s*$'), '').trim();

    // قطع العنوان عند بدء الحقول الوصفية الملتصقة به
    // (مثل: "مـلء الكـأس المشاركين : 1 من كل فريق ...").
    final fieldCut = RegExp(
      r'\s*(?:عدد المشاركين|المشاركين|المشاركون|الزمن المتوقع|الوقت المتوقع|'
      r'المدة الزمنية|الأدوات المطلوبة|المواد المطلوبة|طريقة اللعبة|شرح|الهدف)\s*[::]?\s*',
    ).firstMatch(s);
    if (fieldCut != null) {
      s = s.substring(0, fieldCut.start).trim();
    }
    return s.trim();
  }

  /// استخراج حقول معروفة من نص القسم.
  static _Fields _extractFields(String body) {
    String? description;
    String? preIntro;
    List<String> tools = const [];

    // الأدوات المطلوبة.
    final toolsMatch = RegExp(r'الأدوات المطلوبة\s*[:]?\s*([^.]+)').firstMatch(body);
    if (toolsMatch != null) {
      final raw = toolsMatch.group(1)!.trim();
      if (raw.isNotEmpty && !raw.contains('شرح')) {
        tools = raw
            .split(RegExp(r'[,،/]|\sو\s| أو '))
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty && t.length >= 2)
            .toList();
      }
    }

    // شرح طريقة اللعبة.
    final explainMatch =
        RegExp(r'(?:شرح\s*(?:طريقة)?\s*اللعبة|طريقة اللعبة|الشرح|طريقة المسابقة)\s*[:]?\s*(.+)')
            .firstMatch(body);
    if (explainMatch != null) {
      final raw = explainMatch.group(1)!.trim();
      if (raw.isNotEmpty) {
        description = raw;
      }
    }

    // جملة تمهيدية قبل بدء التفاصيل.
    final introMatch = RegExp(r'^(.+?)\s*(?:شرح|طريقة|يقوم|يلعب|توضع|على الأطفال)')
        .firstMatch(body);
    if (introMatch != null) preIntro = introMatch.group(1)!.trim();

    return _Fields(description: description, preIntro: preIntro, tools: tools);
  }

  /// استخراج الخطوات المرقّمة (1- ... 2- ... إلخ).
  static List<String> _extractSteps(String body) {
    final steps = <String>[];
    final matches = RegExp(r'(?:^|\s)(\d+)\s*[.\-ـ]\s*([^0-9]{5,})')
        .allMatches(' $body ');
    for (final m in matches) {
      final step = m.group(2)!.trim();
      if (step.length >= 5 && !RegExp(r'^(أن|مع|من|إلى|على|في)\b').hasMatch(step)) {
        steps.add(step);
      }
    }
    return steps;
  }

  /// خطوات احتياطية: تقسيم الوصف إلى جمل مفيدة.
  static List<String> _fallbackSteps(String body) {
    final clean = body
        .replaceAll(RegExp(r'(شرح\s*(طريقة)?\s*اللعبة|طريقة اللعبة|الشرح)\s*[:]?'), '')
        .trim();
    if (clean.isEmpty) return const [];
    final parts = clean
        .split(RegExp(r'(?<=[.!؟])\s+'))
        .map((s) => s.trim())
        .where((s) => s.length >= 15)
        .toList();
    return parts.isEmpty ? [clean] : parts;
  }

  static List<String> _tagsFromText(String text) {
    final tags = <String>[];
    if (text.contains('قرآن') || text.contains('سورة') || text.contains('حفظ')) {
      tags.add('قرآني');
    }
    if (text.contains('حرك') || text.contains('كرة')) tags.add('حركي');
    if (text.contains('جماع') || text.contains('فريق')) tags.add('جماعي');
    if (text.contains('أطفال') || text.contains('طفل')) tags.add('أطفال');
    if (text.contains('مسابقة') || text.contains('سؤال')) tags.add('مسابقة');
    if (text.contains('ذكاء') || text.contains('تذكر')) tags.add('ذاكرة');
    return tags.take(3).toList();
  }

  /// تحديد القسم تلقائيًا من الكلمات المفتاحية.
  static _CategoryInfo _detectCategory(String title, String fullText) {
    final text = ' $title $fullText ';

    if (RegExp(r'قرآن|سورة|آية|حفظ|تجويد|تفسير|مراجعة|جزء\s?\d+').hasMatch(text)) {
      return const _CategoryInfo(category: 'quranic', types: ['قرآني', 'ذكي']);
    }
    if (RegExp(r'حرك|كرة|جري|قفز|ميداني|رياض|قفزة|سباق|لياقة').hasMatch(text)) {
      return const _CategoryInfo(
          category: 'kinetic', types: ['حركي', 'جماعي']);
    }
    if (RegExp(r'لغز|ذكاء|تذكر|ذاكرة|أحجية|تفكير').hasMatch(text)) {
      return const _CategoryInfo(category: 'intelligence', types: ['ذكي']);
    }
    if (RegExp(r'فريق|مجموعات|زمر|فرق|جماعي').hasMatch(text)) {
      return const _CategoryInfo(category: 'group', types: ['جماعي']);
    }
    if (RegExp(r'أطفال|طفل|الصغار|للأطفال').hasMatch(text)) {
      return const _CategoryInfo(category: 'kids', types: ['جماعي']);
    }
    if (RegExp(r'ثقاف|معلومة|تاريخ|جغراف|أسئلة عامة|سؤال').hasMatch(text)) {
      return const _CategoryInfo(category: 'culture', types: ['ذكي']);
    }
    if (RegExp(r'فقه|حديث|سيرة|توحيد|آداب|أذكار|صلاة|إسلام').hasMatch(text)) {
      return const _CategoryInfo(category: 'islamic', types: ['ذكي']);
    }
    if (RegExp(r'برنامج|مهرجان|خطة|مخيم|مركز صيفي|حلقة').hasMatch(text)) {
      return const _CategoryInfo(category: 'programs', types: ['برنامج']);
    }
    return const _CategoryInfo(category: 'culture', types: ['ذكي']);
  }

  static String _movementLabel(String category) {
    if (category == 'kinetic') return 'حركية';
    if (category == 'intelligence' || category == 'culture') return 'ساكنة';
    return 'متوسطة';
  }

  static String _sourceName(String sourceFile) {
    var s = sourceFile.replaceAll(RegExp(r'\.(docx?|txt)$'), '');
    return s.trim().isEmpty ? sourceFile : s;
  }

  /// استخراج نطاق رقمي من سطر مثل "من (2) إلى (5)".
  static Map<String, int> _rangeFromLine(String line) {
    final numbers =
        RegExp(r'\d+').allMatches(line).map((m) => int.parse(m.group(0)!)).toList();
    if (numbers.isEmpty) return const {'min': 0, 'max': 0};
    if (numbers.length == 1) return {'min': numbers[0], 'max': numbers[0]};
    final min = numbers[0] < numbers[1] ? numbers[0] : numbers[1];
    final max = numbers[0] < numbers[1] ? numbers[1] : numbers[0];
    return {'min': min, 'max': max};
  }

  static String _shorten(String s, int max) {
    if (s.length <= max) return s;
    final cut = s.substring(0, max).replaceFirst(RegExp(r'\s+\S*$'), '');
    return '$cut…';
  }

  /// معرّف ثابت مستقر من العنوان واسم الملف.
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

class _Fields {
  const _Fields({this.description, this.preIntro, this.tools = const []});
  final String? description;
  final String? preIntro;
  final List<String> tools;
}

class _CategoryInfo {
  const _CategoryInfo({required this.category, required this.types});
  final String category;
  final List<String> types;
}
