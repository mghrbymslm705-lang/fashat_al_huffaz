import '../../core/utils/arabic_text.dart';

/// يحوّل أسماء الأقسام المرنة في ملفات JSON إلى معرّفات الأقسام المعتمدة.
///
/// يدعم الأسماء العربية والإنجليزية، ويدعم أيضًا المعرّفات المخصصة
/// (تعود كما هي لتُعرض كقسم ديناميكي جديد دون تعديل الكود).
class CategoryResolver {
  CategoryResolver._();

  static const Map<String, String> _exact = {
    // معرّفات إنجليزية معتمدة.
    'quranic': 'quranic',
    'islamic': 'islamic',
    'kinetic': 'kinetic',
    'intelligence': 'intelligence',
    'group': 'group',
    'culture': 'culture',
    'kids': 'kids',
    'programs': 'programs',
    // أسماء عربية.
    'الأنشطة القرآنية': 'quranic',
    'أنشطة قرآنية': 'quranic',
    'قرآنية': 'quranic',
    'قرآني': 'quranic',
    'قرآن': 'quranic',
    'الأنشطة الإسلامية': 'islamic',
    'أنشطة إسلامية': 'islamic',
    'إسلامية': 'islamic',
    'إسلامي': 'islamic',
    'الألعاب الحركية': 'kinetic',
    'ألعاب حركية': 'kinetic',
    'حركية': 'kinetic',
    'حركي': 'kinetic',
    'ألعاب الذكاء': 'intelligence',
    'ذكاء': 'intelligence',
    'الذكاء': 'intelligence',
    'الألعاب الجماعية': 'group',
    'ألعاب جماعية': 'group',
    'جماعية': 'group',
    'جماعي': 'group',
    'المسابقات الثقافية': 'culture',
    'مسابقات ثقافية': 'culture',
    'ثقافية': 'culture',
    'ثقافي': 'culture',
    'ألعاب الأطفال': 'kids',
    'أطفال': 'kids',
    'الأطفال': 'kids',
    'البرامج التربوية': 'programs',
    'برامج تربوية': 'programs',
    'تربوية': 'programs',
    'برامج': 'programs',
  };

  /// كلمات تُطابق قسما معيّنًا عند وجودها ضمن النص.
  static const Map<String, String> _contains = {
    'قرآن': 'quranic',
    'إسلام': 'islamic',
    'حرك': 'kinetic',
    'ذكاء': 'intelligence',
    'جماع': 'group',
    'ثقاف': 'culture',
    'طفل': 'kids',
    'أطفال': 'kids',
    'برنامج': 'programs',
    'تربوي': 'programs',
  };

  /// تحليل قيمة القسم وإرجاع معرّف معتمد أو القيمة نفسها (قسم ديناميكي).
  static String resolve(String raw) {
    final original = raw.trim();
    if (original.isEmpty) return 'other';

    final normalized = ArabicText.normalize(original);

    // مطابقة تامة (بعد التطبيع).
    final exactKey = _exact.keys
        .map(ArabicText.normalize)
        .where((k) => k == normalized);
    if (exactKey.isNotEmpty) {
      final originalKey = _exact.keys.firstWhere(
        (k) => ArabicText.normalize(k) == normalized,
      );
      return _exact[originalKey]!;
    }

    // مطابقة بالاحتواء (مثل: "الألعاب الحركية الممتعة").
    for (final entry in _contains.entries) {
      if (normalized.contains(ArabicText.normalize(entry.key))) {
        return entry.value;
      }
    }

    // قيمة مخصصة: تُعامل كمعرّف قسم ديناميكي (يُعرض بقسم جديد تلقائيًا).
    return original;
  }
}
