import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/restaurant.dart';

abstract interface class RestaurantRepository {
  Future<List<Restaurant>> load();
  bool get isDemo;
}

class MockRestaurantRepository implements RestaurantRepository {
  const MockRestaurantRepository();
  @override
  bool get isDemo => true;
  @override
  Future<List<Restaurant>> load() async {
    final source = await rootBundle.loadString('assets/data/restaurants.json');
    final json = jsonDecode(source);
    if (json is! List) {
      throw const FormatException('Invalid restaurant dataset');
    }
    final unique = <String, Restaurant>{};
    for (final item in json) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid restaurant');
      }
      final restaurant = Restaurant.fromJson(item);
      unique.putIfAbsent(restaurant.id, () => restaurant);
    }
    return List.unmodifiable(unique.values);
  }
}
