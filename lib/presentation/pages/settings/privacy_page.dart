import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// صفحة "سياسة الخصوصية".
///
/// نص ثابت يوضح سياسة التطبيق: لا يجمع بيانات، لا يتصل بخدمات خارجية
/// للحصول على محتوى، الإنترنت مقتصر على روابط الشرح.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الخصوصية')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _PolicyItem(
            icon: Icons.shield_rounded,
            title: 'خصوصية البيانات',
            body: 'تطبيق فسحة الحفّاظ لا يجمع أي بيانات شخصية ولا يرسلها '
                'إلى أي جهة. جميع بياناتك (المفضلة والإعدادات) تُحفظ محليًا '
                'على جهازك فقط.',
          ),
          _PolicyItem(
            icon: Icons.folder_open_rounded,
            title: 'محتوى التطبيق',
            body: 'جميع الألعاب والأنشطة والمسابقات الموجودة في التطبيق مصدرها '
                'ملفات JSON التي يضيفها المشرف/المعلم. التطبيق لا ينشئ أي محتوى '
                'من تلقاء نفسه ولا يعدّله.',
          ),
          _PolicyItem(
            icon: Icons.wifi_rounded,
            title: 'استخدام الإنترنت',
            body: 'لا يتصل التطبيق بأي خدمة خارجية لجلب المحتوى. يُستخدم '
                'الإنترنت فقط عند الضغط على زر "مشاهدة الشرح" لفتح رابط الفيديو '
                'الذي يضيفه المشرف.',
          ),
          _PolicyItem(
            icon: Icons.verified_user_rounded,
            title: 'أمان الأطفال',
            body: 'الواجهة مصممة لتكون آمنة ومناسبة للأطفال، ولا يتضمن '
                'التطبيق أي إعلانات أو محتوى من خارج مكتبة المشرف.',
          ),
        ],
      ),
    );
  }
}

class _PolicyItem extends StatelessWidget {
  const _PolicyItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(height: 1.7, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
