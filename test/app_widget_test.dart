import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hom_nay_an_gi/app.dart';
import 'package:hom_nay_an_gi/core/providers.dart';
import 'package:hom_nay_an_gi/core/services/local_store.dart';
import 'package:hom_nay_an_gi/core/services/location_service.dart';
import 'package:hom_nay_an_gi/core/utils/geo.dart';
import 'package:hom_nay_an_gi/features/restaurants/repositories/restaurant_repository.dart';
import 'fixtures.dart';
import 'package:hom_nay_an_gi/features/auth/auth_repository.dart';

class DeniedLocation extends LocationService {
  int calls = 0;
  @override
  Future<GeoPoint> current() async {
    calls++;
    throw const LocationFailure(LocationIssue.denied);
  }
}

Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  RestaurantRepository? repository,
  LocalSettings settings = const LocalSettings(),
  LocationService? location,
  double textScale = 1,
}) async {
  SharedPreferences.setMockInitialValues({});
  final store = LocalStore(await SharedPreferences.getInstance());
  final container = ProviderContainer(
    overrides: [
      authenticationRequiredProvider.overrideWithValue(false),
      localStoreProvider.overrideWithValue(store),
      initialSettingsProvider.overrideWithValue(settings),
      repositoryProvider.overrideWithValue(
        repository ?? TestRepository([venue()]),
      ),
      if (location != null) locationServiceProvider.overrideWithValue(location),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const MealApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('home renders and GPS is never requested on startup', (
    tester,
  ) async {
    final gps = DeniedLocation();
    await pumpApp(tester, location: gps);
    expect(find.text('Hôm Nay Ăn Gì?'), findsOneWidget);
    expect(find.text('CHỌN GIÚP TÔI'), findsOneWidget);
    expect(gps.calls, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('filter changes are staged until Apply and can be cleared', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    await tester.tap(find.byTooltip('Bộ lọc').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('50.000–100.000đ'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).preference.budgetMin, isNull);
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).preference.budgetMin, 50000);
    await tester.tap(find.byTooltip('Bộ lọc').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa bộ lọc'));
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).preference.budgetMin, isNull);
  });
  testWidgets('favorites toggle persists and empty state works', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    await tester.tap(find.text('Khám phá').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Lưu yêu thích').first);
    await tester.pumpAndSettle();
    expect(container.read(localStoreProvider).read().favorites, {'a'});
    await tester.tap(find.text('Yêu thích').last);
    await tester.pumpAndSettle();
    expect(find.text('Phở Demo a'), findsOneWidget);
    await tester.tap(find.byTooltip('Bỏ yêu thích').first);
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa lưu quán nào.'), findsOneWidget);
    expect(container.read(localStoreProvider).read().favorites, isEmpty);
  });
  testWidgets('empty and error data expose recovery actions', (tester) async {
    await pumpApp(tester, repository: TestRepository([], fail: true));
    await tester.tap(find.text('Khám phá').last);
    await tester.pumpAndSettle();
    expect(find.text('Không thể tải danh sách quán.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('search ignores Vietnamese diacritics', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Khám phá').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'pho bo');
    await tester.pumpAndSettle();
    expect(find.text('Phở Demo a'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'not found');
    await tester.pumpAndSettle();
    expect(find.text('Chưa tìm thấy quán phù hợp.'), findsOneWidget);
  });
  testWidgets('recommendation result, detail and persisted history', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    await tester.tap(find.text('CHỌN GIÚP TÔI'));
    await tester.pumpAndSettle();
    expect(find.text('Gợi ý hôm nay'), findsOneWidget);
    expect(container.read(localStoreProvider).read().history, ['a']);
    await tester.ensureVisible(find.text('Phở Demo a'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phở Demo a'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết quán'), findsOneWidget);
    expect(find.text('Địa chỉ demo'), findsOneWidget);
  });
  testWidgets('GPS denied preserves manual fallback', (tester) async {
    final gps = DeniedLocation();
    final container = await pumpApp(tester, location: gps);
    await tester.tap(find.text('Chọn khu vực của bạn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dùng vị trí của tôi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bạn chưa cấp quyền vị trí'), findsOneWidget);
    await tester.ensureVisible(find.text('Tỉnh demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tỉnh demo'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Khu demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khu demo'));
    await tester.pumpAndSettle();
    expect(
      container.read(settingsProvider).location!.label,
      'Khu demo, Tỉnh demo',
    );
    expect(gps.calls, 1);
  });
  testWidgets('dark mode changes and persists', (tester) async {
    final container = await pumpApp(tester);
    await tester.tap(find.text('Cài đặt').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).theme, ThemeMode.dark);
    expect(container.read(localStoreProvider).read().theme, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text('Giao diện'))).brightness,
      Brightness.dark,
    );
  });
  testWidgets('large font home and filters do not overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Bộ lọc').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('real bundled demo fixture is usable offline', (tester) async {
    final container = await pumpApp(
      tester,
      repository: const MockRestaurantRepository(),
    );
    final restaurants = await container.read(restaurantsProvider.future);
    expect(restaurants.length, 24);
    expect(restaurants.every((r) => r.imageUrl.startsWith('assets/')), true);
    expect(restaurants.map((r) => r.id).toSet().length, 24);
  });
  testWidgets('open data attribution and honest TikTok search are visible', (
    tester,
  ) async {
    await pumpApp(tester, repository: TestRepository([venue()], demo: false));
    await tester.tap(find.text('Khám phá').last);
    await tester.pumpAndSettle();
    expect(find.text('© OpenStreetMap contributors · ODbL'), findsOneWidget);
    await tester.ensureVisible(find.text('Phở Demo a'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phở Demo a'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Tìm video trên TikTok'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('chưa phải video review đã đối chiếu'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'real catalog asks for an area before suggesting a distant city',
    (tester) async {
      final container = await pumpApp(
        tester,
        repository: TestRepository([venue()], demo: false),
      );
      await tester.tap(find.text('CHỌN GIÚP TÔI'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn muốn ăn ở đâu?'), findsOneWidget);
      expect(container.read(settingsProvider).history, isEmpty);
      await tester.tap(find.byTooltip('Đóng chọn khu vực'));
      await tester.pumpAndSettle();
      expect(find.text('CHỌN GIÚP TÔI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
