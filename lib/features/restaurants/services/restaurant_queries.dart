import '../../../core/utils/geo.dart';
import '../../recommendation/models/meal_preference.dart';
import '../../recommendation/services/recommendation_service.dart';
import '../models/food_category.dart';
import '../models/restaurant.dart';

List<Restaurant> queryRestaurants(
  List<Restaurant> restaurants, {
  String query = '',
  MealPreference preference = const MealPreference(),
  GeoPoint? origin,
  UserPreference user = const UserPreference(),
}) {
  final terms = normalizeSearch(
    query,
  ).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  final distances = <String, double>{};
  final taste = TasteMatcher(user);
  final result = restaurants.where((r) {
    if (!r.isUsable || !taste.allows(r) || !matchesBudget(r, preference)) {
      return false;
    }
    if (preference.selectedCategories.isNotEmpty &&
        !r.categories.any(preference.selectedCategories.contains)) {
      return false;
    }
    if (origin != null) {
      final km = distanceKm(origin, r.location);
      if (km > preference.maxDistance) return false;
      distances[r.id] = km;
    }
    if (preference.mealTime != null &&
        r.mealTimes.isNotEmpty &&
        !r.mealTimes.contains(preference.mealTime)) {
      return false;
    }
    if (preference.companion != null &&
        r.companions.isNotEmpty &&
        !r.companions.contains(preference.companion)) {
      return false;
    }
    if (terms.isEmpty) return true;
    final text =
        r.indexedSearchText ??
        normalizeSearch(
          [
            r.name,
            r.description,
            ...r.tags,
            for (final id in r.categories) ...[
              categoryById(id).name,
              ...categoryById(id).keywords,
            ],
          ].join(' '),
        );
    return terms.every(text.contains);
  }).toList();
  if (origin != null) {
    result.sort((a, b) => distances[a.id]!.compareTo(distances[b.id]!));
  }
  return result;
}
