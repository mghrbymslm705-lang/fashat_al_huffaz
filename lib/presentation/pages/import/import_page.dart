import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/file_downloader.dart';
import '../../../data/datasources/fs/fs.dart' as fs;
import '../../../domain/repositories/activity_repository.dart';
import '../../providers/activity_provider.dart';

/// صفحة إدارة واستيراد المحتوى.
///
/// وفق سياسة إدارة المحتوى، المصدر الوحيد للأنشطة هو ملفات JSON (أو وورد
/// يُستخرج منه المحتوى). قبل أي استيراد تُعرض معاينة بأرقام حقيقية من الملف،
/// ولا تُعدَّل المكتبة إلا بعد تأكيد المستخدم.
class ImportPage extends StatefulWidget {
  const ImportPage({super.key, this.onViewLibrary});

  /// يُستدعى عند ضغط "عرض المكتبة" للانتقال إلى تبويب المكتبة (الرئيسية).
  /// إن كان فارغًا يُخفى الزر (لا يُنشأ زر وهمي).
  final VoidCallback? onViewLibrary;

  @override
  State<ImportPage> createState() => _ImportPageState();
}

/// مصدر الاستيراد الحالي.
enum _ImportSource { none, json, word, folder }

/// مراحل سير الاستيراد (تظهر للمستخدم بأسماء فعلية).
enum _ImportStage { idle, analyzing, classifying, saving, done, error }

class _ImportPageState extends State<ImportPage> {
  bool _busy = false;

  /// المرحلة الحالية من سير الاستيراد.
  _ImportStage _stage = _ImportStage.idle;

  /// مصدر الاستيراد الحالي.
  _ImportSource _source = _ImportSource.none;

  /// معاينة المصدر بأرقام حقيقية (قبل تأكيد الاستيراد).
  ImportPreview? _preview;

  /// اسم الملف المختار (بانتظار التأكيد أو أثناء الحفظ).
  String? _pendingFileName;

  /// بايتات الملف المختار (بانتظار التأكيد أو أثناء الحفظ).
  Uint8List? _pendingBytes;

  String? _importPath;
  ImportResultView? _result;

  /// ملفات الأنشطة الأصلية (اسم الملف ← المحتوى) للتنزيل.
  Map<String, String> _sourceFiles = {};

  /// محتوى قالب النشاط للتنزيل.
  String? _templateContent;

  @override
  void initState() {
    super.initState();
    _loadPath();
    _loadSourceFiles();
  }

