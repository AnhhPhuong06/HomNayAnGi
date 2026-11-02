import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hom_nay_an_gi/app.dart';
import 'package:hom_nay_an_gi/core/providers.dart';
import 'package:hom_nay_an_gi/core/router/app_router.dart';
import 'package:hom_nay_an_gi/core/services/local_store.dart';
import 'package:hom_nay_an_gi/features/auth/auth_repository.dart';
import 'package:hom_nay_an_gi/features/blog/blog_repository.dart';
import 'package:hom_nay_an_gi/features/restaurants/widgets/dish_photo.dart';
import 'fixtures.dart';
import 'support/community_fakes.dart';

Future<ProviderContainer> communityApp(
  WidgetTester tester,
  MemoryAuth auth,
  MemoryBlog blog, {
  bool ready = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final store = LocalStore(await SharedPreferences.getInstance());
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWithValue(store),
      backendReadyProvider.overrideWithValue(ready),
      authRepositoryProvider.overrideWithValue(auth),
      blogRepositoryProvider.overrideWithValue(blog),
      repositoryProvider.overrideWithValue(TestRepository([venue()])),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await auth.changes.close();
    await blog.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MealApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('large text login keeps every provider reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final auth = MemoryAuth();
    await communityApp(tester, auth, MemoryBlog(), ready: false);
    for (final name in ['Google', 'Facebook', 'Apple']) {
      await tester.scrollUntilVisible(
        find.text('Tiếp tục với $name'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Tiếp tục với $name').hitTestable(), findsOneWidget);
    }
    expect(auth.calls, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('landscape blog with large text can reach the composer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await communityApp(
      tester,
      MemoryAuth(
        current: const Member(id: 'tester', name: 'An'),
      ),
      MemoryBlog(),
    );
    c.read(routerProvider).go('/blog');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Chia sẻ bữa ăn / quán ngon'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chia sẻ bữa ăn / quán ngon'));
    await tester.pumpAndSettle();
    expect(find.text('Viết bài chia sẻ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('restaurant post requires a real destination description', () {
    const draft = PostDraft(
      kind: PostKind.restaurant,
      title: 'Quán ngon hôm nay',
      body: 'Mình ghé ăn ở đây vào buổi trưa và rất thích.',
      category: 'rice',
    );
    expect(draft.validationError, contains('tên quán'));
  });
  test('illustrative photos match category and use a bundled fallback', () {
    expect(dishPhotoAsset(['cafe']), 'assets/images/cafe.jpg');
    expect(dishPhotoAsset(['unknown']), 'assets/images/rice.jpg');
  });
  testWidgets('login is mandatory on startup and protected deep links', (
    tester,
  ) async {
    final container = await communityApp(tester, MemoryAuth(), MemoryBlog());
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
    expect(find.text('Tiếp tục với Facebook'), findsOneWidget);
    expect(find.text('Tiếp tục với Apple'), findsOneWidget);
    container.read(routerProvider).go('/blog/new');
    await tester.pumpAndSettle();
    expect(find.text('Viết bài chia sẻ'), findsNothing);
    expect(find.text('CHỌN GIÚP TÔI'), findsNothing);
  });
  for (final provider in SocialProvider.values) {
    testWidgets('${provider.name} login opens app; logout closes all routes', (
      tester,
    ) async {
      final auth = MemoryAuth();
      final container = await communityApp(tester, auth, MemoryBlog());
      final label = switch (provider) {
        SocialProvider.google => 'Google',
        SocialProvider.facebook => 'Facebook',
        SocialProvider.apple => 'Apple',
      };
      await tester.ensureVisible(find.text('Tiếp tục với $label'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục với $label'));
      await tester.pumpAndSettle();
      expect(auth.lastProvider, provider);
      expect(auth.calls, 1);
      expect(find.text('CHỌN GIÚP TÔI'), findsOneWidget);
      container.read(routerProvider).go('/restaurant/a');
      await tester.pumpAndSettle();
      await auth.signOut();
      await tester.pumpAndSettle();
      expect(find.text('Tiếp tục với Google'), findsOneWidget);
      container.read(routerProvider).go('/result');
      await tester.pumpAndSettle();
      expect(find.text('Gợi ý hôm nay'), findsNothing);
    });
  }
  testWidgets('canceled social sign in stays at login', (tester) async {
    final auth = MemoryAuth()..failure = const SignInCancelled();
    await communityApp(tester, auth, MemoryBlog());
    await tester.ensureVisible(find.text('Tiếp tục với Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục với Google'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn đã hủy đăng nhập.'), findsOneWidget);
    expect(find.text('CHỌN GIÚP TÔI'), findsNothing);
  });
  testWidgets('missing backend never unlocks app or calls providers', (
    tester,
  ) async {
    final auth = MemoryAuth();
    await communityApp(tester, auth, MemoryBlog(), ready: false);
    await tester.ensureVisible(find.text('Tiếp tục với Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục với Google'));
    await tester.pumpAndSettle();
    expect(auth.calls, 0);
    expect(find.textContaining('chưa sẵn sàng'), findsOneWidget);
  });
  testWidgets('publish from linked venue and delete own post', (tester) async {
    final blog = MemoryBlog();
    final container = await communityApp(
      tester,
      MemoryAuth(
        current: const Member(id: 'tester', name: 'An'),
      ),
      blog,
    );
    container.read(routerProvider).go('/blog/new?kind=restaurant&restaurant=a');
    await tester.pumpAndSettle();
    expect(find.text('Ảnh món ăn minh họa'), findsOneWidget);
    final body = find.widgetWithText(TextField, 'Câu chuyện của bạn');
    await tester.ensureVisible(body);
    await tester.enterText(
      body,
      'Mình đã ghé quán hôm nay, phở nóng và rất vừa miệng.',
    );
    await tester.scrollUntilVisible(
      find.byType(CheckboxListTile),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Đăng bài lên blog'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng bài lên blog'));
    await tester.pumpAndSettle();
    expect(blog.lastDraft?.restaurantId, 'a');
    expect(blog.lastDraft?.kind, PostKind.restaurant);
    expect(find.text('Blog ăn ngon'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.ensureVisible(find.byTooltip('Tùy chọn bài viết'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tùy chọn bài viết'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa bài'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa bài').last);
    await tester.pumpAndSettle();
    expect(blog.posts, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('report and block another author hides their posts', (
    tester,
  ) async {
    final blog = MemoryBlog();
    await blog.publish(
      const Member(id: 'other', name: 'Bạn B'),
      const PostDraft(
        kind: PostKind.meal,
        title: 'Cơm trưa thật ngon',
        body: 'Bữa cơm hôm nay vừa miệng, mình rất thích.',
        category: 'rice',
      ),
    );
    final c = await communityApp(
      tester,
      MemoryAuth(
        current: const Member(id: 'tester', name: 'An'),
      ),
      blog,
    );
    c.read(routerProvider).go('/blog');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Tùy chọn bài viết'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tùy chọn bài viết'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Báo cáo bài viết'));
    await tester.pumpAndSettle();
    expect(blog.reports, 1);
    await tester.pump(const Duration(seconds: 4));
    await tester.ensureVisible(find.byTooltip('Tùy chọn bài viết'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tùy chọn bài viết'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chặn tác giả'));
    await tester.pumpAndSettle();
    expect(find.text('Cơm trưa thật ngon'), findsNothing);
  });
}
