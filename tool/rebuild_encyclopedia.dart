// أداة إعادة بناء موسوعة الأنشطة (تُشغَّل داخل هذا المجلد):
//   dart tool/rebuild_encyclopedia.dart            # معاينة فقط دون كتابة
//   dart tool/rebuild_encyclopedia.dart --apply    # تطبيق التعديلات
//
// ما تفعله:
// 1) إعادة تصنيف: ملفات quiz_folder_* → قسم qbank؛ تحويل الأقسام الديناميكية
//    العربية (بحث واكتشاف، إبداع وتأليف، قراءة ومكتبة، استماع وإنصات) إلى
//    معرّفاتها الجديدة (research, creative, reading, listen).
// 2) توحيد قيم types المبعثرة إلى قائمة محكومة (الحفاظ على كلمات المساعد الذكي).
// 3) إصلاح العناوين المكسورة في بنوك الأسئلة وتقسيم البنوك الضخمة إلى أجزاء.
// 4) لا يحذف محتوى، ولا يخترع حقولًا، ويحافظ على ترتيب الحقول في الملفات.

import 'dart:convert';
import 'dart:io';

const activitiesDir = 'assets/data/activities';
const thresholdSplitSteps = 100; // البنوك الأطول تُقسَّم
const partSize = 60; // نحو 60 خطوة لكل جزء

// معرّفات الأقسام الجديدة المطلوبة.
const _dynamicCategoryMap = <String, String>{
  'بحث واكتشاف': 'research',
  'إبداع وتأليف': 'creative',
  'قراءة ومكتبة': 'reading',
  'استماع وإنصات': 'listen',
  'culture': 'qbank',
};

// توحيد أنواع الأنشطة: القيمة الحالية → القيمة الموحدة (خريطة كاملة).
const _typeMap = <String, String?>{
  'قرآني': 'قرآني',
  'إسلامي': 'إسلامي',
  'ثقافي': 'ثقافي',
  'ترفيهي': 'ترفيهي',
  'جماعي': 'جماعي',
  'فردي': 'فردي',
  'حركي': 'حركي',
  'سريع': 'سريع',
  'تربوي': 'تربوي',
  'إبداعي': 'إبداعي',
  'تأليف': 'تأليف',
  'تعبير': 'تعبير',
  'حفظ': 'حفظ',
  'تثبيت': 'تثبيت',
  'مراجعة': 'مراجعة',
  'تلاوة': 'تلاوة',
  'سيرة': 'سيرة',
  'فقه': 'فقه',
  'عقيدة': 'عقيدة',
  'آداب': 'آداب',
  'ألغاز': 'ألغاز',
  'ذاكرة': 'ذاكرة',
  'ذكاء': 'ذكاء',
  'حساب': 'حساب',
  'أرقام': 'أرقام',
  'حروف': 'حروف',
  'فهم': 'فهم',
  'بحث': 'بحث',
  'اكتشاف': 'اكتشاف',
  'قراءة': 'قراءة',
  'مكتبة': 'مكتبة',
  'استماع': 'استماع',
  'رمضان': 'رمضان',
  'أسبوعي': 'أسبوعي',
  'مواسم': 'مواسم',
  'برامج': 'برامج',
  'متابعة': 'متابعة',
  'صلاة': 'صلاة',
  'عبادة': 'عبادة',
  'عيد': 'عيد',
  'تحفيز': 'تحفيز',
  'تكريم': 'تكريم',
  'تلوين': 'تلوين',
  'مطبوعات': 'مطبوعات',
  'بطاقات': 'بطاقات',
  'أوراق عمل': 'أوراق عمل',
  'فعالية': 'فعالية',
  'قصصي': 'قصصي',
  'بنك أسئلة': 'بنك أسئلة',
  'صنع': 'صنع',
  'عرض': 'عرض',
  'حوار': 'حوار',
  'تجربة': 'تجربة',
  // توحيد المتغيرات.
  'رمضاني': 'رمضان',
  'إبداع': 'إبداعي',
  'حرف': 'حروف',
  'إيماني': 'عقيدة',
  'سرعة': 'سريع',
  'ذكي': 'بنك أسئلة',
  'أنشطة': null, // مقترح للحذف عند عدم وجود معلومات أصيلة
  'أفكار': null,
  'خارجي': null,
  'استمرارية': 'أسبوعي',
};