  Future<void> _loadSourceFiles() async {
    final provider = context.read<ActivityProvider>();
    String? template;
    try {
      template = await provider.readTemplate();
    } catch (_) {}
    try {
      final files = await provider.loadActivitySourceFiles();
      if (mounted) {
        setState(() {
          _sourceFiles = files;
          _templateContent = template;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _templateContent = template);
    }
  }

  void _downloadAllFiles() {
    for (final entry in _sourceFiles.entries) {
      downloadTextFile(entry.key, entry.value);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تنزيل ${_sourceFiles.length} ملفًا من ملفات الألعاب')),
    );
  }

  void _downloadTemplate() {
    final content = _templateContent;
    if (content == null) return;
    downloadTextFile('template.json', content);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تنزيل قالب النشاط (template.json)')),
    );
  }

  Future<void> _loadPath() async {
    final provider = context.read<ActivityProvider>();
    try {
      final path = await provider.importFolderPath;
      if (mounted) setState(() => _importPath = path);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _importPath = 'غير متاح على نسخة الويب — اختر ملف JSON مباشرة.');
      }
    }
  }

  // -------------------- الاستيراد: اختيار → معاينة → تأكيد --------------------

  Future<void> _pickFile() async {
    if (_busy) return;
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'doc', 'docx', 'txt'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;

      List<int> bytes;
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await _readPathBytes(file.path!);
      } else {
        _showResult(const ImportResultView(
          message: 'لا يمكن الوصول لمحتوى الملف على هذا الجهاز.',
          isError: true,
        ));
        return;
      }

      await _previewSource(
        source: _isWordFile(file.name)
            ? _ImportSource.word
            : _ImportSource.json,
        fileName: file.name,
        bytes: bytes,
      );
    } catch (_) {
      _showResult(const ImportResultView(
        message: 'حدث خطأ أثناء قراءة الملف.',
        isError: true,
      ));
    }
  }

  bool _isWordFile(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.doc') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.txt');
  }

  /// قراءة بايتات ملف عبر مسار (للمنصات الأصلية).
  Future<List<int>> _readPathBytes(String path) => fs.readBytes(path);

  /// تحليل مصدر دون استيراده ثم عرض المعاينة.
  Future<void> _previewSource({
    required _ImportSource source,
    required String fileName,
    required List<int> bytes,
  }) async {
    final provider = context.read<ActivityProvider>();
    setState(() {
      _busy = true;
      _result = null;
      _preview = null;
      _stage = _ImportStage.analyzing;
      _source = source;
      _pendingFileName = fileName;
      _pendingBytes = Uint8List.fromList(bytes);
    });

    ImportPreview preview;
    try {
      preview = source == _ImportSource.word
          ? await provider.previewWordBytes(fileName, bytes)
          : await provider.previewJsonBytes(fileName, bytes);
    } catch (_) {
      preview = const ImportPreview(error: 'تعذر تحليل الملف.');
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _preview = preview;
      _stage = preview.hasError ? _ImportStage.error : _ImportStage.idle;
      if (preview.hasError) {
        _result = ImportResultView(message: preview.error!, isError: true);
      }
    });
  }

  Future<void> _importFromFolder() async {
    if (_busy) return;
    if (kIsWeb) {
      _showResult(const ImportResultView(
        message: 'استيراد مجلد الاستيراد متاح على أجهزة الجوال فقط. '
            'على الويب اختر ملف JSON مباشرة.',
        isError: false,
      ));
      return;
    }
    final provider = context.read<ActivityProvider>();
    setState(() {
      _busy = true;
      _result = null;
      _preview = null;
      _stage = _ImportStage.analyzing;
      _source = _ImportSource.folder;
    });

    ImportPreview preview;
    try {
      preview = await provider.previewFromDocuments();
    } catch (_) {
      preview = const ImportPreview(error: 'تعذر فحص مجلد الاستيراد.');
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _preview = preview;
      _stage = preview.hasError ? _ImportStage.error : _ImportStage.idle;
      if (preview.hasError) {
        _result = ImportResultView(message: preview.error!, isError: true);
      }
    });
  }

  /// تأكيد استيراد المصدر المُعايَن — هنا فقط تُعدَّل المكتبة.
  Future<void> _confirmImport() async {
    final source = _source;
    final fileName = _pendingFileName;
    final bytes = _pendingBytes;
    if (source == _ImportSource.none) return;

    setState(() {
      _busy = true;
      _preview = null;
      _result = null;
      _stage = source == _ImportSource.word
          ? _ImportStage.classifying
          : _ImportStage.saving;
    });

    final provider = context.read<ActivityProvider>();
    ImportResultView view;
    try {
      if (source == _ImportSource.folder) {
        view = ImportResultView.from(await provider.importFromDocuments());
      } else if (source == _ImportSource.word) {
        view = ImportResultView.from(
          await provider.importWordBytes(fileName!, bytes!),
        );
      } else {
        view = ImportResultView.from(
          await provider.importBytes(fileName!, bytes!),
        );
      }
    } catch (_) {
      view = const ImportResultView(message: 'تعذر حفظ الأنشطة.', isError: true);
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = view;
      _stage = view.isError ? _ImportStage.error : _ImportStage.done;
      _preview = null;
      _pendingBytes = null;
      _pendingFileName = null;
      _source = _ImportSource.none;
    });
  }

  void _cancelPreview() {
    setState(() {
      _preview = null;
      _result = null;
      _pendingBytes = null;
      _pendingFileName = null;
      _source = _ImportSource.none;
      _stage = _ImportStage.idle;
    });
  }

  void _showResult(ImportResultView view) {
    setState(() {
      _result = view;
      _stage = view.isError ? _ImportStage.error : _ImportStage.idle;
    });
  }

  Future<void> _exportTemplate() async {
    if (_busy) return;
    final provider = context.read<ActivityProvider>();
    ImportResultView view;
    if (kIsWeb) {
      view = const ImportResultView(
        message: 'تصدير القالب إلى مجلد المستندات متاح على الجوال فقط. '
            'على الويب استخدم "تنزيل قالب النشاط" أدناه.',
        isError: false,
      );
    } else {
      try {
        final path = await provider.exportTemplate();
        view = ImportResultView(
          message: 'تم تصدير القالب إلى:\n$path',
          isError: false,
        );
      } catch (_) {
        view = const ImportResultView(
          message: 'تعذر تصدير القالب.',
          isError: true,
        );
      }
    }
    if (mounted) _showResult(view);
  }

  void _openLibrary() {
    widget.onViewLibrary?.call();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // -------------------- الواجهة --------------------

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة واستيراد المحتوى')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              children: [
                const _Description(),
                const SizedBox(height: 14),
                _StatsCard(provider: provider),
                if (widget.onViewLibrary != null) ...[
                  const SizedBox(height: 4),
                  _ViewLibraryButton(onTap: _openLibrary),
                ],
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return _buildImportCards(wide: constraints.maxWidth >= 460);
                  },
                ),
                if (_buildActivityArea().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ..._buildActivityArea(),
                ],
                const SizedBox(height: 14),
                _buildAdvancedTools(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بطاقتا الاستيراد (ملف / مجلد): جنبًا إلى جنب على الشاشات الواسعة
  /// بارتفاع متساوٍ، وتتكدّسان عموديًا على الشاشات الضيقة.
  Widget _buildImportCards({required bool wide}) {
    final fileCard = _ImportCard(
      icon: Icons.upload_file_rounded,
      title: 'استيراد ملف',
      subtitle: 'ملف JSON أو وورد (doc / docx / txt) يُستخرج محتواه '
          'وتُصنَّف ألعابه تلقائيًا.',
      buttonLabel: 'اختيار ملف',
      buttonIcon: Icons.upload_file_rounded,
      accent: AppColors.primary,
      filled: true,
      onPressed: _busy ? null : _pickFile,
      note: 'معاينة دقيقة قبل الحفظ مع منع التكرار تلقائيًا.',
    );

    final folderCard = _ImportCard(
      icon: Icons.folder_open_rounded,
      title: 'استيراد من المجلد',
      subtitle: kIsWeb
          ? 'متاح على أجهزة الجوال. على الويب اختر ملفًا مباشرة.'
          : 'يستورد كل ملفات JSON الموضوعة في مجلد الاستيراد.',
      buttonLabel: 'استيراد المجلد',
      buttonIcon: Icons.folder_open_rounded,
      accent: AppColors.blue,
      filled: false,
      onPressed: _busy ? null : _importFromFolder,
      note: !kIsWeb && _importPath != null ? _importPath! : null,
    );

    if (!wide) {
      return Column(
        children: [
          fileCard,
          const SizedBox(height: 12),
          folderCard,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: fileCard),
          const SizedBox(width: 12),
          Expanded(child: folderCard),
        ],
      ),
    );
  }

  /// المنطقة النشطة: تقدم الاستيراد أو المعاينة أو النتيجة.
  List<Widget> _buildActivityArea() {
    if (_busy && _stage != _ImportStage.idle) {
      return [_StatusPanel(stage: _stage, source: _source)];
    }
    final preview = _preview;
    if (preview != null) {
      return [
        _PreviewPanel(
          preview: preview,
          onConfirm: _confirmImport,
          onCancel: _cancelPreview,
        ),
      ];
    }
    final result = _result;
    if (result != null) {
      return [_ResultCard(result: result)];
    }
    return const [];
  }

  /// قسم الأدوات المتقدمة أسفل الصفحة.
  Widget _buildAdvancedTools() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.build_rounded, color: AppColors.gold, size: 22),
        ),
        title: const Text(
          'أدوات متقدمة',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        subtitle: const Text(
          'تصدير القالب وتنزيل الملفات الأصلية',
          style: TextStyle(fontSize: 11),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        children: [
          _AdvancedTile(
            icon: Icons.article_rounded,
            color: AppColors.gold,
            title: 'تصدير قالب نشاط (template.json)',
            subtitle: 'نسخة من البنية المطلوبة تُكتب في مجلد المستندات (الجوال).',
            onTap: _busy ? null : _exportTemplate,
          ),
          const Divider(),
          _AdvancedTile(
            icon: Icons.file_download_rounded,
            color: AppColors.blue,
            title: 'تنزيل جميع ملفات الألعاب (${_sourceFiles.length})',
            subtitle: 'النسخ الأصلية من ملفات الأنشطة (JSON) لحفظها أو مشاركتها.',
            onTap: _sourceFiles.isEmpty ? null : _downloadAllFiles,
          ),
          const Divider(),
          _AdvancedTile(
            icon: Icons.description_rounded,
            color: AppColors.purple,
            title: 'تنزيل قالب النشاط (template.json)',
            subtitle: kIsWeb
                ? 'يُنزَّل كملف عبر المتصفح.'
                : 'يُنزَّل كملف إلى جهازك.',
            onTap: _templateContent == null ? null : _downloadTemplate,
          ),
        ],
      ),
    );
  }
}

