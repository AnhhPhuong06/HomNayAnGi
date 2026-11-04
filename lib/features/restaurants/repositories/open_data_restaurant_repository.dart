import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/restaurant.dart';
import '../models/source_link.dart';
import '../models/restaurant_photo.dart';
import 'restaurant_repository.dart';

class OpenDataRestaurantRepository implements RestaurantRepository {
  const OpenDataRestaurantRepository();
  @override
  bool get isDemo => false;
  @override
  Future<List<Restaurant>> load() async {
    final sources = await Future.wait([
      rootBundle.loadString('assets/data/real_restaurants.json'),
      rootBundle.loadString('assets/data/source_links.json'),
      rootBundle.loadString('assets/data/restaurant_photos.json'),
    ]);
    return compute(parseOpenDataPayload, sources);
  }
}

List<Restaurant> parseOpenDataPayload(List<String> sources) =>
    parseOpenDataCatalog(
      sources[0],
      linksSource: sources[1],
      photosSource: sources.length > 2 ? sources[2] : null,
    );

List<Restaurant> parseOpenDataCatalog(
  String source, {
  String? linksSource,
  String? photosSource,
}) {
  final json = jsonDecode(source);
  if (json is! List) throw const FormatException('Invalid open data catalog');
  final venues = <String, Restaurant>{};
  final photosDocument = photosSource == null ? null : jsonDecode(photosSource);
  if (photosDocument != null &&
      (photosDocument is! Map<String, dynamic> ||
          photosDocument['schemaVersion'] != 1 ||
          photosDocument['restaurants'] is! Map<String, dynamic>)) {
    throw const FormatException('Invalid restaurant photo catalog');
  }
  final photos = photosDocument == null
      ? <String, dynamic>{}
      : (photosDocument as Map<String, dynamic>)['restaurants']
            as Map<String, dynamic>;
  final linksDocument = linksSource == null ? null : jsonDecode(linksSource);
  if (linksDocument != null &&
      (linksDocument is! Map<String, dynamic> ||
          linksDocument['schemaVersion'] != 1 ||
          linksDocument['restaurants'] is! Map<String, dynamic>)) {
    throw const FormatException('Invalid source links catalog');
  }
  final overrides = linksDocument == null
      ? <String, dynamic>{}
      : (linksDocument as Map<String, dynamic>)['restaurants']
            as Map<String, dynamic>;
  for (final raw in json) {
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Invalid open data venue');
    }
    if (raw['sourceName'] != 'OpenStreetMap' || raw['country'] != 'VN') {
      throw const FormatException('Unknown catalog provenance');
    }
    final override = overrides[raw['id']];
    final photo = photos[raw['id']];
    if (photo != null) {
      if (RestaurantPhoto.fromJson(photo) == null) {
        throw const FormatException(
          'Restaurant photo needs safe asset and attribution',
        );
      }
      // An OSM ID can later be renamed to another business: do not reuse its photo.
      if ((photo as Map<String, dynamic>)['venueName'] == raw['name']) {
        raw['photo'] = photo;
      } else {
        raw.remove('photo');
      }
    } else {
      // Open catalog images must come from the reviewed photo overlay.
      raw.remove('photo');
    }
    if (override != null) {
      if (override is! Map<String, dynamic> ||
          override['links'] is! List ||
          override['checkedAt'] is! String ||
          DateTime.tryParse(override['checkedAt'] as String) == null) {
        throw const FormatException(
          'Curated links need a check date and link list',
        );
      }
      final curated = override['links'] as List;
      if (curated.any((link) => SourceLink.fromJson(link) == null)) {
        throw const FormatException('Unsafe curated source URL');
      }
      raw['sourceLinks'] = [...(raw['sourceLinks'] as List? ?? []), ...curated];
    }
    final venue = Restaurant.fromJson(raw);
    if (venue.sourceUrl == null ||
        !RegExp(
          r'^https://www\.openstreetmap\.org/(node|way|relation)/\d+$',
        ).hasMatch(venue.sourceUrl!)) {
      throw const FormatException('Missing source reference');
    }
    venues.putIfAbsent(venue.id, () => venue);
  }
  if (overrides.keys.any((id) => !venues.containsKey(id))) {
    throw const FormatException(
      'Curated link references an unknown restaurant ID',
    );
  }
  if (photos.keys.any((id) => !venues.containsKey(id))) {
    throw const FormatException('Photo references an unknown restaurant ID');
  }
  return List.unmodifiable(venues.values);
}
