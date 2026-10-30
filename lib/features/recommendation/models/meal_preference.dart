enum MealTime {
  breakfast('Sáng'),
  lunch('Trưa'),
  dinner('Tối'),
  late('Đêm');

  const MealTime(this.label);
  final String label;
  static MealTime at(DateTime time) => switch (time.hour) {
    >= 5 && < 11 => breakfast,
    >= 11 && < 15 => lunch,
    >= 15 && < 22 => dinner,
    _ => late,
  };
}

enum Companion {
  alone('Một mình'),
  partner('Người yêu'),
  friends('Bạn bè'),
  family('Gia đình');

  const Companion(this.label);
  final String label;
}

class Budget {
  const Budget(this.label, this.min, this.max);
  final String label;
  final int? min;
  final int? max;
}

const budgets = [
  Budget('< 30.000đ', null, 29999),
  Budget('30.000–50.000đ', 30000, 50000),
  Budget('50.000–100.000đ', 50000, 100000),
  Budget('100.000–200.000đ', 100000, 200000),
  Budget('> 200.000đ', 200001, null),
];
const distanceOptions = [1.0, 3.0, 5.0, 10.0];

class MealPreference {
  const MealPreference({
    this.budgetMin,
    this.budgetMax,
    this.maxDistance = 3,
    this.mealTime,
    this.companion,
    this.selectedCategories = const {},
  });
  final int? budgetMin;
  final int? budgetMax;
  final double maxDistance;
  final MealTime? mealTime;
  final Companion? companion;
  final Set<String> selectedCategories;

  MealPreference withCategories(Set<String> value) => MealPreference(
    budgetMin: budgetMin,
    budgetMax: budgetMax,
    maxDistance: maxDistance,
    mealTime: mealTime,
    companion: companion,
    selectedCategories: Set.unmodifiable(value),
  );
  Map<String, Object?> toJson() => {
    'budgetMin': budgetMin,
    'budgetMax': budgetMax,
    'maxDistance': maxDistance,
    'mealTime': mealTime?.name,
    'companion': companion?.name,
    'selectedCategories': selectedCategories.toList(),
  };
  factory MealPreference.fromJson(Map<String, dynamic> json) {
    int? price(Object? v) => v is int && v >= 0 ? v : null;
    var min = price(json['budgetMin']);
    var max = price(json['budgetMax']);
    if (min != null && max != null && min > max) {
      min = null;
      max = null;
    }
    final distance = json['maxDistance'];
    return MealPreference(
      budgetMin: min,
      budgetMax: max,
      maxDistance:
          distance is num && distanceOptions.contains(distance.toDouble())
          ? distance.toDouble()
          : 3,
      mealTime: MealTime.values
          .where((m) => m.name == json['mealTime'])
          .firstOrNull,
      companion: Companion.values
          .where((c) => c.name == json['companion'])
          .firstOrNull,
      selectedCategories: Set.unmodifiable(
        (json['selectedCategories'] as List? ?? []).whereType<String>(),
      ),
    );
  }
}

class UserPreference {
  const UserPreference({
    this.favoriteCategories = const {},
    this.dislikedCategories = const {},
    this.favoriteRestaurantIds = const {},
  });
  final Set<String> favoriteCategories;
  final Set<String> dislikedCategories;
  final Set<String> favoriteRestaurantIds;
}
