import 'package:flutter/material.dart';
import '../../../core/theme/appearance.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/utils/geo.dart';
import '../models/food_category.dart';
import '../models/restaurant.dart';
import 'dish_photo.dart';
import 'venue_photo.dart';

class FoodImage extends StatelessWidget {
  const FoodImage({super.key, required this.restaurant, this.height = 160});
  final Restaurant restaurant;
  final double height;
  @override
  Widget build(BuildContext context) {
    final photo = restaurant.photo;
    if (photo != null) {
      return VenuePhoto(
        photo: photo,
        categories: restaurant.categories,
        height: height,
      );
    }
    Widget fallback() =>
        DishPhoto(categories: restaurant.categories, height: height);
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
    final s = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      style: IconButton.styleFrom(
        backgroundColor: favorite
            ? s.primary
            : s.surfaceContainerLow.withValues(alpha: .95),
        foregroundColor: favorite ? s.onPrimary : s.onSurface,
      ),
      tooltip: favorite ? 'Bỏ yêu thích' : 'Lưu yêu thích',
      isSelected: favorite,
      icon: AnimatedSwitcher(
        duration: reducedMotion(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        child: Icon(
          favorite ? Icons.favorite : Icons.favorite_border,
          key: ValueKey(favorite),
        ),
      ),
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
    final compact = ref.watch(
      settingsProvider.select((s) => s.appearance.compactCards),
    );
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: FoodImage(
                      restaurant: restaurant,
                      height: compact ? 112 : 190,
                    ),
                  ),
                ),
                if (restaurant.categories.isNotEmpty)
                  Positioned(
                    left: 20,
                    top: 20,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow
                            .withValues(alpha: .96),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        categoryById(restaurant.categories.first).name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 18,
                  top: 18,
                  child: FavoriteButton(id: restaurant.id),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${restaurant.area} · ${restaurant.province}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      Text(
                        restaurant.rating == null
                            ? 'Chưa có đánh giá'
                            : '★ ${restaurant.rating!.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (origin != null)
                        Text(
                          formatDistance(
                            distanceKm(origin, restaurant.location),
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
