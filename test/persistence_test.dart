import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hom_nay_an_gi/core/services/local_store.dart';
import 'package:hom_nay_an_gi/core/utils/geo.dart';
import 'package:hom_nay_an_gi/features/recommendation/models/meal_preference.dart';
import 'package:hom_nay_an_gi/features/restaurants/models/restaurant.dart';

void main() {
  test(
    'settings survive storage reinitialization, history capped at 20',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);
      await store.write(
        LocalSettings(
          theme: ThemeMode.dark,
          favorites: {'a', 'b'},
          history: List.generate(30, (i) => '$i'),
          location: const SavedLocation('Khu demo', GeoPoint(21, 106)),
          preference: const MealPreference(
            budgetMin: 30000,
            budgetMax: 50000,
            maxDistance: 5,
            mealTime: MealTime.dinner,
            selectedCategories: {'rice'},
          ),
        ),
      );
      final restored = LocalStore(await SharedPreferences.getInstance()).read();
      expect(restored.favorites, {'a', 'b'});
      expect(restored.theme, ThemeMode.dark);
      expect(restored.history.length, 20);
      expect(restored.history.first, '0');
      expect(restored.location!.label, 'Khu demo');
      expect(restored.preference.budgetMax, 50000);
      expect(restored.preference.selectedCategories, {'rice'});
    },
  );
  test('precise GPS never serialized', () {
    const settings = LocalSettings(
      location: SavedLocation('GPS', GeoPoint(21, 106), isGps: true),
    );
    expect(settings.toJson()['location'], isNull);
  });
  test('queued writes preserve latest value', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    await Future.wait([
      store.write(const LocalSettings(favorites: {'old'})),
      store.write(const LocalSettings(favorites: {'new'})),
    ]);
    expect(store.read().favorites, {'new'});
  });
  test('corrupt storage produces actionable failure', () async {
    SharedPreferences.setMockInitialValues({LocalStore.key: 'broken json'});
    final store = LocalStore(await SharedPreferences.getInstance());
    expect(store.read, throwsA(isA<StorageFailure>()));
  });
  test('malformed prices, enums and distance recover safely', () {
    final settings = LocalSettings.fromJson(
      jsonDecode(
            '{"theme":"unknown","preference":'
            '{"budgetMin":100,"budgetMax":10,"maxDistance":-3,"mealTime":"oops"}}',
          )
          as Map<String, dynamic>,
    );
    expect(settings.theme, ThemeMode.system);
    expect(settings.preference.budgetMin, isNull);
    expect(settings.preference.maxDistance, 3);
    expect(settings.preference.mealTime, isNull);
  });
  test('restaurant validates untrusted data', () {
    final json = <String, dynamic>{
      'id': 'a',
      'name': 'A',
      'address': 'A',
      'province': 'A',
      'area': 'A',
      'latitude': 21,
      'longitude': 106,
      'rating': 8,
      'priceMin': -1,
    };
    expect(Restaurant.fromJson(json).rating, isNull);
    expect(
      Restaurant.fromJson({
        ...json,
        'dishName': 'Bún bò',
        'tags': ['Lãng mạn'],
      }).dishName,
      'Bún bò',
    );
    expect(Restaurant.fromJson(json).priceMin, isNull);
    expect(
      () => Restaurant.fromJson({...json, 'latitude': 100}),
      throwsFormatException,
    );
    expect(
      () =>
          Restaurant.fromJson({...json, 'priceMin': 50000, 'priceMax': 30000}),
      throwsFormatException,
    );
  });
}
