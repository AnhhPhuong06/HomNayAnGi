import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hom_nay_an_gi/core/providers.dart';
import 'package:hom_nay_an_gi/core/services/local_store.dart';
import 'package:hom_nay_an_gi/features/discover/screens/discover_screen.dart';
import 'package:hom_nay_an_gi/features/restaurants/models/restaurant.dart';
import 'package:hom_nay_an_gi/features/restaurants/models/restaurant_photo.dart';
import 'package:hom_nay_an_gi/features/restaurants/repositories/open_data_restaurant_repository.dart';
import 'package:hom_nay_an_gi/features/restaurants/widgets/restaurant_card.dart';
import 'fixtures.dart';

Future<void> cachePhotos(WidgetTester tester, Iterable<Restaurant> rows) async {
  await tester.pumpWidget(const MaterialApp(home: SizedBox()));
  final context = tester.element(find.byType(SizedBox).first);
  await tester.runAsync(() async {
    for (final row in rows) {
      if (row.photo != null) {
        await precacheImage(
          ResizeImage(AssetImage(row.photo!.asset), width: 1000),
          context,
        );
      }
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> document;
  late List<Restaurant> catalog;
  setUpAll(() async {
    document =
        jsonDecode(
              await rootBundle.loadString('assets/data/restaurant_photos.json'),
            )
            as Map<String, dynamic>;
    catalog = await const OpenDataRestaurantRepository().load();
  });

  test(
    'every reviewed photo binds to a real venue with intact bundled bytes and attribution',
    () async {
      final photos = document['restaurants'] as Map<String, dynamic>;
      expect(
        catalog.where((r) => r.photo != null).length,
        document['reviewedPhotoCount'],
      );
      expect(photos.length, greaterThan(0));
      for (final entry in photos.entries) {
        final r = catalog.singleWhere((r) => r.id == entry.key);
        expect(r.photo, isNotNull);
        expect(entry.value['venueName'], r.name);
        final bytes = await rootBundle.load(r.photo!.asset);
        final data = bytes.buffer.asUint8List(
          bytes.offsetInBytes,
          bytes.lengthInBytes,
        );
        expect(data.take(3), [255, 216, 255]);
        expect(sha256.convert(data).toString(), entry.value['sha256']);
        expect(entry.value['matchEvidence'], isNotEmpty);
      }
    },
  );

  test('rejects missing rights and unsafe assets or links', () {
    final original = Map<String, dynamic>.from(
      (document['restaurants'] as Map).values.first as Map,
    );
    for (final change in [
      {'asset': 'assets/venue_photos/../../config/firebase.ios.json'},
      {
        'sourceUrl':
            'https://commons.wikimedia.org.evil.example/wiki/File:x.jpg',
      },
      {'licenseUrl': 'javascript:alert(1)'},
      {'author': ''},
      {'license': 'All rights reserved'},
    ]) {
      expect(RestaurantPhoto.fromJson({...original, ...change}), isNull);
    }
  });

  test(
    'photo overlay cannot bind to an unknown venue or leak from raw data',
    () async {
      final raw =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/data/real_restaurants.json',
                ),
              )
              as List;
      final original = Map<String, dynamic>.from(
        (document['restaurants'] as Map).values.first as Map,
      );
      expect(
        () => parseOpenDataCatalog(
          jsonEncode([raw.first]),
          photosSource: jsonEncode({
            'schemaVersion': 1,
            'restaurants': {'osm-node-999999999999999': original},
          }),
        ),
        throwsFormatException,
      );
      expect(
        parseOpenDataCatalog(
          jsonEncode([
            {...raw.first as Map, 'photo': original},
          ]),
        ).single.photo,
        isNull,
      );
    },
  );

  test(
    'renamed OSM business does not inherit the previous venue photo',
    () async {
      final raw =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/data/real_restaurants.json',
                ),
              )
              as List;
      final id = (document['restaurants'] as Map).keys.first;
      final row = Map<String, dynamic>.from(
        raw.firstWhere((r) => r['id'] == id) as Map,
      );
      row['name'] = 'A different business';
      expect(
        parseOpenDataCatalog(
          jsonEncode([row]),
          photosSource: jsonEncode({
            'schemaVersion': 1,
            'restaurants': {id: (document['restaurants'] as Map)[id]},
          }),
        ).single.photo,
        isNull,
      );
    },
  );

  testWidgets(
    'real venue image exposes full credit, license and capture date',
    (tester) async {
      final r = catalog.firstWhere((r) => r.photo != null);
      await cachePhotos(tester, [r]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FoodImage(restaurant: r)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Ảnh tại quán ·'));
      await tester.pumpAndSettle();
      expect(find.text('Nguồn ảnh tại quán'), findsOneWidget);
      expect(find.text('Tác giả: ${r.photo!.author}'), findsOneWidget);
      expect(
        find.text('Ngày chụp theo nguồn: ${r.photo!.capturedAt}'),
        findsOneWidget,
      );
      expect(find.text('Ảnh gốc trên Wikimedia Commons'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('photo filter keeps only reviewed venue images', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    final rows = [venue(), ...catalog.where((r) => r.photo != null).take(2)];
    await cachePhotos(tester, rows);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          initialSettingsProvider.overrideWithValue(const LocalSettings()),
          repositoryProvider.overrideWithValue(
            TestRepository(rows, demo: false),
          ),
        ],
        child: const MaterialApp(home: DiscoverScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Có ảnh tại quán'));
    await tester.tap(find.text('Có ảnh tại quán'));
    await tester.pumpAndSettle();
    expect(find.text('2 quán phù hợp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'photo credit remains reachable with large text on a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final r = catalog.singleWhere((r) => r.id == 'osm-node-4272727197');
      await cachePhotos(tester, [r]);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2.6)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: FoodImage(restaurant: r, height: 190),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Ảnh tại quán ·'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Xem giấy phép ${r.photo!.license}'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.text('Xem giấy phép ${r.photo!.license}').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
