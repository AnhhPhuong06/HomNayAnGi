import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/utils/geo.dart';
import '../models/food_category.dart';
import '../models/restaurant.dart';

class FoodImage extends StatelessWidget {
  const FoodImage({super.key, required this.restaurant, this.height = 160});
  final Restaurant restaurant;
  final double height;
  @override
  Widget build(BuildContext context) {
    Widget fallback() => Container(
      height: height,
      width: double.infinity,
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ramen_dining, size: 48),
          SizedBox(height: 8),
          Text('Ảnh chưa khả dụng'),
        ],
      ),
    );
    final source = restaurant.imageUrl;
    if (source.startsWith('assets/images/')) {
      return Image.asset(
        source,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        cacheWidth: 1000,
        excludeFromSemantics: true,
        errorBuilder: (_, error, stack) => fallback(),
      );
    }
    final uri = Uri.tryParse(source);
    if (uri?.scheme != 'https' || uri!.host.isEmpty) return fallback();
    return Image.network(
      source,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      cacheWidth: 1000,
      excludeFromSemantics: true,
      errorBuilder: (_, error, stack) => fallback(),
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : fallback(),
    );
  }
}

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorite = ref.watch(
      settingsProvider.select((s) => s.favorites.contains(id)),
    );
    return IconButton.filledTonal(
      tooltip: favorite ? 'Bỏ yêu thích' : 'Lưu yêu thích',
      isSelected: favorite,
      icon: Icon(favorite ? Icons.favorite : Icons.favorite_border),
      onPressed: () => ref.read(settingsProvider.notifier).toggleFavorite(id),
    );
  }
}

class RestaurantCard extends ConsumerWidget {
  const RestaurantCard({super.key, required this.restaurant});
  final Restaurant restaurant;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final origin = ref.watch(settingsProvider.select((s) => s.location?.point));
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () =>
            context.push('/restaurant/${Uri.encodeComponent(restaurant.id)}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                FoodImage(restaurant: restaurant),
                Positioned(
                  right: 8,
                  top: 8,
                  child: FavoriteButton(id: restaurant.id),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    restaurant.categories
                        .map((c) => categoryById(c).name)
                        .join(' · '),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      Text(
                        restaurant.rating == null
                            ? 'Chưa có đánh giá'
                            : '★ ${restaurant.rating!.toStringAsFixed(1)}',
                      ),
                      if (origin != null)
                        Text(
                          formatDistance(
                            distanceKm(origin, restaurant.location),
                          ),
                        ),
                      Text(
                        formatPrice(restaurant.priceMin, restaurant.priceMax),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${restaurant.area} · ${restaurant.province}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
