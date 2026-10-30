import '../../../core/utils/geo.dart';
import '../../recommendation/models/meal_preference.dart';
import 'food_category.dart';
import 'source_link.dart';

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.address,
    required this.province,
    required this.area,
    required this.categories,
    required this.tags,
    this.country = 'VN',
    this.priceMin,
    this.priceMax,
    this.rating,
    this.reviewCount,
    this.openingHours,
    this.phone,
    this.mapUrl,
    this.suggestedDish,
    this.sourceName,
    this.sourceUrl,
    this.sourceUpdatedAt,
    this.sourceSnapshotAt,
    this.sourceLinks = const [],
    this.indexedSearchText,
    this.mealTimes = const [],
    this.companions = const [],
  });
  final String id,
      name,
      description,
      imageUrl,
      address,
      province,
      area,
      country;
  final GeoPoint location;
  final String? suggestedDish;
  final String? sourceName, sourceUrl, sourceUpdatedAt, sourceSnapshotAt;
  final List<SourceLink> sourceLinks;
  final String? indexedSearchText;
  String get dishName => suggestedDish?.trim().isNotEmpty == true
      ? suggestedDish!.trim()
      : categories.isEmpty
      ? 'Món ngon'
      : categoryById(categories.first).name;
  double get latitude => location.latitude;
  double get longitude => location.longitude;
  final List<String> categories, tags;
  final int? priceMin, priceMax, reviewCount;
  final double? rating;
  final String? openingHours, phone, mapUrl;
  final List<MealTime> mealTimes;
  final List<Companion> companions;
  bool get isUsable =>
      id.trim().isNotEmpty && name.trim().isNotEmpty && location.isValid;

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    String requiredText(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Missing $key');
      }
      return value.trim();
    }

    int? nonNegative(Object? value) =>
        value is int && value >= 0 ? value : null;
    List<String> strings(String key) =>
        List.unmodifiable((json[key] as List? ?? []).whereType<String>());
    final point = GeoPoint.fromJson(json);
    if (point == null) throw const FormatException('Invalid coordinates');
    final rawRating = json['rating'];
    final rating =
        rawRating is num &&
            rawRating.isFinite &&
            rawRating >= 0 &&
            rawRating <= 5
        ? rawRating.toDouble()
        : null;
    final min = nonNegative(json['priceMin']);
    final max = nonNegative(json['priceMax']);
    if (min != null && max != null && min > max) {
      throw const FormatException('Invalid price range');
    }
    return Restaurant(
      id: requiredText('id'),
      suggestedDish: json['dishName'] as String?,
      sourceName: json['sourceName'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      sourceUpdatedAt: json['sourceUpdatedAt'] as String?,
      sourceSnapshotAt: json['sourceSnapshotAt'] as String?,
      sourceLinks: List.unmodifiable(
        (json['sourceLinks'] as List? ?? [])
            .map(SourceLink.fromJson)
            .whereType<SourceLink>(),
      ),
      indexedSearchText: normalizeSearch(
        [
          requiredText('name'),
          json['description'] as String? ?? '',
          ...strings('tags'),
          for (final id in strings('categories')) ...[
            categoryById(id).name,
            ...categoryById(id).keywords,
          ],
        ].join(' '),
      ),
      name: requiredText('name'),
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      location: point,
      address: requiredText('address'),
      province: requiredText('province'),
      area: requiredText('area'),
      country: json['country'] as String? ?? 'VN',
      categories: strings('categories'),
      tags: strings('tags'),
      priceMin: min,
      priceMax: max,
      rating: rating,
      reviewCount: nonNegative(json['reviewCount']),
      openingHours: json['openingHours'] as String?,
      phone: json['phone'] as String?,
      mapUrl: json['mapUrl'] as String?,
      mealTimes: List.unmodifiable(
        MealTime.values.where((m) => strings('mealTimes').contains(m.name)),
      ),
      companions: List.unmodifiable(
        Companion.values.where((c) => strings('companions').contains(c.name)),
      ),
    );
  }
}
