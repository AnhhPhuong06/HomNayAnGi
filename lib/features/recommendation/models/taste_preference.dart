import '../../restaurants/models/food_category.dart';

class TastePreference {
  const TastePreference({
    this.dislikedCategories = const {},
    this.hiddenRestaurantIds = const {},
    this.avoidedKeywords = const [],
    this.avoidRecentCount = 5,
  });
  final Set<String> dislikedCategories, hiddenRestaurantIds;
  final List<String> avoidedKeywords;
  final int avoidRecentCount;

  TastePreference copyWith({
    Set<String>? dislikedCategories,
    Set<String>? hiddenRestaurantIds,
    List<String>? avoidedKeywords,
    int? avoidRecentCount,
  }) => TastePreference(
    dislikedCategories: Set.unmodifiable(
      dislikedCategories ?? this.dislikedCategories,
    ),
    hiddenRestaurantIds: Set.unmodifiable(
      hiddenRestaurantIds ?? this.hiddenRestaurantIds,
    ),
    avoidedKeywords: List.unmodifiable(avoidedKeywords ?? this.avoidedKeywords),
    avoidRecentCount: avoidRecentCount ?? this.avoidRecentCount,
  );

  Map<String, Object> toJson() => {
    'dislikedCategories': dislikedCategories.toList(),
    'hiddenRestaurantIds': hiddenRestaurantIds.toList(),
    'avoidedKeywords': avoidedKeywords,
    'avoidRecentCount': avoidRecentCount,
  };
  factory TastePreference.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key, int limit) =>
        (json[key] is List ? json[key] as List : const <Object?>[])
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .take(limit)
            .toList();
    final categories = foodCategories.map((c) => c.id).toSet();
    return TastePreference(
      dislikedCategories: Set.unmodifiable(
        strings('dislikedCategories', 20).where(categories.contains),
      ),
      hiddenRestaurantIds: Set.unmodifiable(
        strings('hiddenRestaurantIds', 1000).where((id) => id.length <= 100),
      ),
      avoidedKeywords: List.unmodifiable(
        strings('avoidedKeywords', 20).where((s) => s.length <= 40).toSet(),
      ),
      avoidRecentCount: [0, 3, 5, 10].contains(json['avoidRecentCount'])
          ? json['avoidRecentCount'] as int
          : 5,
    );
  }
}
