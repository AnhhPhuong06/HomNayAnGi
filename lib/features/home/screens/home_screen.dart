import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/utils/geo.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/adaptive_cards.dart';
import '../../../core/widgets/editorial.dart';
import '../../auth/auth_repository.dart';
import '../../recommendation/models/meal_preference.dart';
import '../../settings/screens/taste_sheet.dart';
import '../../restaurants/widgets/restaurant_card.dart';
import '../../restaurants/services/restaurant_queries.dart';
import '../widgets/category_strip.dart';
import '../widgets/choose_button.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/location_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(settingsProvider.select((s) => s.location));
    final preference = ref.watch(settingsProvider.select((s) => s.preference));
    final taste = ref.watch(settingsProvider.select((s) => s.taste));
    final data = ref.watch(restaurantsProvider);
    final member = ref.watch(memberProvider).asData?.value;
    final s = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hôm Nay Ăn Gì?',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Bộ lọc',
            onPressed: () => showFilters(context),
            icon: const Icon(Icons.tune_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton.filledTonal(
              tooltip: 'Tài khoản',
              onPressed: () => context.go('/settings'),
              icon: member == null
                  ? const Icon(Icons.person_outline_rounded)
                  : Text(
                      member.name.trim().isEmpty
                          ? 'B'
                          : member.name.trim().characters.first.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
      body: ContentWidth(
        maxWidth: 1120,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.list(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: s.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.location_on_outlined,
                            color: s.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton(
                            onPressed: () => showLocationPicker(context),
                            style: TextButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 10,
                              ),
                            ),
                            child: Text(
                              location?.label ?? 'Chọn khu vực của bạn',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: s.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  MealPhotoHero(
                    eyebrow: 'BỮA NGON, BỚT ĐẮN ĐO',
                    title: 'Hôm nay,\năn thật ngon.',
                    image: 'assets/images/salad.jpg',
                    description:
                        'Một chút bất ngờ cho chiếc bụng đói.\nĐể chúng tôi chọn giúp bạn.',
                    action: const ChooseButton(),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('Bộ lọc'),
                        onPressed: () => showFilters(context),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.payments_outlined, size: 16),
                        label: Text(
                          formatPrice(
                                    preference.budgetMin,
                                    preference.budgetMax,
                                  ) ==
                                  'Chưa có giá'
                              ? 'Mọi ngân sách'
                              : formatPrice(
                                  preference.budgetMin,
                                  preference.budgetMax,
                                ),
                        ),
                        onPressed: () => showFilters(context),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.near_me_outlined, size: 16),
                        label: Text('< ${preference.maxDistance.toInt()} km'),
                        onPressed: () => showFilters(context),
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.restaurant_menu_rounded,
                          size: 16,
                        ),
                        label: const Text('Khẩu vị'),
                        onPressed: () => showTastePreferences(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const SectionTitle('Hôm nay bạn thích…'),
                  const SizedBox(height: 14),
                  CategoryStrip(
                    selected: preference.selectedCategories,
                    onToggle: (id) {
                      final next = {...preference.selectedCategories};
                      next.contains(id) ? next.remove(id) : next.add(id);
                      ref
                          .read(settingsProvider.notifier)
                          .setPreference(preference.withCategories(next));
                    },
                  ),
                  const SizedBox(height: 26),
                  SectionTitle(
                    location == null
                        ? 'Một vài gợi ý cho bạn'
                        : 'Quanh khu vực của bạn',
                    action: 'Xem tất cả',
                    onAction: () => context.go('/discover'),
                  ),
                  const SizedBox(height: 12),
                  const DataSourceNotice(compact: true),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            ...data.when(
              loading: () => [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
              error: (_, _) => [
                SliverToBoxAdapter(
                  child: EmptyMessage(
                    title: 'Không thể tải danh sách quán.',
                    message: 'Vui lòng thử lại.',
                    icon: Icons.cloud_off,
                    action: 'Thử lại',
                    onAction: () => ref.invalidate(restaurantsProvider),
                  ),
                ),
              ],
              data: (restaurants) {
                final visible = queryRestaurants(
                  restaurants,
                  preference: preference,
                  origin: location?.point,
                  user: UserPreference(
                    dislikedCategories: taste.dislikedCategories,
                    hiddenRestaurantIds: taste.hiddenRestaurantIds,
                    avoidedKeywords: taste.avoidedKeywords,
                  ),
                ).take(6).toList();
                if (visible.isEmpty) {
                  return [
                    SliverToBoxAdapter(
                      child: EmptyMessage(
                        title: 'Chưa có quán trong khu vực này.',
                        message: 'Thử mở rộng khoảng cách hoặc đổi khu vực.',
                        action: 'Chỉnh bộ lọc',
                        onAction: () => showFilters(context),
                      ),
                    ),
                  ];
                }
                return [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: AdaptiveCards(
                      itemCount: visible.length,
                      itemBuilder: (_, i) =>
                          RestaurantCard(restaurant: visible[i]),
                    ),
                  ),
                ];
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
