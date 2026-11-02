import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hom_nay_an_gi/core/network/api_client.dart';
import 'package:hom_nay_an_gi/core/providers.dart';
import 'package:hom_nay_an_gi/core/services/local_store.dart';
import 'package:hom_nay_an_gi/features/restaurants/models/restaurant.dart';
import 'package:hom_nay_an_gi/features/restaurants/repositories/restaurant_repository.dart';
import 'fixtures.dart';

class DelayedRepository implements RestaurantRepository {
  final completion = Completer<List<Restaurant>>();
  int calls = 0;
  @override
  bool get isDemo => true;
  @override
  Future<List<Restaurant>> load() {
    calls++;
    return completion.future;
  }
}

class UnwritableStore extends LocalStore {
  UnwritableStore(super.preferences);
  bool fail = true;
  @override
  Future<void> write(LocalSettings settings, {String? accountId}) => fail
      ? Future.error(const StorageFailure('disk full'))
      : super.write(settings, accountId: accountId);
}

void main() {
  test(
    'double recommendation shares a single load and keeps previous result while busy',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = DelayedRepository();
      final container = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(
            LocalStore(await SharedPreferences.getInstance()),
          ),
          repositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(recommendationProvider.notifier);
      final first = controller.choose();
      expect(await controller.choose(), false);
      expect(repository.calls, 1);
      repository.completion.complete([venue()]);
      expect(await first, true);
      final next = controller.choose();
      expect(container.read(recommendationProvider).busy, true);
      expect(container.read(recommendationProvider).result, isNotNull);
      expect(await next, true);
      expect(repository.calls, 1);
    },
  );
  test('storage errors preserve session state and can be retried', () async {
    SharedPreferences.setMockInitialValues({});
    final store = UnwritableStore(await SharedPreferences.getInstance());
    final container = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.notifier).toggleFavorite('a');
    expect(container.read(settingsProvider).favorites, {'a'});
    expect(container.read(storageErrorProvider), isNotNull);
    store.fail = false;
    await container.read(settingsProvider.notifier).retrySave();
    expect(store.read().favorites, {'a'});
    expect(container.read(storageErrorProvider), isNull);
  });
  test(
    'shared preference value with wrong storage type gives recoverable error',
    () async {
      SharedPreferences.setMockInitialValues({LocalStore.key: 123});
      final store = LocalStore(await SharedPreferences.getInstance());
      expect(store.read, throwsA(isA<StorageFailure>()));
    },
  );
  test('API client rejects unsafe endpoints and normalizes timeout', () {
    expect(
      () => createApiClient(Uri.parse('http://example.com')),
      throwsArgumentError,
    );
    expect(
      () => createApiClient(Uri.parse('https://user:password@example.com')),
      throwsArgumentError,
    );
    final dio = createApiClient(Uri.parse('https://example.com'));
    expect(dio.options.connectTimeout, const Duration(seconds: 10));
    final failure = NetworkFailure.fromDio(
      DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.receiveTimeout,
      ),
    );
    expect(failure.message, contains('Kết nối quá chậm'));
    dio.close();
  });
}
