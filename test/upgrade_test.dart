import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hom_nay_an_gi/app.dart';
import 'package:hom_nay_an_gi/core/providers.dart';
import 'package:hom_nay_an_gi/core/router/app_router.dart';
import 'package:hom_nay_an_gi/core/services/local_store.dart';
import 'package:hom_nay_an_gi/core/utils/geo.dart';
import 'package:hom_nay_an_gi/features/auth/auth_repository.dart';
import 'package:hom_nay_an_gi/features/auth/account_action_lock.dart';
import 'package:hom_nay_an_gi/features/blog/blog_repository.dart';
import 'package:hom_nay_an_gi/features/discover/widgets/restaurant_map.dart';
import 'package:hom_nay_an_gi/features/recommendation/models/meal_preference.dart';
import 'package:hom_nay_an_gi/features/recommendation/models/taste_preference.dart';
import 'package:hom_nay_an_gi/features/recommendation/services/recommendation_service.dart';
import 'package:hom_nay_an_gi/features/restaurants/services/restaurant_queries.dart';
import 'package:hom_nay_an_gi/features/settings/personal_backup.dart';
import 'package:hom_nay_an_gi/features/settings/screens/taste_sheet.dart';
import 'fixtures.dart';
import 'support/community_fakes.dart';

class DelayedBackup implements PersonalBackupRepository {
  final pending = Completer<PersonalBackup?>();
  int saves = 0;
  @override
  Future<PersonalBackup?> load(String uid) => pending.future;
  @override
  Future<void> save(
    String uid,
    PersonalBackup backup, {
    required int expectedRevision,
  }) async {
    saves++;
  }
}

class GatedStore extends LocalStore {
  GatedStore(super.preferences);
  final started = Completer<void>();
  final finish = Completer<void>();
  @override
  Future<void> write(LocalSettings settings, {String? accountId}) async {
    if (!started.isCompleted) started.complete();
    await finish.future;
    await super.write(settings, accountId: accountId);
  }
}

