import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/services/maps_service.dart';
import '../../../core/utils/geo.dart';
import '../../../core/widgets/common.dart';
import '../../home/widgets/choose_button.dart';
import '../models/food_category.dart';
import '../models/restaurant.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/source_links.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  const RestaurantDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  bool _opening = false;
  Future<void> _directions(Restaurant restaurant, bool isDemo) async {
    if (_opening) return;
    if (isDemo) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Địa điểm minh họa'),
          content: const Text(
            'Quán này không phải địa điểm đã xác minh. Chỉ mở bản đồ để thử chức năng với tọa độ demo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Quay lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Thử mở bản đồ'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    setState(() => _opening = true);
    final success = await MapsService().directions(restaurant);
    if (!mounted) return;
    setState(() => _opening = false);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được bản đồ. Hãy thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(restaurantsProvider);
    final location = ref.watch(settingsProvider.select((s) => s.location));
    final isDemo = ref.watch(repositoryProvider).isDemo;
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết quán')),
      body: ContentWidth(
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, stack) => EmptyMessage(
            title: 'Không thể tải thông tin quán.',
            message: 'Vui lòng thử lại.',
            action: 'Thử lại',
            onAction: () => ref.invalidate(restaurantsProvider),
          ),
          data: (restaurants) {
            final r = restaurants.where((r) => r.id == widget.id).firstOrNull;
            if (r == null) {
              return const EmptyMessage(
                title: 'Không tìm thấy quán.',
                message: 'Quán có thể không còn trong nguồn dữ liệu hiện tại.',
              );
            }
            return ListView(
              children: [
                FoodImage(restaurant: r, height: 260),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DataSourceNotice(),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              r.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          FavoriteButton(id: r.id),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Text(
                            r.rating == null
                                ? 'Chưa có đánh giá'
                                : '★ ${r.rating!.toStringAsFixed(1)}${r.reviewCount == null ? '' : ' (${r.reviewCount} đánh giá)'}',
                          ),
                          if (location != null)
                            Text(
                              formatDistance(
                                distanceKm(location.point, r.location),
                              ),
                            ),
                          Text(formatPrice(r.priceMin, r.priceMax)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(r.description, style: const TextStyle(height: 1.6)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final id in r.categories)
                            Chip(
                              label: Text(
                                '${categoryById(id).icon} ${categoryById(id).name}',
                              ),
                            ),
                          for (final tag in r.tags) Chip(label: Text(tag)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(r.address),
                        subtitle: Text('${r.area}, ${r.province} · Việt Nam'),
                      ),
                      if (r.openingHours != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.schedule),
                          title: Text(r.openingHours!),
                          subtitle: const Text(
                            'Giờ tham khảo; chưa xác minh trạng thái hiện tại',
                          ),
                        ),
                      if (r.phone != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.phone_outlined),
                          title: Text(r.phone!),
                          onTap: isDemo
                              ? null
                              : () async {
                                  final success = await MapsService().call(
                                    r.phone!,
                                  );
                                  if (!success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Không mở được ứng dụng gọi điện.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                        ),
                      const SizedBox(height: 20),
                      if (!isDemo) ...[
                        RestaurantSourceLinks(restaurant: r),
                        const SizedBox(height: 20),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _opening
                              ? null
                              : () => _directions(r, isDemo),
                          icon: const Icon(Icons.directions_outlined),
                          label: Text(
                            _opening ? 'Đang mở bản đồ…' : 'Chỉ đường',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const ChooseButton(label: 'CHỌN QUÁN KHÁC'),
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
