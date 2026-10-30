import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hom_nay_an_gi/core/utils/geo.dart';
import 'package:hom_nay_an_gi/features/recommendation/models/meal_preference.dart';
import 'package:hom_nay_an_gi/features/recommendation/services/recommendation_service.dart';
import 'fixtures.dart';

void main() {
  late RecommendationService service;
  setUp(() => service = RecommendationService(random: Random(42)));
  const preference = MealPreference(mealTime: MealTime.lunch);
  const origin = GeoPoint(21, 106);
  test('Haversine: zero, symmetry, known 1 degree arc', () {
    expect(distanceKm(origin, origin), 0);
    expect(
      distanceKm(const GeoPoint(0, 0), const GeoPoint(0, 1)),
      closeTo(111.195, .01),
    );
    expect(
      distanceKm(origin, const GeoPoint(22, 107)),
      distanceKm(const GeoPoint(22, 107), origin),
    );
  });
  test('invalid and non-finite coordinates rejected', () {
    for (final p in [
      const GeoPoint(91, 0),
      const GeoPoint(0, -181),
      GeoPoint(double.nan, 0),
    ]) {
      expect(p.isValid, false);
      expect(() => distanceKm(p, origin), throwsArgumentError);
    }
    expect(GeoPoint.fromJson({'latitude': 100, 'longitude': 1}), isNull);
  });
  test(
    'antipodal distance remains finite',
    () => expect(
      distanceKm(const GeoPoint(0, 0), const GeoPoint(0, 180)),
      closeTo(20015.1, 1),
    ),
  );
  test('distance and price display concise values', () {
    expect(formatDistance(.85), '850 m');
    expect(formatDistance(2.438912), '2.4 km');
    expect(formatPrice(null, null), 'Chưa có giá');
    expect(formatPrice(35000, 50000), '35K–50K đ');
  });
  test('budget range overlap, exact boundaries and missing price', () {
    const p = MealPreference(budgetMin: 30000, budgetMax: 50000);
    expect(matchesBudget(venue(min: 50000, max: 80000), p), true);
    expect(matchesBudget(venue(min: 51000, max: 80000), p), false);
    expect(matchesBudget(venue(min: 10000, max: 29000), p), false);
    expect(matchesBudget(venue(min: null, max: null), p), false);
    expect(matchesBudget(venue(min: null, max: null), preference), true);
  });
  test('meal matching with unknown data receives neutral score', () {
    expect(mealTimeScore(venue(), MealTime.lunch), 1);
    expect(mealTimeScore(venue(), MealTime.late), 0);
    expect(mealTimeScore(venue(meals: []), MealTime.lunch), .5);
    expect(MealTime.at(DateTime(2026, 1, 1, 23)), MealTime.late);
  });
  test(
    'empty list returns no recommendation',
    () => expect(
      service.recommend(restaurants: [], preference: preference),
      isNull,
    ),
  );
  test('no location returns valid result with notice', () {
    final result = service.recommend(
      restaurants: [venue()],
      preference: preference,
    )!;
    expect(result.selected.restaurant.id, 'a');
    expect(result.notices.join(), contains('Chưa có vị trí'));
  });
  test(
    'single candidate selected even in history',
    () => expect(
      service
          .recommend(
            restaurants: [venue()],
            preference: preference,
            history: ['a'],
          )!
          .selected
          .restaurant
          .id,
      'a',
    ),
  );
  test('radius relaxation from 1 to 3km disclosed', () {
    final result = service.recommend(
      restaurants: [venue(location: const GeoPoint(21.02, 106))],
      preference: const MealPreference(maxDistance: 1),
      location: origin,
    )!;
    expect(result.notices.join(), contains('3 km'));
  });
  test(
    'all restaurants far away returns no result instead of unrelated city',
    () => expect(
      service.recommend(
        restaurants: [venue(location: const GeoPoint(10, 106))],
        preference: preference,
        location: origin,
      ),
      isNull,
    ),
  );
  test('budget relaxation is transparent', () {
    final result = service.recommend(
      restaurants: [venue(min: 100000, max: 200000)],
      preference: const MealPreference(budgetMax: 30000),
      location: origin,
    )!;
    expect(result.notices.join(), contains('ngân sách'));
  });
  test('category relaxation disclosed', () {
    final result = service.recommend(
      restaurants: [venue()],
      preference: const MealPreference(selectedCategories: {'rice'}),
    )!;
    expect(result.notices.join(), contains('kiểu món'));
  });
  test(
    'explicit dislikes never relaxed',
    () => expect(
      service.recommend(
        restaurants: [venue()],
        preference: preference,
        user: const UserPreference(dislikedCategories: {'noodles'}),
      ),
      isNull,
    ),
  );
  test('missing price and rating produce finite score', () {
    final result = service.recommend(
      restaurants: [venue(min: null, max: null, rating: null)],
      preference: preference,
    )!;
    expect(result.selected.score.isFinite, true);
    expect(result.selected.score, inInclusiveRange(0, 1));
  });
  test(
    'invalid coordinates and blank ids excluded',
    () => expect(
      service.recommend(
        restaurants: [
          venue(location: const GeoPoint(99, 0)),
          venue(id: ''),
        ],
        preference: preference,
      ),
      isNull,
    ),
  );
  test('duplicate ids do not multiply candidates', () {
    final result = service.recommend(
      restaurants: [venue(), venue()],
      preference: preference,
    )!;
    expect(result.nearby.length, 1);
  });
  test(
    'history containing every candidate still returns an option without immediate repeat',
    () {
      final result = service.recommend(
        restaurants: [
          venue(),
          venue(id: 'b'),
        ],
        preference: preference,
        history: ['a', 'b'],
      )!;
      expect(result.selected.restaurant.id, 'b');
    },
  );
  test('unknown prices do not silently expand the search radius', () {
    final result = service.recommend(
      restaurants: [venue(min: null, max: null)],
      location: origin,
      preference: const MealPreference(budgetMax: 30000, maxDistance: 1),
    )!;
    expect(result.notices.join(), contains('chưa có giá'));
    expect(result.notices.join(), isNot(contains('mở rộng lên')));
  });
  test('weighted sampling favors higher score and explores alternatives', () {
    final pool = [
      ScoredRestaurant(venue(), .9),
      ScoredRestaurant(venue(id: 'b'), .1),
    ];
    var count = 0;
    for (var i = 0; i < 2000; i++) {
      if (service.weightedPick(pool).restaurant.id == 'a') count++;
    }
    expect(count, inInclusiveRange(1700, 1900));
  });
  test('weighted sampler handles zero weights and rejects invalid input', () {
    expect(
      service.weightedPick([ScoredRestaurant(venue(), 0)]).restaurant.id,
      'a',
    );
    expect(() => service.weightedPick([]), throwsArgumentError);
    expect(
      () => service.weightedPick([ScoredRestaurant(venue(), double.nan)]),
      throwsArgumentError,
    );
  });
  test(
    'invalid config rejected',
    () => expect(
      () => RecommendationService(
        config: const RecommendationConfig(distanceWeight: 2),
      ),
      throwsArgumentError,
    ),
  );
  test(
    'Vietnamese search normalization',
    () => expect(
      normalizeSearch('  BÚN BÒ HUẾ ĐẶC BIỆT  '),
      'bun bo hue dac biet',
    ),
  );
}