void main(List<String> args) {
  final apply = args.contains('--apply');
  final dir = Directory(activitiesDir);
  if (!dir.existsSync()) {
    stdout.writeln('تعذر إيجاد مجلد: $activitiesDir');
    exitCode = 1;
    return;
  }

  var totalActivities = 0;
  var totalFiles = 0;
  var reclassified = 0;
  var titleFixed = 0;
  var typeChanged = 0;
  var splitCreated = 0;
  final reports = <String>[];

  for (final file in dir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.json') || file.uri.pathSegments.last == 'template.json') {
      continue;
    }
    totalFiles++;

    final rawText = file.readAsStringSync();
    final json = _decode(rawText);
    if (json == null) {
      reports.add('[خطأ] ${file.uri.pathSegments.last}: غير قابل للقراءة');
      continue;
    }

    final fileName = file.uri.pathSegments.last;
    final isQuizFolder = fileName.startsWith('quiz_folder_');

    final List<Map<String, dynamic>> activities;
    Object? wrapper = json;
    if (json is List) {
      activities = List<Map<String, dynamic>>.from(
        json.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
      );
      wrapper = null;
    } else if (json is Map) {
      final nested = json['activities'] ??
          json['items'] ??
          json['games'] ??
          json['الأنشطة'] ??
          json['data'];
      if (nested is List) {
        activities = List<Map<String, dynamic>>.from(
          nested.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        );
        wrapper = json;
      } else if (json.containsKey('title')) {
        activities = [Map<String, dynamic>.from(json)];
        wrapper = null;
      } else {
        activities = <Map<String, dynamic>>[];
        wrapper = json;
      }
    } else {
      activities = <Map<String, dynamic>>[];
      wrapper = json;
    }

    totalActivities += activities.length;

    final rebuilt = <Map<String, dynamic>>[];
    final fileTitleNotes = <String>[];
    for (var activity in activities) {
      activity = Map<String, dynamic>.from(activity);

      // 1) إعادة التصنيف.
      final oldCategory = activity['category']?.toString() ?? '';
      final newCategory = isQuizFolder
          ? 'qbank'
          : (_dynamicCategoryMap[oldCategory] ?? oldCategory);

      String? titleNote;
      final oldTitle = activity['title']?.toString() ?? '';
      if (isQuizFolder) {
        final fixed = _fixQuizTitle(activity, oldTitle);
        if (fixed != oldTitle) {
          titleFixed++;
          titleNote = 'العنوان: "$oldTitle" ← "$fixed"';
          activity['title'] = fixed;
        }
        // بنوك أسئلة: لا نضيف لها مدة/مشاركين/عمرًا (غير أصيلة).
      }

      if (oldCategory.isNotEmpty && newCategory != oldCategory) {
        reclassified++;
      }
      activity['category'] = newCategory;

      // 2) توحيد الأنواع.
      final types = _unifyTypes(activity['types'], isQuizFolder);
      if (!_sameList(activity['types'], types)) typeChanged++;
      activity['types'] = types;

      // 3) تقسيم البنوك الضخمة قبل إضافتها.
      final steps = activity['steps'] is List ? List<String>.from(activity['steps']) : <String>[];
      if (isQuizFolder && steps.length > thresholdSplitSteps) {
        final parts = _splitBank(activity, steps);
        rebuilt.addAll(parts);
        splitCreated += parts.length - 1;
        reports.add('[تقسيم] ${activity['id']} ← ${parts.length} أجزاء');
      } else {
        rebuilt.add(activity);
      }
      if (titleNote != null) fileTitleNotes.add(titleNote);
    }

    final outObject = _updateRoot(json, wrapper, rebuilt);
    if (apply) {
      _write(file, outObject);
    }

    reports.add(
      '${fileName.padRight(24)} | أنشطة: ${rebuilt.length.toString().padLeft(3)} | '
      '${isQuizFolder ? "(بنك أسئلة → qbank)" : ""}${fileTitleNotes.join(" • ")}',
    );
  }

  reports.sort();

  stdout.writeln('===== ملخص التحويل =====');
  stdout.writeln('ملفات: $totalFiles');
  stdout.writeln('أنشطة: قبل = $totalActivities');
  stdout.writeln('أعيد تصنيفها: $reclassified');
  stdout.writeln('عناوين أُصلحت: $titleFixed');
  stdout.writeln('قيم types تغيّرت: $typeChanged');
  stdout.writeln('أجزاء جديدة من التقسيم: $splitCreated');
  stdout.writeln('الوضع: ${apply ? "تطبيق ✓" : "معاينة فقط (أضف --apply للكتابة)"}');
  stdout.writeln('');
  stdout.writeln('===== التفاصيل =====');
  for (final line in reports) {
    stdout.writeln(line);
  }
}

