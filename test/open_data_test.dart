import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hom_nay_an_gi/core/services/maps_service.dart';
import 'package:hom_nay_an_gi/features/restaurants/models/source_link.dart';
import 'package:hom_nay_an_gi/features/restaurants/repositories/open_data_restaurant_repository.dart';
import 'package:hom_nay_an_gi/features/restaurants/services/restaurant_queries.dart';
import 'fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final record = <String, dynamic>{
    'id': 'osm-node-123',
    'name': 'Phở Nguồn Thật',
    'address': 'Chưa có địa chỉ trong OpenStreetMap',
    'province': 'Tỉnh theo nguồn',
    'area': 'Khu theo nguồn',
    'country': 'VN',
    'latitude': 21.18,
    'longitude': 106.07,
    'categories': ['noodles'],
    'tags': ['noodles'],
    'sourceName': 'OpenStreetMap',
    'sourceUrl': 'https://www.openstreetmap.org/node/123',
  };
  test(
    'bundled country catalog matches manifest and contains only sourced real records',
    () async {
      final repository = OpenDataRestaurantRepository();
      final rows = await repository.load();
      final manifest =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/data/catalog_manifest.json',
                ),
              )
              as Map<String, dynamic>;
      expect(rows.length, manifest['namedDiningVenues']);
      expect(rows.length, greaterThan(10000));
      expect(rows.map((r) => r.id).toSet().length, rows.length);
      expect(
        rows.every(
          (r) =>
              r.id.startsWith('osm-') &&
              r.location.isValid &&
              r.country == 'VN',
        ),
        true,
      );
      expect(
        rows.every(
          (r) =>
              r.sourceName == 'OpenStreetMap' &&
              r.priceMin == null &&
              r.rating == null &&
              r.imageUrl.isEmpty,
        ),
        true,
      );
      expect(
        rows.expand((r) => r.sourceLinks).length,
        manifest['tiktokLinkCount'],
      );
      expect(
        rows.map((r) => r.province).toSet().length,
        (manifest['provinceCounts'] as Map).length,
      );
    },
  );
  test('open catalog never fills in missing rating, price or stock photo', () {
    final restaurants = parseOpenDataCatalog(jsonEncode([record, record]));
    expect(restaurants.length, 1);
    expect(restaurants.single.priceMin, isNull);
    expect(restaurants.single.rating, isNull);
    expect(restaurants.single.imageUrl, isEmpty);
    expect(queryRestaurants(restaurants, query: 'pho nguon').length, 1);
    expect(restaurants.single.indexedSearchText, isNotNull);
  });
  test('rejects catalog with unknown provenance or unsafe source URL', () {
    expect(
      () => parseOpenDataCatalog(
        jsonEncode([
          {...record, 'sourceName': 'Demo'},
        ]),
      ),
      throwsFormatException,
    );
    expect(
      () => parseOpenDataCatalog(
        jsonEncode([
          {...record, 'sourceUrl': 'https://evil.example/node/123'},
        ]),
      ),
      throwsFormatException,
    );
  });
  test('curated source link must bind to an existing ID with a check date', () {
    final overlay = {
      'schemaVersion': 1,
      'restaurants': {
        'osm-node-123': {
          'checkedAt': '2026-10-30',
          'links': [
            {
              'platform': 'tiktok',
              'url': 'https://www.tiktok.com/@restaurant/video/123456',
              'label': 'Video tham khảo',
            },
          ],
        },
      },
    };
    final restaurants = parseOpenDataCatalog(
      jsonEncode([record]),
      linksSource: jsonEncode(overlay),
    );
    expect(restaurants.single.sourceLinks.single.platform, 'tiktok');
    expect(
      () => parseOpenDataCatalog('[]', linksSource: jsonEncode(overlay)),
      throwsFormatException,
    );
  });
  test('source link allowlist rejects deceptive hosts and executable URLs', () {
    for (final url in [
      'javascript:alert(1)',
      'http://www.tiktok.com/@food/video/1',
      'https://www.tiktok.com.evil.example/@food/video/1',
      'https://secret@www.tiktok.com/@food/video/1',
      'https://www.tiktok.com:8443/@food/video/1',
      'https://www.tiktok.com/search?q=test',
    ]) {
      expect(
        SourceLink.fromJson({
          'platform': 'tiktok',
          'url': url,
          'label': 'Reference',
        }),
        isNull,
      );
    }
    expect(
      SourceLink.fromJson({
        'platform': 'tiktok',
        'url': 'https://www.tiktok.com/@food/video/123',
        'label': 'Reference',
      }),
      isNotNull,
    );
  });
  test(
    'Google Maps and TikTok links use public venue fields and trusted hosts',
    () {
      final restaurant = venue();
      final maps = MapsService.directionsUri(restaurant);
      expect(maps.host, 'www.google.com');
      expect(maps.queryParameters['destination'], '21.0,106.0');
      final tiktok = MapsService.tiktokSearchUri(restaurant);
      expect(tiktok.host, 'www.tiktok.com');
      expect(tiktok.path, '/search');
      expect(tiktok.queryParameters['q'], contains(restaurant.name));
    },
  );
}
