import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/utils/geo.dart';
import '../../../core/widgets/common.dart';
import '../../home/widgets/choose_button.dart';
import '../../restaurants/widgets/restaurant_card.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recommendationProvider);
    final result = state.result;
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gợi ý hôm nay')),
        body: EmptyMessage(
          title: 'Bữa ngon đang chờ bạn.',
          message: 'Chọn giúp tôi để nhận gợi ý phù hợp.',
          action: 'Về trang chủ',
          onAction: () => context.go('/'),
        ),
      );
    }
    final r = result.selected.restaurant;
    return Scaffold(
      appBar: AppBar(title: const Text('Gợi ý hôm nay')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const DataSourceNotice(compact: true),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎉  HÔM NAY ĂN…',
                    style: TextStyle(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    r.dishName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Điểm phù hợp ${(result.selected.score * 100).round()}/100',
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Điểm xếp hạng tham khảo, không phải xác suất hài lòng.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${formatPrice(r.priceMin, r.priceMax)} · Bữa ${result.mealTime.label.toLowerCase()}',
                  ),
                ],
              ),
            ),
            for (final notice in result.notices)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('ⓘ $notice'),
              ),
            const SizedBox(height: 20),
            RestaurantCard(restaurant: r),
            OutlinedButton.icon(
              onPressed: () => context.push(
                Uri(
                  path: '/blog/new',
                  queryParameters: {'kind': 'meal', 'restaurant': r.id},
                ).toString(),
              ),
              icon: const Icon(Icons.edit_note),
              label: const Text('Chia sẻ hôm nay ăn gì'),
            ),
            const SizedBox(height: 12),
            const ChooseButton(label: 'CHỌN GỢI Ý KHÁC'),
            TextButton.icon(
              onPressed: state.busy
                  ? null
                  : () async {
                      await ref
                          .read(settingsProvider.notifier)
                          .hideRestaurant(r.id, true);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đã ẩn quán. Bấm chọn gợi ý khác để tiếp tục.',
                            ),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.visibility_off_outlined),
              label: const Text('Không gợi ý quán này nữa'),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Các quán cùng kiểu món'),
            const SizedBox(height: 12),
            for (final restaurant
                in result.nearby.where((other) => other.id != r.id).take(5))
              RestaurantCard(restaurant: restaurant),
          ],
        ),
      ),
    );
  }
}
