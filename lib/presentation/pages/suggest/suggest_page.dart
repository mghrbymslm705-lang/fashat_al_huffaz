import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/enums/location_type.dart';
import '../../../core/enums/suggest_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/activity_filter.dart';
import '../../../domain/entities/range_value.dart';
import '../../../domain/entities/suggestion.dart';
import '../../providers/activity_provider.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/empty_state.dart';
import '../details/activity_detail_page.dart';

/// المساعد الذكي "اقترح لي نشاطًا".
///
/// يطرح 6 أسئلة على المستخدم، ثم يبحث داخل قاعدة البيانات المحلية فقط
/// ويعرض الأنشطة الأنسب مرتبة. لا ينتج التطبيق أي نشاط من تلقاء نفسه.
class SuggestPage extends StatefulWidget {
  const SuggestPage({super.key});

  @override
  State<SuggestPage> createState() => _SuggestPageState();
}

/// سؤال من أسئلة المساعد.
class _Question {
  const _Question({
    required this.text,
    required this.helper,
    required this.icon,
    required this.choices,
  });

  final String text;
  final String helper;
  final IconData icon;
  final List<_Choice> choices;
}

/// خيار واحد داخل سؤال.
class _Choice {
  const _Choice(this.label, this.value, {this.icon});

  final String label;
  final dynamic value;
  final IconData? icon;
}

class _SuggestPageState extends State<SuggestPage> {
  static const int _totalSteps = AppConstants.suggestSteps;

  late final List<_Question> _questions = _buildQuestions();

  /// إجابات المستخدم (خام لكل خطوة).
  final List<dynamic> _answers = List<dynamic>.filled(_totalSteps, null);

  /// الخطوات التي أجاب عنها المستخدم فعليًا (لتمييز اختيار "لا يهم" = null).
  final Set<int> _answeredSteps = {};

  int _step = 0;
  bool _finished = false;

  static List<_Question> _buildQuestions() {
    return const [
      _Question(
        text: 'كم عدد الطلاب في الحلقة؟',
        helper: 'اختر أقرب نطاق لعدد طلابك',
        icon: Icons.people_rounded,
        choices: [
          _Choice('أقل من 5', RangeValue(1, 4), icon: Icons.filter_1_rounded),
          _Choice('5 - 10', RangeValue(5, 10), icon: Icons.filter_2_rounded),
          _Choice('10 - 20', RangeValue(10, 20), icon: Icons.filter_3_rounded),
          _Choice('أكثر من 20', RangeValue(20, 60), icon: Icons.groups_rounded),
        ],
      ),
      _Question(
        text: 'ما أعمار الطلاب؟',
        helper: 'اختر الفئة العمرية المناسبة',
        icon: Icons.child_care_rounded,
        choices: [
          _Choice('6 - 8 سنوات', RangeValue(6, 8), icon: Icons.child_care_rounded),
          _Choice('9 - 12 سنة', RangeValue(9, 12), icon: Icons.school_rounded),
          _Choice('13 - 15 سنة', RangeValue(13, 15), icon: Icons.school_rounded),
          _Choice('16 سنة فأكثر', RangeValue(16, 20), icon: Icons.diversity_3_rounded),
          _Choice('أعمار متنوعة', RangeValue(6, 18), icon: Icons.shuffle_rounded),
        ],
      ),
      _Question(
        text: 'كم دقيقة لديك؟',
        helper: 'المدة المتاحة لتنفيذ النشاط',
        icon: Icons.timer_rounded,
        choices: [
          _Choice('10 دقائق', RangeValue(10, 10), icon: Icons.timer_rounded),
          _Choice('15 دقيقة', RangeValue(15, 15)),
          _Choice('20 دقيقة', RangeValue(20, 20)),
          _Choice('30 دقيقة', RangeValue(30, 30)),
          _Choice('أكثر من 30', RangeValue(30, 45)),
        ],
      ),
      _Question(
        text: 'داخل القاعة أم خارجها؟',
        helper: 'مكان تنفيذ النشاط',
        icon: Icons.place_rounded,
        choices: [
          _Choice('داخل القاعة', LocationType.inside, icon: Icons.meeting_room_rounded),
          _Choice('خارج القاعة', LocationType.outside, icon: Icons.park_rounded),
          _Choice('لا يهم', LocationType.any, icon: Icons.public_rounded),
        ],
      ),
      _Question(
        text: 'هل تتوفر أدوات لديك؟',
        helper: 'مثل سبورة، كرات، ورق، مقص...',
        icon: Icons.handyman_rounded,
        choices: [
          _Choice('بدون أدوات', false, icon: Icons.block_rounded),
          _Choice('الأدوات متوفرة', true, icon: Icons.handyman_rounded),
          _Choice('لا يهم', null, icon: Icons.shuffle_rounded),
        ],
      ),
      _Question(
        text: 'ما نوع النشاط المطلوب؟',
        helper: 'حدد طبيعة النشاط أو اختر "لا يهم"',
        icon: Icons.emoji_events_rounded,
        choices: [
          _Choice('قرآني', SuggestType.quranic, icon: Icons.menu_book_rounded),
          _Choice('حركي', SuggestType.kinetic, icon: Icons.directions_run_rounded),
          _Choice('ثقافي', SuggestType.cultural, icon: Icons.emoji_events_rounded),
          _Choice('ترفيهي', SuggestType.entertainment, icon: Icons.celebration_rounded),
          _Choice('جماعي', SuggestType.group, icon: Icons.groups_rounded),
          _Choice('لا يهم', SuggestType.any, icon: Icons.shuffle_rounded),
        ],
      ),
    ];
  }

