import 'dart:js' as js;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../../core/theme/app_colors.dart';
import '../providers/audio_provider.dart';

const _whatsappNumber = '212605706006';
const _appUrl =
    'https://mghrbymslm705-lang.github.io/fashat_al_huffaz/';

/// القائمة الجانبية: رأس متدرج + إجراءات سريعة + معلومات التطبيق.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor:
          isDark ? const Color(0xFF1A1F2E) : AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerTile(
                    icon: Icons.info_outline_rounded,
                    title: 'عن التطبيق',
                    subtitle: 'معلومات ووصف التطبيق',
                    onTap: () => _showAboutSheet(context),
                  ),
                  _DrawerTile(
                    icon: Icons.share_rounded,
                    title: 'مشاركة التطبيق',
                    subtitle: 'شارك التطبيق مع أصدقائك',
                    color: AppColors.blue,
                    onTap: () => _shareApp(),
                  ),
                  _DrawerTile(
                    icon: Icons.lightbulb_rounded,
                    title: 'اقتراح نشاط',
                    subtitle: 'اقترح نشاطًا جديدًا على التطبيق',
                    color: AppColors.gold,
                    onTap: () {
                      Navigator.pop(context);
                      _suggestActivity();
                    },
                  ),
                  const SizedBox(height: 8),
                  const Divider(indent: 16, endIndent: 16),
                  const SizedBox(height: 8),
                  _DrawerTile(
                    icon: Icons.settings_rounded,
                    title: 'الإعدادات',
                    subtitle: 'تخصيص التطبيق',
                    onTap: () {
                      Navigator.pop(context);
                      onOpenSettings?.call();
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.install_mobile_rounded,
                    title: 'تثبيت التطبيق',
                    subtitle: 'أضفه إلى شاشة هاتفك',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _installApp(context);
                    },
                  ),
                  _AudioToggle(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'فسحة الحفّاظ  v1.0.0',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'فسحة الحفّاظ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'مكتبة الأنشطة التربوية لحلقات تحفيظ القرآن الكريم',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AboutSheet(),
    );
  }

  Future<void> _shareApp() async {
    if (kIsWeb) {
      try {
        final data = js.context.callMethod('Object', []);
        data['title'] = 'فسحة الحفّاظ';
        data['text'] = 'فسحة الحفّاظ - مكتبة الأنشطة التربوية لحلقات تحفيظ القرآن الكريم\n\nتطبيق يحتوي على ألعاب وأنشطة تربوية متنوعة لتعلم القرآن بطرق ممتعة.';
        data['url'] = _appUrl;
        js.context.callMethod('shareApp', [data]);
      } catch (_) {
        await Share.share(
          'فسحة الحفّاظ - مكتبة الأنشطة التربوية لحلقات تحفيظ القرآن الكريم\n\n$_appUrl',
        );
      }
    } else {
      await Share.share(
        'فسحة الحفّاظ - مكتبة الأنشطة التربوية لحلقات تحفيظ القرآن الكريم\n\n$_appUrl',
      );
    }
  }

  Future<void> _suggestActivity() async {
    final url = Uri.parse(
      'https://wa.me/$_whatsappNumber?text=${Uri.encodeFull('مرحبًا، أريد اقتراح نشاط جديد لتطبيق فسحة الحفّاظ:\n\n• اسم النشاط:\n• القسم:\n• الفئة العمرية:\n• 설명 مختصر:\n')}',
    );
    if (await url_launcher.canLaunchUrl(url)) {
      await url_launcher.launchUrl(url,
          mode: url_launcher.LaunchMode.externalApplication);
    }
  }

  Future<void> _installApp(BuildContext context) async {
    if (kIsWeb) {
      try {
        final result = js.context.callMethod('promptInstall');
        if (result == 'unavailable') {
          _showInstallGuide(context);
        }
      } catch (_) {
        _showInstallGuide(context);
      }
    } else {
      _showInstallGuide(context);
    }
  }

  void _showInstallGuide(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'لتثبيت التطبيق على هاتفك:\n'
          'اضغط زر المشاركة ← "إضافة إلى الشاشة الرئيسية"',
          textDirection: TextDirection.rtl,
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'حسناً',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  عنصر القائمة الجانبية
// ══════════════════════════════════════════════════════════════

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tileColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: tileColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.textSecondary
                      .withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ورقة "عن التطبيق"
// ══════════════════════════════════════════════════════════════

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // مؤشر السحب
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // الشعار
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'فسحة الحفّاظ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'الإصدار 1.0.0',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _AboutSection(
                title: 'التعريف بالتطبيق',
                body:
                    'فسحة الحفّاظ هو تطبيق تربوي إسلامي مخصص لأيام تحفيظ القرآن الكريم (حلقات الحفظ). '
                    'يحتوي على مئات الأنشطة والألعاب التفاعلية المتنوعة التي تساعد على تثبيت الحفظ '
                    'وإضفاء المرح على الحلقات.',
              ),
              const SizedBox(height: 16),
              const _AboutSection(
                title: 'المحتوى',
                body:
                    '• أنشطة تحفيظ القرآن (تجويد، تلاوة، حفظ)\n'
                    '• أنشطة ثقافية إسلامية (عقيدة، سيرة، فقه)\n'
                    '• ألعاب تفاعلية (مسابقات، ألغاز، ذاكرة)\n'
                    '• أسئلة وجواب من موسوعة المسابقات الإسلامية\n'
                    '• جميع المحتوى يعمل دون إنترنت',
              ),
              const SizedBox(height: 16),
              const _AboutSection(
                title: 'لمن هذا التطبيق؟',
                body:
                    'يُستخدم من قبل معلمي ومعلمات حلقات تحفيظ القرآن الكريم '
                    'في المساجد والمدارس والبيوت. صُمم ليكون بسيطًا وسهل الاستخدام '
                    'ويتناسب مع جميع الأعمار.',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.chat_rounded,
                      label: 'تواصل عبر واتساب',
                      color: const Color(0xFF25D366),
                      onTap: () async {
                        final url = Uri.parse(
                            'https://wa.me/$_whatsappNumber');
                        if (await url_launcher.canLaunchUrl(url)) {
                          await url_launcher.launchUrl(url,
                              mode: url_launcher
                                  .LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.share_rounded,
                      label: 'شارك التطبيق',
                      color: AppColors.blue,
                      onTap: () async {
                        await Share.share(
                            'فسحة الحفّاظ - مكتبة الأنشطة التربوية\n\n$_appUrl');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.7,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// عنصر تبديل الصوت في القائمة الجانبية.
class _AudioToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: audio.isLoading ? null : () => audio.toggle(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (audio.isPlaying
                            ? AppColors.primary
                            : AppColors.textSecondary)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    audio.isPlaying
                        ? Icons.music_note_rounded
                        : Icons.music_off_rounded,
                    size: 22,
                    color: audio.isPlaying
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audio.isPlaying ? 'إيقاف الصوت' : 'تشغيل الصوت',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        audio.isPlaying
                            ? 'الصوت يعمل الآن'
                            : 'اضغط لتشغيل الصوت',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  audio.isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  size: 28,
                  color: audio.isPlaying
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
