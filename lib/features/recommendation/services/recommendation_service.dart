import 'dart:math';
import '../../../core/utils/geo.dart';
import '../../restaurants/models/restaurant.dart';
import '../../restaurants/models/food_category.dart';
import '../models/meal_preference.dart';

class RecommendationConfig {
  const RecommendationConfig({
    this.distanceWeight = .25,
    this.budgetWeight = .25,
    this.mealWeight = .20,
    this.ratingWeight = .15,
    this.preferenceWeight = .10,
    this.noveltyWeight = .05,
    this.poolSize = 5,
    this.minimumScore = .35,
  });
  final double distanceWeight,
      budgetWeight,
      mealWeight,
      ratingWeight,
      preferenceWeight,
      noveltyWeight,
      minimumScore;
  final int poolSize;
}

class ScoredRestaurant {
  const ScoredRestaurant(this.restaurant, this.score);
  final Restaurant restaurant;
  final double score;
}

class RecommendationResult {
  const RecommendationResult({
    required this.selected,
    required this.nearby,
    required this.notices,
    required this.mealTime,
  });
  final ScoredRestaurant selected;
  final List<Restaurant> nearby;
  final List<String> notices;
  final MealTime mealTime;
}

bool matchesBudget(Restaurant r, MealPreference p) {
  if (p.budgetMin == null && p.budgetMax == null) return true;
  if (r.priceMin == null && r.priceMax == null) return false;
  return (p.budgetMax == null ||
          r.priceMin == null ||
          r.priceMin! <= p.budgetMax!) &&
      (p.budgetMin == null ||
          r.priceMax == null ||
          r.priceMax! >= p.budgetMin!);
}

double mealTimeScore(Restaurant r, MealTime meal) => r.mealTimes.isEmpty
    ? .5
    : r.mealTimes.contains(meal)
    ? 1
    : 0;

class TasteMatcher {
  TasteMatcher(this.user)
    : keywords = user.avoidedKeywords
          .map(normalizeSearch)
          .where((word) => word.trim().isNotEmpty)
          .toList();
  final UserPreference user;
  final List<String> keywords;
  bool allows(Restaurant r) {
    if (user.hiddenRestaurantIds.contains(r.id) ||
        r.categories.any(user.dislikedCategories.contains)) {
      return false;
    }
    if (keywords.isEmpty) return true;
    final text =
        r.indexedSearchText ??
        normalizeSearch(
          [
            r.name,
            r.dishName,
            r.description,
            ...r.tags,
            for (final id in r.categories) categoryById(id).name,
          ].join(' '),
        );
    return !keywords.any(text.contains);
  }
}

class RecommendationService {
  RecommendationService({
    Random? random,
    this.config = const RecommendationConfig(),
  }) : _random = random ?? Random() {
    final weights = [
      config.distanceWeight,
      config.budgetWeight,
      config.mealWeight,
      config.ratingWeight,
      config.preferenceWeight,
      config.noveltyWeight,
    ];
    if (weights.any((w) => !w.isFinite || w < 0) ||
        (weights.fold(0.0, (a, b) => a + b) - 1).abs() > .0001 ||
        config.poolSize < 1 ||
        !config.minimumScore.isFinite ||
        config.minimumScore < 0 ||
        config.minimumScore > 1) {
      throw ArgumentError('Invalid recommendation configuration');
    }
  }
  final Random _random;
  final RecommendationConfig config;