void main() {
  test(
    'corrupt account storage is recoverable rather than a raw type error',
    () async {
      SharedPreferences.setMockInitialValues({
        LocalStore.accountKey('alice'): 42,
      });
      final store = LocalStore(await SharedPreferences.getInstance());
      expect(() => store.readAccount('alice'), throwsA(isA<StorageFailure>()));
    },
  );

  test(
    'a recommendation finishing persistence after sign-out cannot leak to the next account',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = GatedStore(await SharedPreferences.getInstance());
      final auth = MemoryAuth(
        current: const Member(id: 'alice', name: 'An'),
      );
      final c = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          backendReadyProvider.overrideWithValue(true),
          authRepositoryProvider.overrideWithValue(auth),
          repositoryProvider.overrideWithValue(TestRepository([venue()])),
        ],
      );
      final subscription = c.listen(recommendationProvider, (_, _) {});
      addTearDown(() async {
        subscription.close();
        c.dispose();
        await auth.changes.close();
      });
      await c.read(memberProvider.future);
      final choosing = c.read(recommendationProvider.notifier).choose();
      await store.started.future;
      auth.setMember(const Member(id: 'bob', name: 'Bình'));
      await Future<void>.delayed(Duration.zero);
      store.finish.complete();
      expect(await choosing, false);
      expect(c.read(recommendationProvider).result, isNull);
      expect(c.read(settingsProvider).history, isEmpty);
      expect(store.readAccount('bob').history, isEmpty);
    },
  );

  testWidgets('a stale taste editor cannot save into another member profile', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final auth = MemoryAuth(
      current: const Member(id: 'alice', name: 'An'),
    );
    final c = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(
          LocalStore(await SharedPreferences.getInstance()),
        ),
        backendReadyProvider.overrideWithValue(true),
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );
    final subscription = c.listen(settingsProvider, (_, _) {});
    addTearDown(() async {
      subscription.close();
      c.dispose();
      await auth.changes.close();
    });
    await c.read(memberProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showTastePreferences(context),
                child: const Text('Mở khẩu vị'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở khẩu vị'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🍜 Bún / Phở'));
    auth.setMember(const Member(id: 'bob', name: 'Bình'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu khẩu vị'));
    await tester.pumpAndSettle();
    expect(c.read(settingsProvider).taste.dislikedCategories, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account actions remain disabled during personal data mutation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final auth = MemoryAuth(
      current: const Member(id: 'alice', name: 'An'),
    );
    final blog = MemoryBlog();
    final c = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(
          LocalStore(await SharedPreferences.getInstance()),
        ),
        backendReadyProvider.overrideWithValue(true),
        authRepositoryProvider.overrideWithValue(auth),
        blogRepositoryProvider.overrideWithValue(blog),
        repositoryProvider.overrideWithValue(TestRepository([venue()])),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await auth.changes.close();
      await blog.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const MealApp()),
    );
    await tester.pumpAndSettle();
    c.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();
    c.read(accountActionLockProvider.notifier).begin();
    await tester.pump();
    final logout = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Đăng xuất'),
    );
    expect(logout.onPressed, isNull);
    final delete = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Xóa tài khoản'),
    );
    expect(delete.onPressed, isNull);
    c.read(accountActionLockProvider.notifier).release();
    await tester.pump();
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Đăng xuất'))
          .onPressed,
      isNotNull,
    );
  });
  test(
    'old settings migrate with neutral taste; new taste survives persistence',
    () {
      final old = LocalSettings.fromJson({
        'favorites': ['a'],
      });
      expect(old.taste.dislikedCategories, isEmpty);
      final next = old.copyWith(
        taste: const TastePreference(
          dislikedCategories: {'grill'},
          avoidedKeywords: ['ốc'],
          avoidRecentCount: 10,
        ),
      );
      final restored = LocalSettings.fromJson(
        Map<String, dynamic>.from(next.toJson()),
      );
      expect(restored.favorites, {'a'});
      expect(restored.taste.dislikedCategories, {'grill'});
      expect(restored.taste.avoidedKeywords, ['ốc']);
      expect(restored.taste.avoidRecentCount, 10);
    },
  );

  test(
    'hidden venues and disliked categories stay excluded when filters relax',
    () {
      final result = RecommendationService(random: Random(4)).recommend(
        restaurants: [
          venue(id: 'hidden'),
          venue(id: 'disliked', categories: ['rice']),
          venue(id: 'allowed', categories: ['cafe']),
        ],
        preference: const MealPreference(
          selectedCategories: {'rice'},
          budgetMax: 100,
        ),
        user: const UserPreference(
          hiddenRestaurantIds: {'hidden'},
          dislikedCategories: {'rice'},
        ),
      );
      expect(result!.selected.restaurant.id, 'allowed');
      expect(result.nearby.map((r) => r.id), ['allowed']);
    },
  );

  test(
    'keyword avoidance is accent-insensitive and also applies to discovery',
    () {
      final restaurants = [venue()];
      const user = UserPreference(avoidedKeywords: ['pho bo']);
      expect(
        RecommendationService().recommend(
          restaurants: restaurants,
          preference: const MealPreference(),
          user: user,
        ),
        isNull,
      );
      expect(queryRestaurants(restaurants, user: user), isEmpty);
    },
  );

  test(
    'recent window selects unseen candidates and honestly relaxes if exhausted',
    () {
      final restaurants = [venue(id: 'a'), venue(id: 'b'), venue(id: 'c')];
      final service = RecommendationService(random: Random(6));
      final fresh = service.recommend(
        restaurants: restaurants,
        preference: const MealPreference(),
        history: ['a', 'b'],
      )!;
      expect(fresh.selected.restaurant.id, 'c');
      final repeated = service.recommend(
        restaurants: restaurants,
        preference: const MealPreference(),
        history: ['a', 'b', 'c'],
      )!;
      expect(repeated.selected.restaurant.id, isNot('a'));
      expect(repeated.notices.join(), contains('lịch sử gần đây'));
    },
  );

  test('cloud backup excludes GPS, manual area and device theme', () {
    for (final gps in [false, true]) {
      final local = LocalSettings(
        theme: ThemeMode.dark,
        favorites: {'a'},
        history: ['b'],
        location: SavedLocation(
          'Private area',
          const GeoPoint(21, 106),
          isGps: gps,
        ),
        taste: const TastePreference(hiddenRestaurantIds: {'c'}),
      );
      final payload = PersonalBackup.fromSettings(local).toData();
      final json = jsonEncode(payload);
      for (final secret in [
        'latitude',
        'longitude',
        'location',
        'Private area',
        'theme',
      ]) {
        expect(json, isNot(contains(secret)));
      }
      final restored = PersonalBackup.fromData(
        Map<String, dynamic>.from(payload),
      );
      expect(restored.favorites, {'a'});
      expect(restored.taste.hiddenRestaurantIds, {'c'});
    }
  });

  test(
    'oversized or unexpected backup fields are rejected before applying',
    () {
      final backup = PersonalBackup.fromSettings(const LocalSettings());
      final data = Map<String, dynamic>.from(backup.toData());
      expect(
        () => PersonalBackup.fromData({
          ...data,
          'location': {'latitude': 21},
        }),
        throwsFormatException,
      );
      expect(
        () => PersonalBackup.fromData({
          ...data,
          'favorites': [42],
        }),
        throwsFormatException,
      );
      expect(
        () =>
            PersonalBackup.fromData({...data, 'history': List.filled(21, 'a')}),
        throwsFormatException,
      );
    },
  );

  test(
    'local account storage never inherits another account or the legacy profile',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = LocalStore(await SharedPreferences.getInstance());
      await store.write(const LocalSettings(favorites: {'legacy'}));
      await store.write(
        const LocalSettings(
          favorites: {'alice'},
          taste: TastePreference(hiddenRestaurantIds: {'hidden'}),
        ),
        accountId: 'alice',
      );
      expect(store.readAccount('bob').favorites, isEmpty);
      expect(store.readAccount('alice').favorites, {'alice'});
      await store.removeAccount('alice');
      expect(store.readAccount('alice').favorites, isEmpty);
      expect(store.read().favorites, {'legacy'});
    },
  );

  test(
    'switching accounts clears and restores only their own settings',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = LocalStore(await SharedPreferences.getInstance());
      final auth = MemoryAuth(
        current: const Member(id: 'alice', name: 'An'),
      );
      final c = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          backendReadyProvider.overrideWithValue(true),
          authRepositoryProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await auth.changes.close();
      });
      final subscription = c.listen(settingsProvider, (_, _) {});
      addTearDown(subscription.close);
      await c.read(memberProvider.future);
      await c.read(settingsProvider.notifier).toggleFavorite('alice-only');
      auth.setMember(const Member(id: 'bob', name: 'Bình'));
      await Future<void>.delayed(Duration.zero);
      expect(c.read(settingsProvider).favorites, isEmpty);
      await c.read(settingsProvider.notifier).toggleFavorite('bob-only');
      auth.setMember(const Member(id: 'alice', name: 'An'));
      await Future<void>.delayed(Duration.zero);
      expect(c.read(settingsProvider).favorites, {'alice-only'});
      auth.setMember(null);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(settingsProvider).favorites, isEmpty);
    },
  );

  testWidgets(
    'taste sheet edits are a draft until Save; cancel discards them',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(
            LocalStore(await SharedPreferences.getInstance()),
          ),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showTastePreferences(context),
                  child: const Text('Khẩu vị'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Khẩu vị'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🍜 Bún / Phở'));
      await tester.pumpAndSettle();
      expect(c.read(settingsProvider).taste.dislikedCategories, isEmpty);
      await tester.tap(find.byTooltip('Đóng khẩu vị'));
      await tester.pumpAndSettle();
      expect(c.read(settingsProvider).taste.dislikedCategories, isEmpty);
      await tester.tap(find.text('Khẩu vị'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🍜 Bún / Phở'));
      await tester.tap(find.text('Lưu khẩu vị'));
      await tester.pumpAndSettle();
      expect(c.read(settingsProvider).taste.dislikedCategories, {'noodles'});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('offline map shows actual venue markers and selectable detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapNetworkEnabledProvider.overrideWithValue(false),
          localStoreProvider.overrideWithValue(
            LocalStore(await SharedPreferences.getInstance()),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RestaurantMap(
                restaurants: [venue()],
                origin: const GeoPoint(21, 106),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa tải được nền bản đồ'), findsOneWidget);
    await tester.tap(find.byTooltip('Phở Demo a'));
    await tester.pumpAndSettle();
    expect(find.text('Phở Demo a'), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'restoration finishing after account switch cannot overwrite the next member',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final auth = MemoryAuth(
        current: const Member(id: 'alice', name: 'An'),
      );
      final blog = MemoryBlog();
      final backup = DelayedBackup();
      final c = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(
            LocalStore(await SharedPreferences.getInstance()),
          ),
          backendReadyProvider.overrideWithValue(true),
          authRepositoryProvider.overrideWithValue(auth),
          blogRepositoryProvider.overrideWithValue(blog),
          personalBackupRepositoryProvider.overrideWithValue(backup),
          repositoryProvider.overrideWithValue(TestRepository([venue()])),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await auth.changes.close();
        await blog.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const MealApp()),
      );
      await tester.pumpAndSettle();
      c.read(routerProvider).go('/settings');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Khôi phục từ tài khoản'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Khôi phục từ tài khoản'));
      await tester.pump();
      auth.setMember(const Member(id: 'bob', name: 'Bình'));
      await tester.pumpAndSettle();
      backup.pending.complete(
        PersonalBackup.fromSettings(
          const LocalSettings(favorites: {'alice-only'}),
        ),
      );
      await tester.pumpAndSettle();
      expect(c.read(settingsProvider).favorites, isEmpty);
      expect(find.text('Khôi phục từ tài khoản?'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
