// Visual QA of the shipping widgets. Run explicitly with flutter test.
// Auth is a test fixture; venue data is the real bundled OSM catalog.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hom_nay_an_gi/app.dart';
import 'package:hom_nay_an_gi/core/providers.dart';
import 'package:hom_nay_an_gi/core/router/app_router.dart';
import 'package:hom_nay_an_gi/core/services/local_store.dart';
import 'package:hom_nay_an_gi/core/theme/appearance.dart';
import 'package:hom_nay_an_gi/features/auth/auth_repository.dart';
import 'package:hom_nay_an_gi/features/moderation/moderation_repository.dart';
import 'package:hom_nay_an_gi/features/blog/blog_repository.dart';
import 'package:hom_nay_an_gi/features/restaurants/models/restaurant.dart';
import 'package:hom_nay_an_gi/features/restaurants/repositories/open_data_restaurant_repository.dart';
import '../fixtures.dart';
import '../support/community_fakes.dart';
import 'package:hom_nay_an_gi/features/discover/widgets/restaurant_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const renderPreviews = bool.fromEnvironment('RENDER_UI_PREVIEWS');
  final catalog = <Restaurant>[];
  setUpAll(() async {
    if (!renderPreviews) return;
    final font = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    catalog.addAll(
      parseOpenDataCatalog(
        await rootBundle.loadString('assets/data/real_restaurants.json'),
      ),
    );
  });

  for (final (name, route, signedIn, theme) in [
    ('modern_login_light', '/login', false, ThemeMode.light),
    ('modern_login_dark', '/login', false, ThemeMode.dark),
    ('modern_home_fixture', '/', true, ThemeMode.light),
    ('modern_blog_empty_fixture', '/blog', true, ThemeMode.light),
    ('modern_discover_fixture', '/discover', true, ThemeMode.light),
    ('upgrade_settings_fixture', '/settings', true, ThemeMode.light),
    ('upgrade_taste_fixture', '/', true, ThemeMode.light),
    ('upgrade_map_offline_fixture', '/discover', true, ThemeMode.light),
    ('adaptive_tablet_discover_fixture', '/discover', true, ThemeMode.light),
    ('adaptive_desktop_home_fixture', '/', true, ThemeMode.light),
    ('adaptive_personalization_fixture', '/settings', true, ThemeMode.dark),
    ('adaptive_community_places_fixture', '/discover', true, ThemeMode.light),
    (
      'adaptive_place_form_fixture',
      '/blog/new?kind=place',
      true,
      ThemeMode.light,
    ),
  ]) {
    testWidgets(name, (tester) async {
      tester.view.physicalSize = switch (name) {
        'adaptive_tablet_discover_fixture' => const Size(1024, 900),
        'adaptive_desktop_home_fixture' => const Size(1440, 1000),
        'adaptive_community_places_fixture' => const Size(1280, 1000),
        _ => const Size(412, 915),
      };
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final store = LocalStore(await SharedPreferences.getInstance());
      final origin = name.startsWith('adaptive_')
          ? catalog.firstWhere(
              (r) => r.id == 'osm-node-3508237297',
              orElse: () => catalog.first,
            )
          : catalog.first;
      final auth = MemoryAuth(
        current: signedIn
            ? const Member(id: 'visual-test-only', name: 'Người kiểm thử')
            : null,
      );
      final blog = MemoryBlog();
      if (name == 'adaptive_community_places_fixture') {
        for (final r
            in catalog
                .where(
                  (r) =>
                      r.province == origin.province &&
                      r.address.isNotEmpty &&
                      !r.address.startsWith('Chưa có'),
                )
                .take(2)) {
          await blog.publish(
            const Member(id: 'preview-only', name: 'Phiên kiểm thử'),
            PostDraft(
              kind: PostKind.place,
              title: 'Địa điểm muốn giới thiệu: ${r.name}'.characters
                  .take(100)
                  .toString(),
              body:
                  'Bài viết xem trước để kiểm tra giao diện. Tọa độ và địa chỉ lấy từ địa điểm công khai trong catalog OSM, chưa phải bài đăng cộng đồng thật.',
              category: r.categories.firstOrNull ?? 'other',
              restaurantName: r.name,
              area: '${r.address}, ${r.province}',
              place: r.location,
            ),
          );
        }
      }
      if (signedIn) {
        await store.write(
          LocalSettings(
            theme: theme,
            appearance: name == 'adaptive_personalization_fixture'
                ? const Appearance(
                    accent: AppAccent.berry,
                    textSize: 1.15,
                    compactCards: true,
                  )
                : const Appearance(),
            location: SavedLocation(
              '${origin.area}, ${origin.province}',
              origin.location,
            ),
          ),
          accountId: 'visual-test-only',
        );
      }
      final container = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          mapNetworkEnabledProvider.overrideWithValue(false),
          initialSettingsProvider.overrideWithValue(
            LocalSettings(
              theme: theme,
              location: SavedLocation(
                '${origin.area}, ${origin.province}',
                origin.location,
              ),
            ),
          ),
          repositoryProvider.overrideWithValue(
            TestRepository(catalog, demo: false),
          ),
          backendReadyProvider.overrideWithValue(signedIn),
          isAdminProvider.overrideWith((ref) => Stream.value(false)),
          authRepositoryProvider.overrideWithValue(auth),
          blogRepositoryProvider.overrideWithValue(blog),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await auth.changes.close();
        await blog.close();
      });
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: UncontrolledProviderScope(
            container: container,
            child: const MealApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go(route);
      await tester.pumpAndSettle();
      if (name == 'adaptive_tablet_discover_fixture') {
        await tester.drag(
          find.byType(CustomScrollView).last,
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
      }
      if (name == 'adaptive_desktop_home_fixture') {
        await tester.drag(
          find.byType(CustomScrollView).last,
          const Offset(0, -620),
        );
        await tester.pumpAndSettle();
      }
      if (name == 'adaptive_personalization_fixture') {
        await tester.scrollUntilVisible(
          find.text('Màu của bạn'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await Scrollable.ensureVisible(
          tester.element(find.text('Màu của bạn')),
          alignment: 0,
        );
        await tester.pumpAndSettle();
      }
      if (name == 'adaptive_community_places_fixture') {
        await tester.tap(find.text('Cộng đồng'));
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(CustomScrollView).last,
          const Offset(0, -360),
        );
        await tester.pumpAndSettle();
      }
      if (name == 'upgrade_taste_fixture') {
        await tester.scrollUntilVisible(
          find.text('Khẩu vị'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Khẩu vị'));
        await tester.pumpAndSettle();
      }
      if (name == 'upgrade_map_offline_fixture') {
        await tester.tap(find.text('Bản đồ'));
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(CustomScrollView).last,
          const Offset(0, -280),
        );
        await tester.pumpAndSettle();
      }
      // Asset decoding completes on a real event loop before final paint.
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('artifacts').create(recursive: true);
        await File(
          'artifacts/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }, skip: !renderPreviews);
  }
}