  bool get _hasAnsweredStep =>
      _answers[_step] != null || _answeredSteps.contains(_step);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اقترح لي نشاطًا 🎲'),
        actions: [
          if (_finished)
            TextButton.icon(
              onPressed: () => setState(() => _finished = false),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('تعديل الإجابات'),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _finished ? _buildResults() : _buildQuestion(),
          ),
        ),
      ),
    );
  }

  // -------------------- شاشة الأسئلة --------------------

  Widget _buildQuestion() {
    final question = _questions[_step];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'أجب عن $_totalSteps أسئلة قصيرة وسنرشّح لك أنسب نشاط من مكتبتك المحلية.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildProgress(),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _QuestionCard(question: question),
              const SizedBox(height: 12),
              ...question.choices.map((choice) {
                final selected = _answeredSteps.contains(_step) &&
                    _answers[_step] == choice.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AnswerTile(
                    choice: choice,
                    selected: selected,
                    onTap: () => setState(() {
                      _answers[_step] = choice.value;
                      _answeredSteps.add(_step);
                    }),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildNavButtons(),
      ],
    );
  }

  Widget _buildProgress() {
    final current = _step + 1;
    // قسمة صحيحة: 16% ثم 33% ... حتى 100%.
    final percent = current * 100 ~/ _totalSteps;

    return Column(
      children: [
        Row(
          children: [
            // عداد السؤال بتنسيق آمن للاتجاه (يمين→يسار): السؤال 1 من 6.
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'السؤال',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$current',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'من',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '$_totalSteps',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // شريط التقدم: يمتد من اليمين إلى اليسار (RTL).
        Transform.flip(
          flipX: true,
          child: LinearProgressIndicator(
            value: current / _totalSteps,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            color: AppColors.primary,
            backgroundColor: Colors.grey.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }

  Widget _buildNavButtons() {
    final isLast = _step == _totalSteps - 1;

    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _step--),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('السابق'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          )
        else
          const Spacer(),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _hasAnsweredStep ? _next : null,
            icon: isLast
                ? const Icon(Icons.casino_rounded)
                : const Icon(Icons.arrow_back_rounded),
            label: Text(isLast ? 'عرض النشاط المقترح' : 'التالي'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      return;
    }
    _runSuggestion();
  }

  void _runSuggestion() {
    final filter = ActivityFilter(
      participants: _answers[0] as RangeValue,
      age: _answers[1] as RangeValue,
      duration: _answers[2] as RangeValue,
      location: _answers[3] as LocationType,
      hasTools: _answers[4] as bool?,
      type: _answers[5] as SuggestType,
    );
    context.read<ActivityProvider>().runSuggest(filter);
    setState(() => _finished = true);
  }

  void _restart() {
    setState(() {
      _step = 0;
      _finished = false;
      for (var i = 0; i < _answers.length; i++) {
        _answers[i] = null;
      }
      _answeredSteps.clear();
    });
  }

  // -------------------- شاشة النتائج --------------------

  Widget _buildResults() {
    final provider = context.watch<ActivityProvider>();
    final suggestions = provider.suggestions;
    final top = suggestions.isNotEmpty ? suggestions.first : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _ResultsHeader(suggestionsCount: suggestions.length),
        const SizedBox(height: 16),
        if (suggestions.isEmpty)
          const _NoMatchCard()
        else ...[
          if (top != null) ...[
            _SuggestionCard(suggestion: top),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ActivityDetailPage(activity: top.activity),
                ),
              ),
              icon: const Icon(Icons.info_outline_rounded),
              label: const Text('عرض تفاصيل النشاط'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
          if (suggestions.length > 1) ...[
            const SizedBox(height: 18),
            const Text(
              'نتائج أخرى قد تناسبك',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 10),
            ...suggestions.skip(1).map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _SuggestionCard(suggestion: s),
                  ),
                ),
          ],
        ],
        const SizedBox(height: 18),
        Center(
          child: OutlinedButton.icon(
            onPressed: _restart,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('إعادة الاختبار'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

/// بطاقة السؤال بتصميم مدمج (أصغر من السابق).
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final _Question question;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(question.icon, size: 22, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            question.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              height: 1.3,
            ),
          ),
          if (question.helper.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              question.helper,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// خيار إجابة قابل للضغط (بطاقة راديو مدمجة مع علامة ✓).
class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _Choice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.09)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _RadioDot(selected: selected),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  choice.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: selected
                        ? AppColors.primaryDark
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('check'),
                        color: AppColors.primary,
                        size: 20,
                      )
                    : const SizedBox(key: ValueKey('none'), width: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// دائرة راديو صغيرة تمتلئ باللون الأخضر عند الاختيار.
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: selected
              ? AppColors.primary
              : Theme.of(context).colorScheme.outline,
          width: 1.6,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

/// رأس شاشة النتائج: تدرج أخضر مع أيقونة الاحتفال والرسالة.
class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.suggestionsCount});

  final int suggestionsCount;

  @override
  Widget build(BuildContext context) {
    final countText = suggestionsCount == 0
        ? 'جرّب تعديل إجاباتك لتحصل على نتائج أفضل'
        : suggestionsCount == 1
            ? 'نشاط مناسب لمعطياتك من مكتبتك المحلية'
            : 'أفضل $suggestionsCount نشاط مناسب لمعطياتك من مكتبتك المحلية';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.celebration_rounded, color: Colors.white, size: 34),
          const SizedBox(height: 10),
          const Text(
            '🎉 وجدنا لك نشاطًا مناسبًا',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            countText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة نتيجة الاقتراح: أسباب + بطاقة النشاط.
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion});

  final Suggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (suggestion.reasons.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'لماذا يناسبك؟',
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: suggestion.reasons
                      .map((r) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              r,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ActivityCard(activity: suggestion.activity),
      ],
    );
  }
}

/// بطاقة "لا يوجد نشاط مطابق" (الرسالة الإلزامية).
class _NoMatchCard extends StatelessWidget {
  const _NoMatchCard();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.search_off_rounded,
      title: 'لا توجد نتائج',
      message: AppConstants.noActivityMatchMessage,
    );
  }
}
