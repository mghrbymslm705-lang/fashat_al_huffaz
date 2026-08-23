import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/fs/fs.dart' as fs;
import '../../providers/activity_provider.dart';
import '../../providers/settings_provider.dart';
import '../import/import_page.dart';
import 'about_page.dart';
import 'contact_page.dart';
import 'privacy_page.dart';

/// صفحة الإعدادات.
///
/// منظمة في ثلاثة أقسام: المظهر (الوضع الليلي + حجم الخط)،
/// المحتوى (استيراد الملفات)، معلومات التطبيق (الخصوصية/حول/تواصل).
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.onOpenLibrary});

  /// يُمرَّر إلى صفحة الاستيراد لزر "عرض المكتبة".
  final VoidCallback? onOpenLibrary;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _importing = false;
  String? _importMessage;
  bool _importError = false;

  /// اختيار ملف واستيراده مباشرة مع إظهار النتيجة (نجاح/خطأ).
  Future<void> _importFile() async {
    if (_importing) return;
    setState(() {
      _importing = true;
      _importMessage = null;
    });

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'doc', 'docx', 'txt'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) {
        if (mounted) setState(() => _importing = false);
        return;
      }

      final file = picked.files.single;
      List<int>? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await fs.readBytes(file.path!);
      }
      if (bytes == null) {
        if (mounted) {
          setState(() {
            _importing = false;
            _importMessage = 'لا يمكن الوصول لمحتوى الملف على هذا الجهاز.';
            _importError = true;
          });
        }
        return;
      }

      if (!mounted) return;
      final provider = context.read<ActivityProvider>();
      final name = file.name.toLowerCase();
      final isWord = name.endsWith('.doc') ||
          name.endsWith('.docx') ||
          name.endsWith('.txt');

      final ImportResultView view;
      if (isWord) {
        view = ImportResultView.from(await provider.importWordBytes(file.name, bytes));
      } else {
        view = ImportResultView.from(await provider.importBytes(file.name, bytes));
      }

      if (!mounted) return;
      setState(() {
        _importing = false;
        _importMessage = view.message;
        _importError = view.isError;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _importing = false;
          _importMessage = 'تعذر استيراد الملف. تأكد أنه ملف JSON صالح.';
          _importError = true;
        });
      }
    }
  }

  void _openImportPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImportPage(onViewLibrary: widget.onOpenLibrary),
      ),
    );
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              children: [
                // ---------------- المظهر ----------------
                const _SectionTitle('المظهر'),
                const SizedBox(height: 8),
                _GroupCard(
                  children: [
                    _buildThemeRow(settings),
                    const _GroupDivider(),
                    _buildFontRow(settings),
                  ],
                ),
                const SizedBox(height: 20),

                // ---------------- المحتوى ----------------
                const _SectionTitle('المحتوى'),
                const SizedBox(height: 8),
                _buildImportSection(),
                const SizedBox(height: 20),

                // ---------------- معلومات التطبيق ----------------
                const _SectionTitle('معلومات التطبيق'),
                const SizedBox(height: 8),
                _GroupCard(
                  children: [
                    _InfoTile(
                      icon: Icons.privacy_tip_rounded,
                      color: AppColors.purple,
                      title: 'سياسة الخصوصية',
                      onTap: () => _open(const PrivacyPage()),
                    ),
                    const _GroupDivider(),
                    _InfoTile(
                      icon: Icons.info_rounded,
                      color: AppColors.teal,
                      title: 'حول التطبيق',
                      onTap: () => _open(const AboutPage()),
                    ),
                    const _GroupDivider(),
                    _InfoTile(
                      icon: Icons.mail_rounded,
                      color: AppColors.orange,
                      title: 'تواصل معنا',
                      onTap: () => _open(const ContactPage()),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    '${AppConstants.appName} — الإصدار ${AppConstants.appVersion}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// صف إعداد الوضع الليلي مع مفتاح منزلق مدمج.
  Widget _buildThemeRow(SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _RowIcon(
                icon: Icons.brightness_6_rounded,
                color: AppColors.blue,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'الوضع الليلي',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              Text(
                settings.themeMode == ThemeMode.dark
                    ? 'ليلي'
                    : settings.themeMode == ThemeMode.light
                        ? 'نهاري'
                        : 'نظام',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Segmented<ThemeMode>(
            options: const [
              _SegmentOption(ThemeMode.system, 'نظام'),
              _SegmentOption(ThemeMode.light, 'نهاري'),
              _SegmentOption(ThemeMode.dark, 'ليلي'),
            ],
            selected: settings.themeMode,
            onChanged: settings.setThemeMode,
          ),
        ],
      ),
    );
  }

  /// صف إعداد حجم الخط مع معاينة فورية ومفتاح منزلق مدمج.
  Widget _buildFontRow(SettingsProvider settings) {
    final scale = settings.fontScale;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _RowIcon(
                icon: Icons.text_fields_rounded,
                color: AppColors.purple,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'حجم الخط',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              Text(
                settings.fontScaleLabel,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // معاينة فورية لأثر حجم الخط المختار.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '﴿وَقُلْ رَبِّ زِدْنِي عِلْمًا﴾',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12 * scale,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Segmented<double>(
            options: [
              for (final value in SettingsProvider.fontScaleOptions)
                _SegmentOption(value, SettingsProvider.fontScaleLabels[value]!),
            ],
            selected: settings.fontScale,
            onChanged: settings.setFontScale,
          ),
        ],
      ),
    );
  }

  /// بطاقة استيراد المحتوى: إجراء مستقل بزر واضح ورسالة نجاح/خطأ.
  Widget _buildImportSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _RowIcon(
                icon: Icons.upload_file_rounded,
                color: AppColors.primary,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'استيراد المحتوى',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'إضافة ملفات JSON جديدة إلى مكتبتك',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(44, 48)),
              onPressed: _importing ? null : _importFile,
              icon: _importing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(_importing ? 'جارٍ الاستيراد...' : 'استيراد ملف'),
            ),
          ),
          if (_importMessage != null) ...[
            const SizedBox(height: 10),
            _ImportStatus(message: _importMessage!, isError: _importError),
          ],
          const SizedBox(height: 6),
          // وصول إلى أدوات الاستيراد المتقدمة دون فقدان أي وظيفة.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InkWell(
              onTap: _openImportPage,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'الإدارة المتقدمة: مجلد الاستيراد، القالب، التنزيلات',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// عنوان قسم صغير ومدمج.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// بطاقة مجموعة بيضاء تحتوي صفوفًا مفصولة بخطوط رفيعة.
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// فاصل رفيع بين صفوف المجموعة.
class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
    );
  }
}

/// أيقونة صغيرة داخل صف إعداد.
class _RowIcon extends StatelessWidget {
  const _RowIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }
}

/// خيار داخل المفتاح المنزلق المدمج.
class _SegmentOption<T> {
  const _SegmentOption(this.value, this.label);

  final T value;
  final String label;
}

/// مفتاح منزلق مدمج (Segmented Control) متوافق مع RTL ومضغوط.
class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<_SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A3340) : AppColors.divider.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(child: _buildSegment(context, option)),
        ],
      ),
    );
  }

  Widget _buildSegment(BuildContext context, _SegmentOption<T> option) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = option.value == selected;
    final fg = isDark ? Colors.white70 : AppColors.textSecondary;

    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => onChanged(option.value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// عنصر بسيط في قسم معلومات التطبيق.
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      leading: _RowIcon(icon: icon, color: color),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: const Icon(
        Icons.chevron_left_rounded,
        size: 20,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}

/// رسالة نتيجة الاستيراد (نجاح أو خطأ) بشكل مضغوط.
class _ImportStatus extends StatelessWidget {
  const _ImportStatus({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.redAccent : AppColors.primaryDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
