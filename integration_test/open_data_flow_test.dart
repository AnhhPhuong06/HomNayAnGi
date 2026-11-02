import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_app.dart';
import 'package:hom_nay_an_gi/core/services/local_store.dart';
import 'package:hom_nay_an_gi/features/restaurants/repositories/open_data_restaurant_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real catalog offline: choose, source, TikTok entry, favorite and restore',
    (tester) async {
      final catalog = parseOpenDataCatalog(
        await rootBundle.loadString('assets/data/real_restaurants.json'),
      );
      expect(catalog.length, greaterThan(100));
      final origin = catalog.first;
      final preferences = await SharedPreferences.getInstance();
      final store = LocalStore(preferences);
      await store.write(
        LocalSettings(
          location: SavedLocation(
            '${origin.area}, ${origin.province}',
            origin.location,
          ),
        ),
      );
      await launchCatalogTestApp();
      await tester.pumpAndSettle();
      await tester.tap(find.text('CHỌN GIÚP TÔI'));
      await tester.pumpAndSettle();
      expect(find.text('Gợi ý hôm nay'), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors · ODbL'), findsOneWidget);
      final id = store.read().history.first;
      final selected = catalog.firstWhere((r) => r.id == id);
      expect(id, startsWith('osm-'));
      expect(selected.rating, isNull);
      expect(selected.priceMin, isNull);
      await tester.scrollUntilVisible(
        find.byTooltip('Lưu yêu thích').first,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byTooltip('Lưu yêu thích').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(selected.name).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(selected.name).first);
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết quán'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Tìm video trên TikTok'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Xem nguồn OpenStreetMap'), findsOneWidget);
      expect(
        find.textContaining('chưa phải video review đã đối chiếu'),
        findsOneWidget,
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cài đặt').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tối'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await launchCatalogTestApp();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yêu thích').last);
      await tester.pumpAndSettle();
      expect(find.text(selected.name), findsOneWidget);
      expect(store.read().favorites, contains(id));
      expect(store.read().theme, ThemeMode.dark);
      expect(tester.takeException(), isNull);
    },
  );
}
