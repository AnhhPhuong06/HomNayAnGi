import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../restaurants/widgets/restaurant_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(settingsProvider.select((s) => s.favorites));
    final data = ref.watch(restaurantsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Yêu thích')),
      body: ContentWidth(
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, stack) => EmptyMessage(
            title: 'Không thể tải quán đã lưu.',
            message: 'Danh sách yêu thích vẫn được giữ trên thiết bị.',
            action: 'Thử lại',
            onAction: () => ref.invalidate(restaurantsProvider),
          ),
          data: (restaurants) {
            final favorites = restaurants
                .where((r) => ids.contains(r.id))
                .toList();
            if (favorites.isEmpty) {
              return EmptyMessage(
                title: 'Bạn chưa lưu quán nào.',
                message:
                    'Chạm vào trái tim để giữ lại những quán bạn muốn thử.',
                icon: Icons.favorite_border,
                action: 'Khám phá quán',
                onAction: () => context.go('/discover'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: favorites.length + 1,
              itemBuilder: (_, i) => i == 0
                  ? const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: DataSourceNotice(),
                    )
                  : RestaurantCard(restaurant: favorites[i - 1]),
            );
          },
        ),
      ),
    );
  }
}
