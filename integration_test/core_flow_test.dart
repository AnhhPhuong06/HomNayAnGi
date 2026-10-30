import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hom_nay_an_gi/main.dart' as app;
import 'package:hom_nay_an_gi/core/services/local_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('offline demo: choose, detail, favorite, search, theme, restart', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(LocalStore.key);
    await app.main();
    await tester.pumpAndSettle();
    expect(find.text('CHỌN GIÚP TÔI'), findsOneWidget);
    await tester.tap(find.text('Chọn khu vực của bạn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bắc Ninh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khu vực Bắc Ninh (demo)'));
    await tester.pumpAndSettle();
    expect(find.text('Khu vực Bắc Ninh (demo), Bắc Ninh'), findsOneWidget);
    await tester.tap(find.text('CHỌN GIÚP TÔI'));
    await tester.pumpAndSettle();
    expect(find.text('Gợi ý hôm nay'), findsOneWidget);
    final state = LocalStore(preferences).read();
    expect(state.history.length, 1);
    final id = state.history.first;
    await tester.scrollUntilVisible(
      find.byTooltip('Lưu yêu thích').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Lưu yêu thích').first);
    await tester.pumpAndSettle();
    expect(LocalStore(preferences).read().favorites, contains(id));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yêu thích').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Bỏ yêu thích'), findsOneWidget);
    await tester.tap(find.byType(Card).first);
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết quán'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khám phá').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'pho');
    await tester.pumpAndSettle();
    expect(find.textContaining('Phở bò · Bếp Demo'), findsWidgets);
    await tester.tap(find.text('Cài đặt').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();
    expect(LocalStore(preferences).read().theme, ThemeMode.dark);
    // Tear down the widget tree and bootstrap a fresh app using actual platform storage.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await app.main();
    await tester.pumpAndSettle();
    expect(find.text('Khu vực Bắc Ninh (demo), Bắc Ninh'), findsOneWidget);
    expect(LocalStore(preferences).read().history, contains(id));
    await tester.tap(find.text('Yêu thích').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Bỏ yêu thích'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Card).first)).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
}
