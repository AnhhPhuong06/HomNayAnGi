import 'package:hom_nay_an_gi/core/utils/geo.dart';
import 'package:hom_nay_an_gi/features/recommendation/models/meal_preference.dart';
import 'package:hom_nay_an_gi/features/restaurants/models/restaurant.dart';
import 'package:hom_nay_an_gi/features/restaurants/repositories/restaurant_repository.dart';

Restaurant venue({
  String id = 'a',
  GeoPoint location = const GeoPoint(21, 106),
  int? min = 30000,
  int? max = 50000,
  double? rating = 4.5,
  List<String> categories = const ['noodles'],
  List<MealTime> meals = const [MealTime.lunch],
}) => Restaurant(
  id: id,
  name: 'Phở Demo $id',
  suggestedDish: 'Phở bò',
  description: 'Minh họa',
  imageUrl: '',
  location: location,
  address: 'Địa chỉ demo',
  province: 'Tỉnh demo',
  area: 'Khu demo',
  categories: categories,
  tags: const ['Phở bò'],
  priceMin: min,
  priceMax: max,
  rating: rating,
  mealTimes: meals,
);

class TestRepository implements RestaurantRepository {
  TestRepository(this.restaurants, {this.fail = false, this.demo = true});
  final List<Restaurant> restaurants;
  final bool fail;
  final bool demo;
  @override
  bool get isDemo => demo;
  @override
  Future<List<Restaurant>> load() async {
    if (fail) throw const FormatException('test failure');
    return restaurants;
  }
}
