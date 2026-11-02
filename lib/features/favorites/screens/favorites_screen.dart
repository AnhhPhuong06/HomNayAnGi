import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/adaptive_cards.dart';
import '../../../core/widgets/editorial.dart';
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
        maxWidth: 1120,
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
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PageIntro(
                                eyebrow: 'ĐỂ DÀNH CHO BỮA TỚI',
                                title: 'Những quán\nbạn muốn quay lại.',
                                description:
                                    '${favorites.length} địa điểm đã lưu cho những lúc cần một lựa chọn quen.',
                              ),
                              const SizedBox(height: 18),
                              const DataSourceNotice(compact: true),
                            ],
                          ),
                        ),
                      ),
                      AdaptiveCards(
                        itemCount: favorites.length,
                        itemBuilder: (_, i) =>
                            RestaurantCard(restaurant: favorites[i]),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
