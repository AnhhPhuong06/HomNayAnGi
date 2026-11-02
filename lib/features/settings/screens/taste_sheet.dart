import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../recommendation/models/taste_preference.dart';
import '../../restaurants/models/food_category.dart';
import '../../restaurants/models/restaurant.dart';
import '../../auth/auth_repository.dart';

Future<void> showTastePreferences(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (_) => const TasteSheet(),
    );

class TasteSheet extends ConsumerStatefulWidget {
  const TasteSheet({super.key});
  @override
  ConsumerState<TasteSheet> createState() => _TasteSheetState();
}

class _TasteSheetState extends ConsumerState<TasteSheet> {
  late TastePreference _taste;
  late final TextEditingController _keywords;
  String? _error;
  String? _ownerId;
  @override
  void initState() {
    super.initState();
    _ownerId = ref.read(memberProvider).asData?.value?.id;
    _taste = ref.read(settingsProvider).taste;
    _keywords = TextEditingController(text: _taste.avoidedKeywords.join(', '));
  }

  @override
  void dispose() {
    _keywords.dispose();
    super.dispose();
  }

  void _save() {
    if (_ownerId != ref.read(memberProvider).asData?.value?.id) {
      Navigator.pop(context);
      return;
    }
    final words = _keywords.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (words.length > 20 || words.any((s) => s.length > 40)) {
      setState(
        () => _error = 'Tối đa 20 từ khóa, mỗi từ khóa không quá 40 ký tự.',
      );
      return;
    }
    ref
        .read(settingsProvider.notifier)
        .setTaste(_taste.copyWith(avoidedKeywords: words));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final names = {
      for (final r
          in ref.watch(restaurantsProvider).asData?.value ?? <Restaurant>[])
        r.id: r.name,
    };
    return FractionallySizedBox(
      heightFactor: .92,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Khẩu vị của bạn',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng khẩu vị',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              children: [
                Text(
                  'Bữa ăn hợp ý hơn mỗi ngày',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Món và quán bạn muốn tránh sẽ được loại khỏi gợi ý và Khám phá, kể cả khi nới bộ lọc.',
                ),
                const SizedBox(height: 24),
                Text(
                  'Kiểu món không thích',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final c in foodCategories)
                      FilterChip(
                        label: Text('${c.icon} ${c.name}'),
                        selected: _taste.dislikedCategories.contains(c.id),
                        onSelected: (selected) => setState(() {
                          final ids = {..._taste.dislikedCategories};
                          selected ? ids.add(c.id) : ids.remove(c.id);
                          _taste = _taste.copyWith(dislikedCategories: ids);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _keywords,
                  maxLength: 800,
                  decoration: InputDecoration(
                    labelText: 'Từ khóa muốn tránh',
                    hintText: 'Ví dụ: hải sản, ốc',
                    errorText: _error,
                    helperText:
                        'Ngăn cách bằng dấu phẩy; so tên, mô tả và nhãn món.',
                    helperMaxLines: 3,
                  ),
                ),
                const Text(
                  'Nguồn quán chưa có danh sách nguyên liệu đầy đủ. Bộ lọc không xác nhận món ăn chay hoặc an toàn với dị ứng; cần hỏi trực tiếp quán.',
                ),
                const SizedBox(height: 24),
                Text(
                  'Ưu tiên quán chưa chọn gần đây',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final count in [0, 3, 5, 10])
                      ChoiceChip(
                        label: Text(
                          count == 0
                              ? 'Không giới hạn'
                              : '$count lượt gần nhất',
                        ),
                        selected: _taste.avoidRecentCount == count,
                        onSelected: (_) => setState(
                          () =>
                              _taste = _taste.copyWith(avoidRecentCount: count),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Quán đã ẩn (${_taste.hiddenRestaurantIds.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_taste.hiddenRestaurantIds.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Bạn có thể ẩn quán từ trang chi tiết hoặc kết quả gợi ý.',
                    ),
                  ),
                for (final id in _taste.hiddenRestaurantIds.take(20))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(names[id] ?? id),
                    trailing: IconButton(
                      tooltip: 'Bỏ ẩn quán',
                      icon: const Icon(Icons.visibility_outlined),
                      onPressed: () => setState(
                        () => _taste = _taste.copyWith(
                          hiddenRestaurantIds: {..._taste.hiddenRestaurantIds}
                            ..remove(id),
                        ),
                      ),
                    ),
                  ),
                if (_taste.hiddenRestaurantIds.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(
                      () => _taste = _taste.copyWith(hiddenRestaurantIds: {}),
                    ),
                    child: const Text('Bỏ ẩn tất cả quán'),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _taste = const TastePreference();
                      _keywords.clear();
                      _error = null;
                    }),
                    child: const Text('Đặt lại'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Lưu khẩu vị'),
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
}