/// وصف مختصر لأعلى الصفحة.
class _Description extends StatelessWidget {
  const _Description();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'أضف ملفات JSON أو وورد (doc / docx / txt) من جهازك إلى مكتبتك، '
      'مع معاينة دقيقة قبل الحفظ ومنع التكرار تلقائيًا.',
      style: TextStyle(fontSize: 12.5, height: 1.6, color: AppColors.textSecondary),
    );
  }
}

/// بطاقة إحصائية ديناميكية من البيانات الفعلية.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.provider});

  final ActivityProvider provider;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        icon: Icons.menu_book_rounded,
        value: provider.totalCount,
        label: 'نشاطًا في مكتبتك',
      ),
      (icon: Icons.folder_rounded, value: provider.categories.length, label: 'قسمًا'),
      (
        icon: Icons.favorite_rounded,
        value: provider.favoriteActivities.length,
        label: 'مفضلة',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(width: 1, height: 36, color: Colors.white24),
            Expanded(
              child: Column(
                children: [
                  Icon(stats[i].icon, color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    '${stats[i].value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    stats[i].label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// زر عرض المكتبة (يظهر فقط عندما تتوفر وظيفة الانتقال).
class _ViewLibraryButton extends StatelessWidget {
  const _ViewLibraryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
        onPressed: onTap,
        icon: const Icon(Icons.library_books_rounded,
            size: 18, color: AppColors.primaryDark),
        label: const Text(
          'عرض المكتبة',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// بطاقة استيراد (ملف أو مجلد).
class _ImportCard extends StatelessWidget {
  const _ImportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.accent,
    required this.onPressed,
    this.filled = true,
    this.note,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
  final Color accent;
  final VoidCallback? onPressed;
  final bool filled;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surface;

    final button = filled
        ? FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(44, 48)),
            onPressed: onPressed,
            icon: Icon(buttonIcon, size: 18),
            label: Text(buttonLabel),
          )
        : OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48)),
            onPressed: onPressed,
            icon: Icon(buttonIcon, size: 18),
            label: Text(buttonLabel),
          );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: button),
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(
              note!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                height: 1.4,
                color: AppColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// لوحة تقدم الاستيراد (مراحل فعلية بأسماء توضيحية).
class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.stage, required this.source});

  final _ImportStage stage;
  final _ImportSource source;

  String get _label {
    switch (stage) {
      case _ImportStage.analyzing:
        return 'جارٍ تحليل الملف واستخراج المحتوى...';
      case _ImportStage.classifying:
        return 'جارٍ تصنيف الأنشطة في أقسامها المناسبة...';
      case _ImportStage.saving:
        return 'جارٍ حفظ الأنشطة في مكتبتك...';
      default:
        return 'جارٍ المعالجة...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ImportSteps(stage: stage, source: source),
        ],
      ),
    );
  }
}

