import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hom_nay_an_gi/app.dart';
import 'package:hom_nay_an_gi/core/providers.dart';
import 'package:hom_nay_an_gi/core/router/app_router.dart';
import 'package:hom_nay_an_gi/core/services/local_store.dart';
import 'package:hom_nay_an_gi/core/services/maps_service.dart';
import 'package:hom_nay_an_gi/core/theme/appearance.dart';
import 'package:hom_nay_an_gi/core/utils/geo.dart';
import 'package:hom_nay_an_gi/core/widgets/adaptive_cards.dart';
import 'package:hom_nay_an_gi/features/auth/auth_repository.dart';
import 'package:hom_nay_an_gi/features/blog/blog_repository.dart';
import 'package:hom_nay_an_gi/features/blog/compose_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hom_nay_an_gi/features/discover/widgets/restaurant_map.dart';
import 'package:hom_nay_an_gi/features/settings/personal_backup.dart';
import 'fixtures.dart';
import 'support/community_fakes.dart';

Future<(ProviderContainer, MemoryBlog)> mountAdaptive(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  LocalSettings settings = const LocalSettings(),
  MemoryBlog? blog,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({});
  final store = LocalStore(await SharedPreferences.getInstance());
  await store.write(settings, accountId: 'ui-test');
  final auth = MemoryAuth(
    current: const Member(id: 'ui-test', name: 'An'),
  );
  final repository = blog ?? MemoryBlog();
  final c = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWithValue(store),
      backendReadyProvider.overrideWithValue(true),
      authRepositoryProvider.overrideWithValue(auth),
      blogRepositoryProvider.overrideWithValue(repository),
      mapNetworkEnabledProvider.overrideWithValue(false),
      repositoryProvider.overrideWithValue(
        TestRepository([for (var i = 0; i < 12; i++) venue(id: '$i')]),
      ),
    ],
  );
  addTearDown(() async {
    c.dispose();
    await auth.changes.close();
    await repository.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const MealApp()),
  );
  await tester.pumpAndSettle();
  return (c, repository);
}

PostDraft placeDraft({
  GeoPoint? point = const GeoPoint(10.77734, 106.700248),
  String name = 'Quán thành viên',
  String area = 'Địa chỉ quán, TP.HCM',
}) => PostDraft(
  kind: PostKind.place,
  title: 'Địa điểm mới đáng ghé',
  body: 'Quán này có món ngon và mình muốn giới thiệu với mọi người.',
  category: 'rice',
  restaurantName: name,
  area: area,
  place: point,
);

