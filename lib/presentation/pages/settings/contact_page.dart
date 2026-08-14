import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_launcher.dart';

/// صفحة "تواصل معنا": بريد + واتساب (حسب ما يُعدّله المشرف).
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تواصل معنا')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'يسعدنا تواصلك معنا لأي استفسار أو ملاحظة حول التطبيق '
            'أو محتواه.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.7, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mail_rounded, color: Color(0xFF3B82F6)),
              title: const Text('البريد الإلكتروني',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text(AppConstants.contactEmail),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => AppLauncher.openEmail(context, AppConstants.contactEmail),
            ),
          ),
          if (AppConstants.contactWhatsApp.isNotEmpty)
            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.chat_rounded, color: Color(0xFF22C55E)),
                title: const Text('واتساب',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: const Text(AppConstants.contactWhatsApp),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => AppLauncher.openWhatsApp(
                  context,
                  AppConstants.contactWhatsApp,
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'ملاحظة: عدّل بيانات التواصل في الملف\n'
            'lib/core/constants/app_constants.dart',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}