/// حالة خطوة من خطوات سير الاستيراد.
enum _StepState { waiting, active, done }

/// خطوات سير الاستيراد (تحليل → تصنيف → حفظ) مع تقدمها الفعلي.
class _ImportSteps extends StatelessWidget {
  const _ImportSteps({required this.stage, required this.source});

  final _ImportStage stage;
  final _ImportSource source;

  @override
  Widget build(BuildContext context) {
    final flow = source == _ImportSource.word
        ? const [
            (_ImportStage.analyzing, 'تحليل'),
            (_ImportStage.classifying, 'تصنيف'),
            (_ImportStage.saving, 'حفظ'),
          ]
        : const [
            (_ImportStage.analyzing, 'تحليل'),
            (_ImportStage.saving, 'حفظ'),
          ];

    final isEnd = stage == _ImportStage.done || stage == _ImportStage.error;
    final currentIndex =
        isEnd ? flow.length : flow.indexWhere((s) => s.$1 == stage);

    return Row(
      children: [
        for (var i = 0; i < flow.length; i++) ...[
          _StepChip(
            label: flow[i].$2,
            state: isEnd
                ? _StepState.done
                : i < currentIndex
                    ? _StepState.done
                    : i == currentIndex
                        ? _StepState.active
                        : _StepState.waiting,
          ),
          if (i < flow.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: isEnd || (i + 1) < currentIndex
                    ? AppColors.primary
                    : Colors.black.withValues(alpha: 0.12),
              ),
            ),
        ],
      ],
    );
  }
}

