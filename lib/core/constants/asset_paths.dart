/// مسارات الأصول (Assets) المستخدمة في التطبيق.
///
/// ميزة أساسية: مجلد الأنشطة كاملًا مضمّن في pubspec.yaml،
/// لذا فإن إضافة أي ملف JSON جديد إليه يكفي لظهور محتواه
/// تلقائيًا دون أي تعديل على الكود (انظر LocalActivityDatasource).
class AssetPaths {
  AssetPaths._();

  /// مجلد بيانات الأقسام والفهارس.
  static const String dataFolder = 'assets/data/';

  /// ملف الأقسام (التصنيفات الرئيسية).
  static const String categoriesFile = 'assets/data/categories.json';

  /// مجلد ملفات الأنشطة (يُحمّل كاملًا تلقائيًا).
  static const String activitiesFolder = 'assets/data/activities/';

  /// ملف القالب الذي يوضح بنية نشاط واحد (لا يُعدّ نشاطًا فعليًا).
  static const String templateFile = 'assets/data/activities/template.json';
}