void main() {
  test(
    'old settings remain readable and malformed appearance resets safely',
    () {
      expect(LocalSettings.fromJson({}).appearance.textSize, 1);
      final value = Appearance.fromJson({
        'accent': 'unknown',
        'textSize': double.infinity,
        'reduceMotion': 'yes',
      });
      expect(value.accent, AppAccent.forest);
      expect(value.textSize, 1);
      expect(value.reduceMotion, false);
    },
  );
  test('personal font size preserves the system accessibility scaler', () {
    const scaler = PersonalTextScaler(TextScaler.linear(2), 1.3);
    expect(scaler.scale(16), closeTo(41.6, .001));
  });
  test('private appearance is absent from account backup', () {
    const settings = LocalSettings(
      appearance: Appearance(
        accent: AppAccent.ocean,
        textSize: 1.3,
        reduceMotion: true,
      ),
    );
    expect(settings.toJson()['appearance'], isNotNull);
    expect(
      PersonalBackup.fromSettings(settings).toData().containsKey('appearance'),
      false,
    );
  });
  for (final (size, scale, rail) in [
    (const Size(320, 568), 1.0, false),
    (const Size(390, 844), 2.0, false),
    (const Size(320, 568), 2.6, false),
    (const Size(844, 390), 1.5, true),
    (const Size(800, 1280), 1.0, true),
    (const Size(1440, 900), 1.0, true),
  ]) {
    testWidgets('all main tabs fit $size at text scale $scale', (tester) async {
      final (c, _) = await mountAdaptive(tester, size: size, scale: scale);
      for (final route in [
        '/',
        '/discover',
        '/favorites',
        '/blog',
        '/settings',
      ]) {
        c.read(routerProvider).go(route);
        await tester.pumpAndSettle();
        expect(
          find.byType(NavigationRail),
          rail ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull, reason: route);
      }
    });
  }
  testWidgets('window resize keeps the search and current branch', (
    tester,
  ) async {
    final (c, _) = await mountAdaptive(tester);
    c.read(routerProvider).go('/discover');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Demo 4');
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();
    expect(find.text('Demo 4'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'cards use columns with natural height and collapse at large text',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: CustomScrollView(
            slivers: [
              AdaptiveCards(
                itemCount: 3,
                itemBuilder: (_, i) =>
                    SizedBox(height: 180, child: Text('Card $i')),
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('Card 0')).dy,
        tester.getTopLeft(find.text('Card 1')).dy,
      );
      expect(tester.getTopLeft(find.text('Card 1')).dx, greaterThan(300));
    },
  );
  testWidgets('appearance changes persist and do not reset the route', (
    tester,
  ) async {
    final (c, _) = await mountAdaptive(tester);
    c.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Đại dương'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Đại dương'));
    await tester.pumpAndSettle();
    expect(c.read(settingsProvider).appearance.accent, AppAccent.ocean);
    final stored = c.read(localStoreProvider).readAccount('ui-test');
    expect(stored.appearance.accent, AppAccent.ocean);
    expect(find.text('Cài đặt'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reduced motion skips the artificial meal selection delay', (
    tester,
  ) async {
    final (c, _) = await mountAdaptive(
      tester,
      settings: const LocalSettings(appearance: Appearance(reduceMotion: true)),
    );
    await tester.tap(find.text('CHỌN GIÚP TÔI'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.read(recommendationProvider).result, isNotNull);
    expect(c.read(recommendationProvider).busy, false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  test(
    'new places require a name, address and finite valid public coordinates',
    () {
      expect(placeDraft().validationError, isNull);
      expect(placeDraft(name: '').validationError, isNotNull);
      expect(placeDraft(area: '').validationError, isNotNull);
      for (final point in [
        null,
        const GeoPoint(double.nan, 106),
        const GeoPoint(91, 106),
        const GeoPoint(10, 181),
      ]) {
        expect(placeDraft(point: point).validationError, isNotNull);
      }
      final uri = MapsService.sharedPlaceUri(const GeoPoint(10, 106));
      expect(uri.host, 'www.google.com');
      expect(uri.queryParameters['destination'], '10.0,106.0');
    },
  );
  testWidgets('place composer validates and publishes a public pin', (
    tester,
  ) async {
    final (c, blog) = await mountAdaptive(tester);
    c.read(routerProvider).push('/blog/new?kind=place');
    await tester.pumpAndSettle();
    expect(find.byType(ComposeScreen), findsOneWidget);
    Future<void> fill(String label, String value) async {
      final field = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      await tester.scrollUntilVisible(
        field,
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.enterText(field, value);
      await tester.pump();
    }

    await fill('Tiêu đề', 'Địa điểm mới đáng ghé');
    await fill(
      'Câu chuyện của bạn',
      'Mình đã ăn ở đây và muốn chia sẻ địa chỉ này với mọi người.',
    );
    await fill('Tên quán *', 'Quán thành viên');
    await fill('Khu vực / địa chỉ', 'Địa chỉ quán, TP.HCM');
    await fill('Vĩ độ quán (công khai)', '10.77734');
    await fill('Kinh độ quán (công khai)', '106.700248');
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.ensureVisible(find.text('Chia sẻ địa điểm'));
    await tester.tap(find.text('Chia sẻ địa điểm'));
    await tester.pumpAndSettle();
    expect(blog.lastDraft?.kind, PostKind.place);
    expect(blog.lastDraft?.place?.latitude, 10.77734);
    await tester.scrollUntilVisible(
      find.text('Địa điểm mới đáng ghé'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Địa điểm mới đáng ghé'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'community discovery sees other members place and respects blocks',
    (tester) async {
      final blog = MemoryBlog();
      await blog.publish(
        const Member(id: 'alice', name: 'Alice'),
        placeDraft(),
      );
      final (c, _) = await mountAdaptive(tester, blog: blog);
      c.read(routerProvider).go('/discover');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cộng đồng'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Địa điểm mới đáng ghé'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Địa điểm mới đáng ghé'), findsOneWidget);
      await blog.block('ui-test', 'alice');
      await tester.pumpAndSettle();
      expect(find.text('Địa điểm mới đáng ghé'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'large-text place form and picker stay reachable without automatically publishing GPS',
    (tester) async {
      final (c, blog) = await mountAdaptive(
        tester,
        size: const Size(320, 568),
        scale: 2,
      );
      c.read(routerProvider).push('/blog/new?kind=place');
      await tester.pumpAndSettle();
      final button = find.text('Chọn vị trí quán trên bản đồ');
      await tester.scrollUntilVisible(
        button,
        180,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Chưa chọn ghim.'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(FlutterMap),
        120,
        scrollable: find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FlutterMap));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Dùng vị trí quán này'),
        150,
        scrollable: find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Dùng vị trí quán này'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(blog.lastDraft, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