// ---------------------------------------------------------------- استيعاب

Object? _decode(String raw) {
  try {
    final clean = raw.replaceAll('\uFEFF', '');
    return jsonDecode(clean);
  } catch (_) {
    return null;
  }
}

void _write(File file, Object? object) {
  const encoder = JsonEncoder.withIndent('  ');
  final text = encoder.convert(object);
  file.writeAsStringSync('$text\n', flush: true);
}

Object? _updateRoot(Object? original, Object? wrapper, List<Map<String, dynamic>> rebuilt) {
  if (original is List) return rebuilt;
  if (original is Map) {
    if (wrapper == null) return rebuilt.first;
    final copy = Map<String, dynamic>.from(original);
    if (copy['activities'] != null) {
      copy['activities'] = rebuilt;
    } else if (copy['items'] != null) {
      copy['items'] = rebuilt;
    } else if (copy['games'] != null) {
      copy['games'] = rebuilt;
    } else if (copy['الأنشطة'] != null) {
      copy['الأنشطة'] = rebuilt;
    } else if (copy['data'] != null) {
      copy['data'] = rebuilt;
    }
    return copy;
  }
  return original;
}

// ---------------------------------------------------------------- الأنواع

List<String> _unifyTypes(Object? raw, bool isQuiz) {
  List<String> input;
  if (raw is List) {
    input = raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
  } else if (raw != null && raw.toString().trim().isNotEmpty) {
    input = [raw.toString().trim()];
  } else {
    input = const [];
  }

  final out = <String>[];
  for (final t in input) {
    final mapped = _typeMap.containsKey(t) ? _typeMap[t] : t;
    if (mapped == null) continue;
    if (!out.contains(mapped)) out.add(mapped);
  }
  return out;
}

bool _sameList(Object? a, Object? b) {
  final la = (a is List ? a.map((e) => e.toString()).toList() : const <String>[]);
  final lb = (b is List ? b.map((e) => e.toString()).toList() : const <String>[]);
  if (la.length != lb.length) return false;
  for (var i = 0; i < la.length; i++) {
    if (la[i] != lb[i]) return false;
  }
  return true;
}

// ---------------------------------------------------------------- العناوين

String _fixQuizTitle(Map<String, dynamic> activity, String title) {
  final trimmed = title.trim();
  // عنوان مكسور: يبدأ بسؤال مقطوع أو جملة عامة بلا معنى.
  final broken = trimmed.isEmpty ||
      RegExp(r'^س\s*\d+\s*[)-]').hasMatch(trimmed) ||
      trimmed.contains('مسابقة مختارة من') ||
      trimmed.contains('..') ||
      trimmed.endsWith('الجواب');
  if (!broken) return title;

  // نستمد عنوانًا سليمًا من اسم المصدر إن وُجد.
  final sourceName = activity['source'] is Map
      ? (activity['source'] as Map)['name']?.toString().trim() ?? ''
      : '';
  if (sourceName.isNotEmpty) {
    return sourceName.replaceAll(RegExp(r'[\.\s]+$'), '');
  }
  // وإلا نستخدم أول سؤال داخل الخطوات بشكل مختصر.
  final steps = activity['steps'];
  if (steps is List && steps.isNotEmpty) {
    final first = steps.first.toString().trim();
    final clean = first
        .replaceAll(RegExp(r'^السؤال\s*[:-]\s*'), '')
        .replaceAll(RegExp(r'^س\s*\d+\s*[)-]\s*'), '');
    if (clean.isNotEmpty && clean.length <= 45 && !clean.contains('\n')) {
      return clean;
    }
  }
  return title;
}

// ---------------------------------------------------------------- التقسيم

List<Map<String, dynamic>> _splitBank(Map<String, dynamic> activity, List<String> steps) {
  final parts = <Map<String, dynamic>>[];
  final baseId = activity['id']?.toString() ?? 'quiz';
  final baseTitle = activity['title']?.toString() ?? 'مسابقة';

  var index = 0;
  var partNum = 1;
  while (index < steps.length) {
    final end = (index + partSize).clamp(index + 1, steps.length);
    final chunk = steps.sublist(index, end);

    final part = Map<String, dynamic>.from(activity);
    part['id'] = '$baseId-p$partNum';
    part['title'] = partNum == 1 && parts.isEmpty
        ? baseTitle
        : '$baseTitle (الجزء $partNum)';
    part['steps'] = chunk;
    // إبقاء بقية الحقول كما هي دون اختراع.
    parts.add(part);

    index = end;
    partNum++;
  }
  return parts;
}