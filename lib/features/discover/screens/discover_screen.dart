import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/adaptive_cards.dart';
import '../../../core/widgets/editorial.dart';
import '../../home/widgets/filter_sheet.dart';
import '../../restaurants/services/restaurant_queries.dart';
import '../../restaurants/widgets/restaurant_card.dart';
import '../../recommendation/models/meal_preference.dart';
import '../../home/widgets/location_sheet.dart';
import '../widgets/restaurant_map.dart';
import '../widgets/community_places.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String _query = '';
  bool _map = false;
  bool _community = false;
  bool _photosOnly = false;
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(restaurantsProvider);
    final p = ref.watch(settingsProvider.select((s) => s.preference));
    final location = ref.watch(settingsProvider.select((s) => s.location));
    final taste = ref.watch(settingsProvider.select((s) => s.taste));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khám phá'),
        actions: [
          IconButton(
            tooltip: 'Bộ lọc',
            onPressed: () => showFilters(context),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: ContentWidth(
        maxWidth: 1120,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              sliver: SliverList.list(
                children: [
                  PageIntro(
                    eyebrow: 'ĐI TÌM VỊ NGON',
                    title: 'Tìm quán hợp ý.',
                    description: location == null
                        ? 'Tìm một món quen hay khám phá địa chỉ bạn chưa từng ghé.'
                        : 'Khám phá quanh ${location.label}.',
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Tìm món hoặc quán...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Danh mục OSM'),
                        selected: !_community,
                        onSelected: (_) => setState(() => _community = false),
                      ),
                      ChoiceChip(
                        label: const Text('Cộng đồng'),
                        selected: _community,
                        onSelected: (_) => setState(() => _community = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!_community)
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.view_list_outlined),
                          label: Text('Danh sách'),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.map_outlined),
                          label: Text('Bản đồ'),
                        ),
                      ],
                      selected: {_map},
                      onSelectionChanged: (value) =>
                          setState(() => _map = value.single),
                    ),
                  const SizedBox(height: 12),
                  if (!_community) const DataSourceNotice(compact: true),
                  if (!_community)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilterChip(
                        showCheckmark: false,
                        avatar: const Icon(
                          Icons.photo_camera_outlined,
                          size: 18,
                        ),
                        label: const Text('Có ảnh tại quán'),
                        selected: _photosOnly,
                        onSelected: (value) =>
                            setState(() => _photosOnly = value),
                      ),
                    ),
                ],
              ),
            ),
            if (_community)
              CommunityPlaces(query: _query)
            else
              data.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyMessage(
                    title: 'Không thể tải danh sách quán.',
                    message: 'Vui lòng thử lại.',
                    action: 'Thử lại',
                    onAction: () => ref.invalidate(restaurantsProvider),
                  ),
                ),
                data: (restaurants) {
                  final visible = queryRestaurants(
                    _photosOnly
                        ? restaurants.where((r) => r.photo != null).toList()
                        : restaurants,
                    query: _query,
                    preference: p,
                    origin: location?.point,
                    user: UserPreference(
                      dislikedCategories: taste.dislikedCategories,
                      hiddenRestaurantIds: taste.hiddenRestaurantIds,
                      avoidedKeywords: taste.avoidedKeywords,
                    ),
                  );
                  if (_map && location == null) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyMessage(
                        title: 'Bạn muốn khám phá ở đâu?',
                        message:
                            'Chọn khu vực để hiển thị bản đồ và quán gần đó.',
                        action: 'Chọn khu vực',
                        onAction: () => showLocationPicker(context),
                      ),
                    );
                  }
                  if (visible.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyMessage(
                        title: 'Chưa tìm thấy quán phù hợp.',
                        message: _photosOnly
                            ? 'Chưa có ảnh đã đối chiếu trong kết quả này. Hãy tắt lọc ảnh hoặc đổi khu vực/bộ lọc.'
                            : 'Thử từ khóa khác hoặc nới bộ lọc.',
                        action: 'Chỉnh bộ lọc',
                        onAction: () => showFilters(context),
                      ),
                    );
                  }
                  if (_map) {
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverToBoxAdapter(
                        child: RestaurantMap(
                          key: ValueKey(
                            '${location!.point.latitude}:${location.point.longitude}',
                          ),
                          restaurants: visible,
                          origin: location.point,
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              '${visible.length} quán phù hợp',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                        AdaptiveCards(
                          itemCount: visible.length,
                          itemBuilder: (_, i) =>
                              RestaurantCard(restaurant: visible[i]),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
