// Shipping widgets with real OSM/Commons assets; this is a UI fixture, not OAuth proof.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hom_nay_an_gi/core/providers.dart';
import 'package:hom_nay_an_gi/core/services/local_store.dart';
import 'package:hom_nay_an_gi/core/theme/app_theme.dart';
import 'package:hom_nay_an_gi/features/discover/screens/discover_screen.dart';
import 'package:hom_nay_an_gi/features/restaurants/repositories/open_data_restaurant_repository.dart';
import 'package:hom_nay_an_gi/features/restaurants/screens/restaurant_detail_screen.dart';
import '../fixtures.dart';
import 'package:hom_nay_an_gi/features/restaurants/models/restaurant.dart';

void main() {
  const enabled = bool.fromEnvironment('RENDER_VENUE_PHOTO_PREVIEWS');
  late List<Restaurant> rows;
  setUpAll(() async {
    if (!enabled) return;
    final font = FontLoader('BeVietnamPro');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$w.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    rows = (await const OpenDataRestaurantRepository().load())
        .where((r) => r.photo != null)
        .toList();
  });
  for (final name in ['detail', 'discover', 'credit']) {
    testWidgets('real_photo_${name}_fixture', (tester) async {
      tester.view.physicalSize = name == 'discover'
          ? const Size(800, 1000)
          : const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final selected = rows.singleWhere((r) => r.id == 'osm-node-9587113803');
      SharedPreferences.setMockInitialValues({});
      final store = LocalStore(await SharedPreferences.getInstance());
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: ProviderScope(
            overrides: [
              localStoreProvider.overrideWithValue(store),
              initialSettingsProvider.overrideWithValue(const LocalSettings()),
              repositoryProvider.overrideWithValue(
                TestRepository([
                  selected,
                  ...rows.where((r) => r.id != selected.id),
                ], demo: false),
              ),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: appTheme(Brightness.light),
              home: name == 'discover'
                  ? const DiscoverScreen()
                  : RestaurantDetailScreen(id: selected.id),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      await tester.runAsync(() async {
        for (final r in rows) {
          await precacheImage(
            ResizeImage(AssetImage(r.photo!.asset), width: 1000),
            context,
          );
        }
      });
      await tester.pumpAndSettle();
      if (name == 'discover') {
        await tester.tap(find.text('Có ảnh tại quán'));
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -350),
        );
        await tester.pumpAndSettle();
      }
      if (name == 'credit') {
        await tester.tap(find.textContaining('Ảnh tại quán ·'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (capture.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('artifacts').create(recursive: true);
        await File(
          'artifacts/real_photo_${name}_fixture.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }, skip: !enabled);
  }
}
