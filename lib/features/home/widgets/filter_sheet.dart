import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../recommendation/models/meal_preference.dart';
import '../../restaurants/models/food_category.dart';

Future<void> showFilters(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  useSafeArea: true,
  builder: (_) => const FilterSheet(),
);

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});
  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late MealPreference _value;
  @override
  void initState() {
    super.initState();
    _value = ref.read(settingsProvider).preference;
  }

  void _update({
    bool clearBudget = false,
    double? distance,
    MealTime? meal,
    bool clearMeal = false,
    Companion? companion,
    bool clearCompanion = false,
  }) {
    setState(
      () => _value = MealPreference(
        budgetMin: clearBudget ? null : _value.budgetMin,
        budgetMax: clearBudget ? null : _value.budgetMax,
        maxDistance: distance ?? _value.maxDistance,
        mealTime: clearMeal ? null : meal ?? _value.mealTime,
        companion: clearCompanion ? null : companion ?? _value.companion,
        selectedCategories: _value.selectedCategories,
      ),
    );
  }

  Widget _group(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: children),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .9,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Bạn muốn ăn thế nào?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Đóng bộ lọc',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _group('Ngân sách / người', [
                  ChoiceChip(
                    label: const Text('Bất kỳ'),
                    selected:
                        _value.budgetMin == null && _value.budgetMax == null,
                    onSelected: (_) => _update(clearBudget: true),
                  ),
                  for (final b in budgets)
                    ChoiceChip(
                      label: Text(b.label),
                      selected:
                          _value.budgetMin == b.min &&
                          _value.budgetMax == b.max,
                      onSelected: (_) {
                        setState(
                          () => _value = MealPreference(
                            budgetMin: b.min,
                            budgetMax: b.max,
                            maxDistance: _value.maxDistance,
                            mealTime: _value.mealTime,
                            companion: _value.companion,
                            selectedCategories: _value.selectedCategories,
                          ),
                        );
                      },
                    ),
                ]),
                _group('Khoảng cách', [
                  for (final d in distanceOptions)
                    ChoiceChip(
                      label: Text('< ${d.toInt()} km'),
                      selected: _value.maxDistance == d,
                      onSelected: (_) => _update(distance: d),
                    ),
                ]),
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Cần vị trí GPS hoặc tâm khu vực để tính khoảng cách.',
                  ),
                ),
                _group('Bữa ăn', [
                  ChoiceChip(
                    label: const Text('Theo giờ hiện tại'),
                    selected: _value.mealTime == null,
                    onSelected: (_) => _update(clearMeal: true),
                  ),
                  for (final m in MealTime.values)
                    ChoiceChip(
                      label: Text(m.label),
                      selected: _value.mealTime == m,
                      onSelected: (_) => _update(meal: m),
                    ),
                ]),
                _group('Đi cùng', [
                  ChoiceChip(
                    label: const Text('Bất kỳ'),
                    selected: _value.companion == null,
                    onSelected: (_) => _update(clearCompanion: true),
                  ),
                  for (final c in Companion.values)
                    ChoiceChip(
                      label: Text(c.label),
                      selected: _value.companion == c,
                      onSelected: (_) => _update(companion: c),
                    ),
                ]),
                _group('Kiểu món', [
                  for (final c in foodCategories)
                    FilterChip(
                      label: Text('${c.icon} ${c.name}'),
                      selected: _value.selectedCategories.contains(c.id),
                      onSelected: (selected) {
                        final next = {..._value.selectedCategories};
                        selected ? next.add(c.id) : next.remove(c.id);
                        setState(() => _value = _value.withCategories(next));
                      },
                    ),
                ]),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                TextButton(
                  onPressed: () =>
                      setState(() => _value = const MealPreference()),
                  child: const Text('Xóa bộ lọc'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      ref.read(settingsProvider.notifier).setPreference(_value);
                      Navigator.pop(context);
                    },
                    child: const Text('Áp dụng'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
