import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/recommendation/models/meal_preference.dart';
import '../features/recommendation/services/recommendation_service.dart';
import '../features/restaurants/models/restaurant.dart';
import '../features/restaurants/repositories/restaurant_repository.dart';
import '../features/restaurants/repositories/open_data_restaurant_repository.dart';
import 'services/local_store.dart';
import 'services/location_service.dart';

final localStoreProvider = Provider<LocalStore>(
  (ref) => throw StateError('Initialize storage at startup'),
);
final initialSettingsProvider = Provider<LocalSettings>(
  (ref) => const LocalSettings(),
);
final startupNoticeProvider = Provider<String?>((ref) => null);
final repositoryProvider = Provider<RestaurantRepository>(
  (ref) =>
      const String.fromEnvironment('RESTAURANT_DATA', defaultValue: 'open') ==
          'demo'
      ? const MockRestaurantRepository()
      : const OpenDataRestaurantRepository(),
);
final restaurantsProvider = FutureProvider<List<Restaurant>>(
  (ref) => ref.watch(repositoryProvider).load(),
  retry: (retryCount, error) => null,
);
final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);
final recommendationServiceProvider = Provider<RecommendationService>(
  (ref) => RecommendationService(),
);

final settingsProvider = NotifierProvider<SettingsController, LocalSettings>(
  SettingsController.new,
);
final storageErrorProvider = NotifierProvider<StorageError, String?>(
  StorageError.new,
);

class StorageError extends Notifier<String?> {
  @override
  String? build() => ref.watch(startupNoticeProvider);
  void set(String? message) => state = message;
}

class SettingsController extends Notifier<LocalSettings> {
  @override
  LocalSettings build() => ref.watch(initialSettingsProvider);
  Future<void> _save(LocalSettings next) async {
    state = next;
    try {
      await ref.read(localStoreProvider).write(next);
      if (ref.mounted) ref.read(storageErrorProvider.notifier).set(null);
    } catch (_) {
      if (ref.mounted) {
        ref
            .read(storageErrorProvider.notifier)
            .set(
              'Thay đổi đang dùng trong phiên này nhưng chưa lưu được. Hãy thử lưu lại.',
            );
      }
    }
  }

  Future<void> toggleFavorite(String id) {
    final next = {...state.favorites};
    if (!next.remove(id)) next.add(id);
    return _save(state.copyWith(favorites: next));
  }

  Future<void> setTheme(ThemeMode mode) => _save(state.copyWith(theme: mode));
  Future<void> setPreference(MealPreference value) =>
      _save(state.copyWith(preference: value));
  Future<void> setLocation(SavedLocation value) =>
      _save(state.copyWith(location: value));
  Future<void> clearLocation() => _save(state.copyWith(clearLocation: true));
  Future<void> retrySave() => _save(state);
  Future<void> remember(String id) =>
      _save(state.copyWith(history: [id, ...state.history].take(20).toList()));
}

class RecommendationState {
  const RecommendationState({this.busy = false, this.result, this.message});
  final bool busy;
  final RecommendationResult? result;
  final String? message;
}

final recommendationProvider =
    NotifierProvider<RecommendationController, RecommendationState>(
      RecommendationController.new,
    );

class RecommendationController extends Notifier<RecommendationState> {
  @override
  RecommendationState build() => const RecommendationState();
  Future<bool> choose() async {
    if (state.busy) return false;
    final previous = state.result;
    state = RecommendationState(busy: true, result: previous);
    try {
      final restaurants = await ref.read(restaurantsProvider.future);
      if (!ref.mounted) return false;
      final settings = ref.read(settingsProvider);
      if (!ref.read(repositoryProvider).isDemo && settings.location == null) {
        state = RecommendationState(
          result: previous,
          message:
              'Hãy chọn khu vực hoặc dùng GPS để tìm quán phù hợp gần bạn.',
        );
        return false;
      }
      final favoriteCategories = restaurants
          .where((r) => settings.favorites.contains(r.id))
          .expand((r) => r.categories)
          .toSet();
      final result = ref
          .read(recommendationServiceProvider)
          .recommend(
            restaurants: restaurants,
            preference: settings.preference,
            location: settings.location?.point,
            history: settings.history,
            user: UserPreference(
              favoriteRestaurantIds: settings.favorites,
              favoriteCategories: favoriteCategories,
            ),
          );
      if (result == null) {
        state = RecommendationState(
          result: previous,
          message:
              'Chưa có quán phù hợp quanh khu vực này. Thử đổi khu vực hoặc bộ lọc.',
        );
        return false;
      }
      await ref
          .read(settingsProvider.notifier)
          .remember(result.selected.restaurant.id);
      if (!ref.mounted) return false;
      state = RecommendationState(result: result);
      return true;
    } catch (_) {
      if (ref.mounted) {
        state = RecommendationState(
          result: previous,
          message: 'Không thể tải gợi ý. Vui lòng thử lại.',
        );
      }
      return false;
    }
  }
}
