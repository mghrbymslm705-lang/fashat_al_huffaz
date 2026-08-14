import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/app_logo.dart';

/// صفحة "حول التطبيق".
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Center(child: AppLogo(size: 150)),
          SizedBox(height: 16),
          Text(
            AppConstants.appName,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
          ),
          SizedBox(height: 8),
          Text(
            AppConstants.appDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.7),
          ),
          SizedBox(height: 24),
          _InfoRow(label: 'الجهة المعدة', value: AppConstants.appProducer),
          _InfoRow(label: 'الإصدار', value: AppConstants.appVersion),
          _InfoRow(label: 'الاتصال بالإنترنت', value: 'روابط الشرح فقط'),
          _InfoRow(label: 'العمل دون اتصال', value: 'مدعوم بالكامل'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
