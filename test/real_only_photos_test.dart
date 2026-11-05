import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hom_nay_an_gi/core/providers.dart';
import 'package:hom_nay_an_gi/features/blog/blog_repository.dart';
import 'package:hom_nay_an_gi/features/blog/story_card.dart';
import 'package:hom_nay_an_gi/features/restaurants/models/restaurant.dart';
import 'package:hom_nay_an_gi/features/restaurants/repositories/open_data_restaurant_repository.dart';
import 'package:hom_nay_an_gi/features/restaurants/widgets/restaurant_card.dart';
import 'fixtures.dart';
import 'restaurant_photos_test.dart' show cachePhotos;

class UnreadableVenuePhotos extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/venue_photos/')) {
      throw StateError('Unreadable photo');
    }
    return rootBundle.load(key);
  }
}

BlogPost story({Restaurant? restaurant, String? venueName}) => BlogPost(
  id: 'post',
  authorId: 'writer',
  authorName: 'An',
  kind: PostKind.restaurant,
  title: 'Một quán ngon đáng ghé',
  body: 'Chia sẻ trải nghiệm tại quán.',
  category: 'rice',
  restaurantId: restaurant?.id ?? '',
  restaurantName: venueName ?? restaurant?.name ?? 'Quán thành viên',
  area: 'Việt Nam',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Restaurant> catalog;
  late Map<String, dynamic> rawVenue;
  setUpAll(() async {
    catalog = await const OpenDataRestaurantRepository().load();
    rawVenue =
        (jsonDecode(
                      await rootBundle.loadString(
                        'assets/data/real_restaurants.json',
                      ),
                    )
                    as List)
                .first
            as Map<String, dynamic>;
  });

  test(
    'shipping asset bundle contains reviewed venue photos and no stock pictures',
    () async {
      final assets = (await AssetManifest.loadFromAssetBundle(
        rootBundle,
      )).listAssets();
      expect(assets.where((p) => p.startsWith('assets/images/')), isEmpty);
      for (final row in catalog.where((r) => r.photo != null)) {
        expect(assets, contains(row.photo!.asset));
      }
    },
  );

  testWidgets(
    'unreviewed local and remote image URLs never become venue photographs',
    (tester) async {
      for (final url in [
        'assets/images/noodles.jpg',
        'https://images.unsplash.com/stock-food.jpg',
      ]) {
        final row = Restaurant.fromJson({...rawVenue, 'imageUrl': url});
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: FoodImage(restaurant: row)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Image), findsNothing);
        expect(find.text('Quán chưa có ảnh thực tế.'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'a broken real photo shows information instead of an illustrative fallback',
    (tester) async {
      final row = catalog.firstWhere((r) => r.photo != null);
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: UnreadableVenuePhotos(),
          child: MaterialApp(
            home: Scaffold(body: FoodImage(restaurant: row)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ảnh tại quán tạm chưa tải được.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a community post without a reviewed venue has no photo panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlogStoryCard(
                post: story(),
                own: false,
                busy: false,
                onAction: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    expect(find.text('Một quán ngon đáng ghé'), findsOneWidget);
  });

  testWidgets(
    'linked blog photo requires both venue ID and matching venue name',
    (tester) async {
      final row = catalog.firstWhere((r) => r.photo != null);
      await cachePhotos(tester, [row]);
      for (final name in ['A different venue', row.name]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              repositoryProvider.overrideWithValue(
                TestRepository([row], demo: false),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: BlogStoryCard(
                    post: story(restaurant: row, venueName: name),
                    own: false,
                    busy: false,
                    onAction: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(Image),
          name == row.name ? findsOneWidget : findsNothing,
        );
        if (name == row.name) {
          expect(find.textContaining('Ảnh tại quán ·'), findsOneWidget);
        }
      }
    },
  );
}
