import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/recommendation/models/meal_preference.dart';
import '../features/recommendation/models/taste_preference.dart';
import '../features/auth/auth_repository.dart';
import '../features/recommendation/services/recommendation_service.dart';
import '../features/restaurants/models/restaurant.dart';
import '../features/restaurants/repositories/restaurant_repository.dart';
import '../features/restaurants/repositories/open_data_restaurant_repository.dart';
import 'services/local_store.dart';
import 'services/location_service.dart';
import 'theme/appearance.dart';

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
  String? _accountId;
  @override
  LocalSettings build() {
    final initial = ref.watch(initialSettingsProvider);
    final scoped =
        ref.watch(backendReadyProvider) &&
        ref.watch(authenticationRequiredProvider);
    _accountId = scoped
        ? ref.watch(memberProvider.select((s) => s.asData?.value?.id))
        : null;
    if (!scoped) return initial;
    if (_accountId == null) return LocalSettings(theme: initial.theme);
    try {
      return ref
          .read(localStoreProvider)
          .readAccount(_accountId!, theme: initial.theme);
    } on StorageFailure catch (e) {
      Future.microtask(() {
        if (ref.mounted) ref.read(storageErrorProvider.notifier).set(e.message);
      });
      return LocalSettings(theme: initial.theme);
    }
  }

  Future<void> _save(LocalSettings next) async {
    final account = _accountId;
    state = next;
    try {
      await ref.read(localStoreProvider).write(next, accountId: account);
      if (ref.mounted && account == _accountId) {
        ref.read(storageErrorProvider.notifier).set(null);
      }
    } catch (_) {
      if (ref.mounted && account == _accountId) {
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
  Future<void> setAppearance(Appearance value) =>
      _save(state.copyWith(appearance: value));
  Future<void> setPreference(MealPreference value) =>
      _save(state.copyWith(preference: value));
  Future<void> setTaste(TastePreference value) =>
      _save(state.copyWith(taste: value));
  Future<void> hideRestaurant(String id, bool hidden) {
    final ids = {...state.taste.hiddenRestaurantIds};
    hidden ? ids.add(id) : ids.remove(id);
    return setTaste(state.taste.copyWith(hiddenRestaurantIds: ids));
  }

  Future<void> restorePersonalData({
    required Set<String> favorites,
    required List<String> history,
    required MealPreference preference,
    required TastePreference taste,
  }) => _save(
    state.copyWith(
      favorites: favorites,
      history: history,
      preference: preference,
      taste: taste,
    ),
  );
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
  RecommendationState build() {
    if (ref.watch(backendReadyProvider)) {
      ref.watch(memberProvider.select((s) => s.asData?.value?.id));
    }
    return const RecommendationState();
  }

  Future<bool> choose() async {
    if (state.busy) return false;
    final previous = state.result;
    final account = ref.read(memberProvider).asData?.value?.id;
    state = RecommendationState(busy: true, result: previous);
    try {
      final restaurants = await ref.read(restaurantsProvider.future);
      if (!ref.mounted) return false;
      if (account != ref.read(memberProvider).asData?.value?.id) return false;
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
              dislikedCategories: settings.taste.dislikedCategories,
              hiddenRestaurantIds: settings.taste.hiddenRestaurantIds,
              avoidedKeywords: settings.taste.avoidedKeywords,
              avoidRecentCount: settings.taste.avoidRecentCount,
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
      if (account != ref.read(memberProvider).asData?.value?.id) return false;
      state = RecommendationState(result: result);
      return true;
    } catch (_) {
      if (ref.mounted &&
          account == ref.read(memberProvider).asData?.value?.id) {
        state = RecommendationState(
          result: previous,
          message: 'Không thể tải gợi ý. Vui lòng thử lại.',
        );
      }
      return false;
    }
  }
}