/// شريحة خطوة من خطوات الاستيراد.
class _StepChip extends StatelessWidget {
  const _StepChip({required this.label, required this.state});

  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Widget? icon;
    switch (state) {
      case _StepState.done:
        bg = AppColors.primary;
        fg = Colors.white;
        icon = const Icon(Icons.check_rounded, size: 13, color: Colors.white);
      case _StepState.active:
        bg = AppColors.primary.withValues(alpha: 0.14);
        fg = AppColors.primaryDark;
        icon = const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case _StepState.waiting:
        bg = Colors.black.withValues(alpha: 0.06);
        fg = AppColors.textSecondary;
        icon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon, const SizedBox(width: 5)],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// لوحة المعاينة قبل الاستيراد (أرقام حقيقية من الملف).
class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.preview,
    required this.onConfirm,
    required this.onCancel,
  });

  final ImportPreview preview;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isWord = preview.kind == ImportKind.word;
    final isFolder = preview.kind == ImportKind.folder;

    final description = isFolder
        ? 'فحص مجلد الاستيراد: وُجد ${preview.activityCount} نشاطًا.'
        : isWord
            ? 'استُخرج ${preview.activityCount} نشاطًا من الملف، وستُصنَّف '
                'كل لعبة في قسمها المناسب تلقائيًا.'
            : 'الملف يحتوي على ${preview.activityCount} نشاطًا قابلاً للقراءة.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.visibility_rounded,
                  color: AppColors.primaryDark, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'معاينة قبل الاستيراد',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(fontSize: 12.5, height: 1.6),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreviewChip(
                label: preview.newCount == 0
                    ? 'لا جديد'
                    : 'سيتُضاف ${preview.newCount}',
                color: AppColors.primary,
                icon: Icons.add_circle_outline_rounded,
              ),
              _PreviewChip(
                label: preview.updateCount == 0
                    ? 'لا تحديث'
                    : 'سيتحدّث ${preview.updateCount}',
                color: AppColors.blue,
                icon: Icons.update_rounded,
              ),
              _PreviewChip(
                label: preview.duplicateCount == 0
                    ? 'لا مكرر'
                    : 'مكرر ${preview.duplicateCount}',
                color: AppColors.textSecondary,
                icon: Icons.block_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(44, 48)),
                  onPressed: onConfirm,
                  icon: const Icon(Icons.download_done_rounded),
                  label: const Text('استيراد الآن'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48)),
                onPressed: onCancel,
                child: const Text('إلغاء'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'لن تُعدَّل مكتبتك إلا بعد تأكيد الاستيراد.',
            style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// شريحة إحصائية داخل لوحة المعاينة.
class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// عنصر ضمن قسم الأدوات المتقدمة.
class _AdvancedTile extends StatelessWidget {
  const _AdvancedTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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

/// نتيجة استيراد جاهزة للعرض (تبسيط لإخراج البيانات في الواجهة).
class ImportResultView {
  const ImportResultView({required this.message, required this.isError});

  final String message;
  final bool isError;

  static ImportResultView from(ImportResult result) {
    final lines = <String>[
      'تمت معالجة ${result.totalTouched} نشاطًا.',
      if (result.added > 0) 'أُضيف: ${result.added}',
      if (result.updated > 0) 'حُدّث: ${result.updated}',
      if (result.skipped > 0) 'مكرر/متجاهل: ${result.skipped}',
      if (result.errors > 0) 'أخطاء: ${result.errors}',
      ...result.messages,
    ];
    return ImportResultView(
      message: lines.join('\n'),
      isError: result.errors > 0,
    );
  }
}

/// بطاقة عرض النتيجة.
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final ImportResultView result;

  @override
  Widget build(BuildContext context) {
    final color = result.isError ? Colors.redAccent : AppColors.primaryDark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            result.isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
