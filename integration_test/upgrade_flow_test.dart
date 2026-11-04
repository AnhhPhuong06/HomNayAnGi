import 'package:hom_nay_an_gi/features/moderation/moderation_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hom_nay_an_gi/app.dart';
import 'package:hom_nay_an_gi/core/providers.dart';
import 'package:hom_nay_an_gi/core/router/app_router.dart';
import 'package:hom_nay_an_gi/core/services/local_store.dart';
import 'package:hom_nay_an_gi/core/theme/appearance.dart';
import 'package:hom_nay_an_gi/features/auth/auth_repository.dart';
import 'package:hom_nay_an_gi/features/blog/blog_repository.dart';
import 'package:hom_nay_an_gi/features/restaurants/repositories/open_data_restaurant_repository.dart';
import '../test/fixtures.dart';
import '../test/support/community_fakes.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real catalog, taste, appearance and public place flow on Android', (
    tester,
  ) async {
    const uid = 'native-upgrade-test-only';
    debugPrint('Upgrade fixture: opening local storage');
    final store = LocalStore(await SharedPreferences.getInstance());
    debugPrint('Upgrade fixture: loading public catalog');
    final catalog = await const OpenDataRestaurantRepository().load();
    debugPrint('Upgrade fixture: ${catalog.length} public venues loaded');
    // Public venue coordinates, not a user's GPS location.
    final origin = catalog.firstWhere(
      (r) => r.id == 'osm-node-3508237297',
      orElse: () => catalog.first,
    );
    await store.write(
      LocalSettings(
        location: SavedLocation(
          '${origin.area}, ${origin.province}',
          origin.location,
        ),
      ),
      accountId: uid,
    );
    debugPrint('Upgrade fixture: account storage ready');
    final auth = MemoryAuth(
      current: const Member(id: uid, name: 'Người kiểm thử'),
    );
    final blog = MemoryBlog();
    final c = ProviderContainer(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        backendReadyProvider.overrideWithValue(true),
        isAdminProvider.overrideWith((ref) => Stream.value(false)),
        authRepositoryProvider.overrideWithValue(auth),
        blogRepositoryProvider.overrideWithValue(blog),
        repositoryProvider.overrideWithValue(
          TestRepository(catalog, demo: false),
        ),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await auth.changes.close();
      await blog.close();
      await store.removeAccount(uid);
    });
    runApp(UncontrolledProviderScope(container: c, child: const MealApp()));
    debugPrint('Upgrade fixture: application mounted');
    await tester.pumpAndSettle();
    // Convert before the interactions so Android has painted the image surface
    // by the first screenshot, rather than capturing an empty initial frame.
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Khẩu vị'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Khẩu vị'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('☕ Cafe'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('upgrade_taste_native_fixture');
    await tester.tap(find.text('Lưu khẩu vị'));
    await tester.pumpAndSettle();
    expect(c.read(settingsProvider).taste.dislikedCategories, {'cafe'});
    c.read(routerProvider).go('/discover');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bản đồ'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    await binding.takeScreenshot('upgrade_map_native_fixture');
    c.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lưu lên tài khoản'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await binding.takeScreenshot('upgrade_settings_native_fixture');
    await tester.scrollUntilVisible(
      find.text('Màu của bạn'),
      180,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đại dương'));
    await tester.pumpAndSettle();
    expect(c.read(settingsProvider).appearance.accent, AppAccent.ocean);
    await Scrollable.ensureVisible(
      tester.element(find.text('Màu của bạn')),
      alignment: 0,
    );
    await tester.pumpAndSettle();
    await binding.takeScreenshot('adaptive_personalization_native_fixture');
    c.read(routerProvider).go('/blog/new?kind=place');
    await tester.pumpAndSettle();
    Future<void> fill(String label, String value) async {
      final field = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      await tester.scrollUntilVisible(
        field,
        180,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(field, value);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
    }

    await fill('Tiêu đề', 'Bản kiểm thử: địa điểm mới');
    await fill(
      'Câu chuyện của bạn',
      'Bài viết kiểm thử giao diện trên máy giả lập. Đây là địa điểm công khai trong catalog, không phải bài đăng production.',
    );
    await fill('Tên quán *', origin.name);
    await fill('Khu vực / địa chỉ', '${origin.address}, ${origin.province}');
    await fill('Vĩ độ quán (công khai)', origin.latitude.toString());
    await fill('Kinh độ quán (công khai)', origin.longitude.toString());
    await tester.scrollUntilVisible(
      find.byType(CheckboxListTile),
      180,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.ensureVisible(find.text('Chia sẻ địa điểm'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('adaptive_place_form_native_fixture');
    await tester.tap(find.text('Chia sẻ địa điểm'));
    await tester.pumpAndSettle();
    expect(blog.lastDraft?.kind, PostKind.place);
    expect(blog.lastDraft?.place?.latitude, origin.latitude);
    c.read(routerProvider).go('/discover');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cộng đồng'));
    await tester.tap(find.text('Cộng đồng'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Bản kiểm thử: địa điểm mới'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await binding.takeScreenshot('adaptive_places_native_fixture');
    expect(tester.takeException(), isNull);
  });
}
