import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/appearance.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(settingsProvider.select((s) => s.appearance));
    void save(Appearance next) =>
        ref.read(settingsProvider.notifier).setAppearance(next);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Màu của bạn', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final accent in AppAccent.values)
              ChoiceChip(
                avatar: Icon(Icons.circle, size: 16, color: accent.color),
                label: Text(accent.label),
                selected: value.accent == accent,
                onSelected: (_) => save(value.copyWith(accent: accent)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Cỡ chữ trong ứng dụng',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (size, label) in [
              (1.0, 'Theo hệ thống'),
              (1.15, 'Lớn hơn'),
              (1.3, 'Rất lớn'),
            ])
              ChoiceChip(
                label: Text(label),
                selected: value.textSize == size,
                onSelected: (_) => save(value.copyWith(textSize: size)),
              ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Tăng thêm trên cỡ chữ hệ thống; không giới hạn chữ trợ năng.',
          ),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Thẻ quán gọn'),
          subtitle: const Text('Thu nhỏ ảnh để xem được nhiều quán hơn.'),
          value: value.compactCards,
          onChanged: (v) => save(value.copyWith(compactCards: v)),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Giảm chuyển động'),
          subtitle: const Text(
            'Bỏ hiệu ứng chọn món và chuyển trang của ứng dụng. Luôn tôn trọng cài đặt trợ năng hệ thống.',
          ),
          value: value.reduceMotion,
          onChanged: (v) => save(value.copyWith(reduceMotion: v)),
        ),
      ],
    );
  }
}
