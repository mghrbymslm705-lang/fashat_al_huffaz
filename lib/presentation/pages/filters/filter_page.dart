import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/enums/location_type.dart';
import '../../../core/enums/movement_level.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/activity_filter.dart';
import '../../../domain/entities/range_value.dart';
import '../../providers/activity_provider.dart';
import '../../widgets/section_header.dart';

/// صفحة الفلاتر الذكية.
///
/// يختار المستخدم معايير متعددة ثم يضغط "تطبيق" لتظهر
/// الأنشطة المناسبة فقط (بحث داخل قاعدة البيانات المحلية).
class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late ActivityFilter _filter;
  late RangeValues _ageValues;
  late RangeValues _participantsValues;
  late RangeValues _durationValues;

  @override
  void initState() {
    super.initState();
    final current = context.read<ActivityProvider>().activeFilter;
    _filter = current;

    _ageValues = _toValues(current.age, 0, 20);
    _participantsValues = _toValues(current.participants, 1, 60);
    _durationValues = _toValues(current.duration, 1, 60);
  }

  static RangeValues _toValues(RangeValue range, int min, int max) {
    final start = range.isValid && range.min > 0 ? range.min.clamp(min, max) : min;
    final end = range.isValid && range.max > 0 ? range.max.clamp(start, max) : max;
    return RangeValues(start.toDouble(), end.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('الفلاتر الذكية')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const SectionHeader(title: 'الأقسام', subtitle: 'اختر قسمًا أو أكثر'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.categories.map((category) {
              final selected = _filter.categoryIds.contains(category.id);
              return FilterChip(
                label: Text(category.name),
                selected: selected,
                onSelected: (value) => setState(() {
                  final ids = List<String>.of(_filter.categoryIds);
                  value ? ids.add(category.id) : ids.remove(category.id);
                  _filter = _filter.copyWith(categoryIds: ids);
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'مكان التنفيذ'),
          const SizedBox(height: 8),
          _LocationSelector(
            value: _filter.location,
            onChanged: (v) =>
                setState(() => _filter = _filter.copyWith(location: v)),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'مستوى الحركة'),
          const SizedBox(height: 8),
          _MovementSelector(
            value: _filter.movement,
            onChanged: (v) =>
                setState(() => _filter = _filter.copyWith(movement: v)),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'الأدوات'),
          const SizedBox(height: 8),
          _ToolsSelector(
            value: _filter.hasTools,
            onChanged: (v) =>
                setState(() => _filter = _filter.copyWith(hasTools: v)),
          ),
          const SizedBox(height: 20),
          _RangeSliderTile(
            title: 'العمر المناسب (سنة)',
            values: _ageValues,
            min: 0,
            max: 20,
            onChanged: (v) => setState(() => _ageValues = v),
          ),
          const SizedBox(height: 12),
          _RangeSliderTile(
            title: 'عدد المشاركين',
            values: _participantsValues,
            min: 1,
            max: 60,
            onChanged: (v) => setState(() => _participantsValues = v),
          ),
          const SizedBox(height: 12),
          _RangeSliderTile(
            title: 'المدة (دقيقة)',
            values: _durationValues,
            min: 1,
            max: 60,
            onChanged: (v) => setState(() => _durationValues = v),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _filter = const ActivityFilter();
                      _ageValues = const RangeValues(0, 20);
                      _participantsValues = const RangeValues(1, 60);
                      _durationValues = const RangeValues(1, 60);
                    });
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('مسح الكل'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _apply,
                  icon: const Icon(Icons.filter_alt_rounded),
                  label: Text(
                    'تطبيق (${_countCriteria()} شرط)',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _countCriteria() {
    var count = _filter.categoryIds.isNotEmpty ? 1 : 0;
    if (_filter.location != LocationType.any) count++;
    if (_filter.movement != MovementLevel.any) count++;
    if (_filter.hasTools != null) count++;
    if (_ageValues.start > 0 || _ageValues.end < 20) count++;
    if (_participantsValues.start > 1 || _participantsValues.end < 60) count++;
    if (_durationValues.start > 1 || _durationValues.end < 60) count++;
    return count;
  }

  void _apply() {
    final filter = ActivityFilter(
      categoryIds: _filter.categoryIds,
      location: _filter.location,
      movement: _filter.movement,
      hasTools: _filter.hasTools,
      age: RangeValue(_ageValues.start.round(), _ageValues.end.round()),
      participants: RangeValue(
        _participantsValues.start.round(),
        _participantsValues.end.round(),
      ),
      duration: RangeValue(
        _durationValues.start.round(),
        _durationValues.end.round(),
      ),
      type: _filter.type,
    );

    context.read<ActivityProvider>().setFilter(filter);
    Navigator.of(context).pop();
  }
}

/// محدد مكان التنفيذ.
class _LocationSelector extends StatelessWidget {
  const _LocationSelector({required this.value, required this.onChanged});

  final LocationType value;
  final ValueChanged<LocationType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<LocationType>(
      segments: const [
        ButtonSegment(value: LocationType.any, label: Text('لا يهم')),
        ButtonSegment(value: LocationType.inside, label: Text('داخل')),
        ButtonSegment(value: LocationType.outside, label: Text('خارج')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// محدد مستوى الحركة.
class _MovementSelector extends StatelessWidget {
  const _MovementSelector({required this.value, required this.onChanged});

  final MovementLevel value;
  final ValueChanged<MovementLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MovementLevel>(
      segments: const [
        ButtonSegment(value: MovementLevel.any, label: Text('لا يهم')),
        ButtonSegment(value: MovementLevel.quiet, label: Text('هادئة')),
        ButtonSegment(value: MovementLevel.active, label: Text('حركية')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// محدد توفر الأدوات.
class _ToolsSelector extends StatelessWidget {
  const _ToolsSelector({required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool?>(
      segments: const [
        ButtonSegment(value: null, label: Text('لا يهم')),
        ButtonSegment(value: false, label: Text('بدون أدوات')),
        ButtonSegment(value: true, label: Text('بأدوات')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// شريط نطاق مع عنوان وقيم ظاهرة.
class _RangeSliderTile extends StatelessWidget {
  const _RangeSliderTile({
    required this.title,
    required this.values,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final RangeValues values;
  final int min;
  final int max;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Text(
                '${values.start.round()} - ${values.end.round()}',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: values,
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            labels: RangeLabels(
              '${values.start.round()}',
              '${values.end.round()}',
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
