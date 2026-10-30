import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/utils/geo.dart';
import '../../../core/widgets/common.dart';
import '../../restaurants/models/food_category.dart';
import '../../restaurants/widgets/restaurant_card.dart';
import '../../restaurants/services/restaurant_queries.dart';
import '../widgets/choose_button.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/location_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(settingsProvider.select((s) => s.location));
    final preference = ref.watch(settingsProvider.select((s) => s.preference));
    final data = ref.watch(restaurantsProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hôm Nay Ăn Gì?'),
        actions: [
          IconButton(
            tooltip: 'Bộ lọc',
            onPressed: () => showFilters(context),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: ContentWidth(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.list(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => showLocationPicker(context),
                      icon: const Icon(Icons.location_on_outlined, size: 18),
                      label: Text(
                        location?.label ?? 'Chọn khu vực của bạn',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primaryContainer,
                          scheme.tertiaryContainer,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: scheme.onPrimaryContainer,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'BỮA NGON, BỚT ĐẮN ĐO',
                              style: TextStyle(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 1.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Bạn đang không\nbiết ăn gì?',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                                color: scheme.onPrimaryContainer,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Để chúng tôi chọn giúp bạn.',
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const ChooseButton(),
                        const SizedBox(height: 12),
                        Text(
                          'Một chút bất ngờ. Một bữa thật ngon.',
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.tune, size: 17),
                        label: const Text('Bộ lọc'),
                        onPressed: () => showFilters(context),
                      ),
                      ActionChip(
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
                        label: Text('< ${preference.maxDistance.toInt()} km'),
                        onPressed: () => showFilters(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle('Hôm nay bạn thích…'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in foodCategories)
                        FilterChip(
                          label: Text('${c.icon}  ${c.name}'),
                          selected: preference.selectedCategories.contains(
                            c.id,
                          ),
                          onSelected: (selected) {
                            final next = {...preference.selectedCategories};
                            selected ? next.add(c.id) : next.remove(c.id);
                            ref
                                .read(settingsProvider.notifier)
                                .setPreference(preference.withCategories(next));
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const DataSourceNotice(),
                  const SizedBox(height: 20),
                  SectionTitle(
                    location == null
                        ? 'Một vài gợi ý cho bạn'
                        : 'Quanh khu vực của bạn',
                    action: 'Xem tất cả',
                    onAction: () => context.go('/discover'),
                  ),
                  const SizedBox(height: 12),
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
              error: (_, stack) => [
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
                    sliver: SliverList.builder(
                      itemCount: visible.length,
                      itemBuilder: (_, i) =>
                          RestaurantCard(restaurant: visible[i]),
                    ),
                  ),
                ];
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}
