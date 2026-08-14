/// ثوابت عامة خاصة بالتطبيق.
///
/// كل ما يخص هوية التطبيق ونصوصه الثابتة يُجمَّع هنا
/// حتى يسهل تعديله مستقبلًا دون البحث في الصفحات.
class AppConstants {
  AppConstants._();

  /// اسم التطبيق الظاهر للمستخدم.
  static const String appName = 'فسحة الحفّاظ';

  /// وصف قصير للتطبيق (يُستخدم في صفحة "حول التطبيق").
  static const String appDescription =
      'تطبيق تربوي وترفيهي لمعلمي حلقات القرآن الكريم، '
      'مكتبة منظمة من الألعاب والأنشطة والمسابقات والبرامج التربوية.';

  /// الجهة التي أعدّت التطبيق (تُعرض في صفحة "حول التطبيق").
  static const String appProducer = 'كتاب حي - جوهرة لتعليم القرآن الكريم';

  /// إصدار التطبيق.
  static const String appVersion = '1.0.0';

  /// بريد التواصل (يُفتح من صفحة "تواصل معنا").
  static const String contactEmail = 'info@example.com';

  /// رقم تواصل عبر واتساب (اختياري - عدّله لاحقًا).
  static const String contactWhatsApp = '';

  /// الرسالة الإلزامية عند عدم وجود نشاط يطابق معايير البحث.
  static const String noActivityMatchMessage =
      'لا يوجد نشاط يطابق المعايير المحددة داخل قاعدة البيانات الحالية.';

  /// أقصى عدد من النتائج يعرضها المساعد الذكي.
  static const int maxSuggestions = 10;

  /// القيمة الافتراضية للحد الأقصى في النطاقات غير المحددة.
  static const int unknownMax = 999;

  /// عدد خطوات أسئلة المساعد الذكي.
  static const int suggestSteps = 6;

  /// بادئة النشاط التجريبي (يُستخدم في صفحة التفاصيل فقط للتوضيح).
  static const String demoBadge = 'نموذج تجريبي';
}