  RecommendationResult? recommend({
    required List<Restaurant> restaurants,
    required MealPreference preference,
    GeoPoint? location,
    UserPreference user = const UserPreference(),
    List<String> history = const [],
    DateTime? now,
  }) {
    final origin = location?.isValid == true ? location : null;
    final meal = preference.mealTime ?? MealTime.at(now ?? DateTime.now());
    final unique = <String, Restaurant>{};
    for (final r in restaurants) {
      if (r.isUsable) unique.putIfAbsent(r.id, () => r);
    }
    var candidates = unique.values.toList();
    if (candidates.isEmpty) return null;
    final notices = <String>[];
    // Explicit dislikes are never relaxed. An empty result is preferable.
    candidates = candidates.where(TasteMatcher(user).allows).toList();
    if (candidates.isEmpty) return null;
    var selected = preference.selectedCategories;
    final hasBudget =
        preference.budgetMin != null || preference.budgetMax != null;
    final allPricesUnknown = candidates.every(
      (r) => r.priceMin == null && r.priceMax == null,
    );
    var enforceBudget = !(hasBudget && allPricesUnknown);
    if (!enforceBudget) {
      notices.add(
        'Nguồn chưa có giá. Gợi ý chưa được kiểm chứng theo ngân sách; hãy hỏi quán trước khi đến.',
      );
    }
    var radius = preference.maxDistance.isFinite && preference.maxDistance > 0
        ? preference.maxDistance
        : 3.0;
    List<Restaurant> filter() => candidates
        .where(
          (r) =>
              (selected.isEmpty || r.categories.any(selected.contains)) &&
              (!enforceBudget || matchesBudget(r, preference)) &&
              (origin == null || distanceKm(origin, r.location) <= radius),
        )
        .toList();
    var pool = filter();
    if (origin == null) {
      notices.add('Chưa có vị trí. Gợi ý chưa được giới hạn theo khoảng cách.');
    }
    if (pool.isEmpty && origin != null) {
      for (final next in distanceOptions.where((d) => d > radius).toList()) {
        radius = next;
        pool = filter();
        if (pool.isNotEmpty) break;
      }
    }
    if (pool.isEmpty && enforceBudget && hasBudget) {
      enforceBudget = false;
      pool = filter();
      notices.add(
        'Chưa có quán đúng ngân sách. Đã mở rộng khoảng giá; hãy kiểm tra giá trước khi chọn.',
      );
    }
    if (pool.isEmpty && selected.isNotEmpty) {
      selected = const {};
      pool = filter();
      notices.add('Chưa có kiểu món đã chọn. Đang gợi ý thêm kiểu món khác.');
    }
    // Do not silently recommend a restaurant hundreds of kilometres away.
    if (pool.isEmpty) return null;
    if (origin != null && radius > preference.maxDistance) {
      notices.insert(
        0,
        'Không có quán phù hợp trong ${preference.maxDistance.toStringAsFixed(0)} km; đã mở rộng lên ${radius.toStringAsFixed(0)} km.',
      );
    }
    final recent = history.take(user.avoidRecentCount.clamp(0, 10)).toSet();
    if (recent.isNotEmpty) {
      final fresh = pool.where((r) => !recent.contains(r.id)).toList();
      if (fresh.isNotEmpty) {
        pool = fresh;
      } else {
        notices.add(
          'Các quán phù hợp đều có trong lịch sử gần đây. Đang chọn lại trong nhóm này.',
        );
      }
    }
    double score(Restaurant r) {
      final distance = origin == null
          ? .5
          : (1 - distanceKm(origin, r.location) / radius).clamp(0.0, 1.0);
      final budget = matchesBudget(r, preference)
          ? 1.0
          : r.priceMin == null && r.priceMax == null
          ? .4
          : .1;
      final category = preference.selectedCategories.isEmpty
          ? .7
          : r.categories.any(preference.selectedCategories.contains)
          ? 1.0
          : .2;
      final favorite =
          user.favoriteRestaurantIds.contains(r.id) ||
          r.categories.any(user.favoriteCategories.contains);
      final companion = preference.companion == null || r.companions.isEmpty
          ? .5
          : r.companions.contains(preference.companion)
          ? 1.0
          : 0.0;
      final affinity =
          category * .6 + (favorite ? 1 : .5) * .2 + companion * .2;
      final index = history.indexOf(r.id);
      final novelty = index < 0
          ? 1.0
          : ((index + 1) / (history.length + 1)) * .4;
      return distance * config.distanceWeight +
          budget * config.budgetWeight +
          mealTimeScore(r, meal) * config.mealWeight +
          ((r.rating ?? 3) / 5) * config.ratingWeight +
          affinity * config.preferenceWeight +
          novelty * config.noveltyWeight;
    }

    var ranked = pool.map((r) => ScoredRestaurant(r, score(r))).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final acceptable = ranked
        .where((r) => r.score >= config.minimumScore)
        .toList();
    if (acceptable.isNotEmpty) ranked = acceptable;
    // Avoid an immediate repeat whenever another viable restaurant exists.
    if (ranked.length > 1 && history.isNotEmpty) {
      ranked = ranked.where((r) => r.restaurant.id != history.first).toList();
      final previous = unique[history.first];
      if (previous != null) {
        final newDishes = ranked
            .where(
              (r) =>
                  normalizeSearch(r.restaurant.dishName) !=
                  normalizeSearch(previous.dishName),
            )
            .toList();
        if (newDishes.isNotEmpty) ranked = newDishes;
      }
    }
    final top = ranked.take(config.poolSize).toList();
    final chosen = weightedPick(top);
    final nearby = pool
        .where((r) => r.categories.any(chosen.restaurant.categories.contains))
        .toList();
    if (origin != null) {
      nearby.sort(
        (a, b) => distanceKm(
          origin,
          a.location,
        ).compareTo(distanceKm(origin, b.location)),
      );
    }
    return RecommendationResult(
      selected: chosen,
      nearby: List.unmodifiable(nearby),
      notices: List.unmodifiable(notices),
      mealTime: meal,
    );
  }

  ScoredRestaurant weightedPick(List<ScoredRestaurant> pool) {
    if (pool.isEmpty) throw ArgumentError('Empty candidate pool');
    if (pool.any((r) => !r.score.isFinite || r.score < 0)) {
      throw ArgumentError('Invalid weight');
    }
    final total = pool.fold(0.0, (sum, item) => sum + item.score);
    if (total == 0) return pool[_random.nextInt(pool.length)];
    var cursor = _random.nextDouble() * total;
    for (final item in pool) {
      cursor -= item.score;
      if (cursor < 0) return item;
    }
    return pool.last;
  }
}
