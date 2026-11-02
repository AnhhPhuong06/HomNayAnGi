import 'package:url_launcher/url_launcher.dart';
import '../../features/restaurants/models/restaurant.dart';
import '../../features/restaurants/models/source_link.dart';
import '../utils/geo.dart';

class MapsService {
  static Uri sharedPlaceUri(GeoPoint point) =>
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '${point.latitude},${point.longitude}',
        'travelmode': 'driving',
      });
  Future<bool> sharedPlace(GeoPoint point) =>
      point.isValid ? _external(sharedPlaceUri(point)) : Future.value(false);
  Future<bool> openDataLicense() =>
      _external(Uri.https('www.openstreetmap.org', '/copyright'));
  Future<bool> openSource(SourceLink source) =>
      _external(Uri.parse(source.url));

  static Uri tiktokSearchUri(Restaurant restaurant) =>
      Uri.https('www.tiktok.com', '/search', {
        'q': [restaurant.name, restaurant.area, restaurant.province].join(' '),
      });

  Future<bool> searchTikTok(Restaurant restaurant) =>
      _external(tiktokSearchUri(restaurant));

  static Uri directionsUri(Restaurant restaurant) =>
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '${restaurant.latitude},${restaurant.longitude}',
        'travelmode': 'driving',
      });

  Future<bool> _external(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<bool> directions(Restaurant restaurant) async {
    if (!restaurant.location.isValid) return false;
    // Construct a trusted HTTPS URL instead of launching untrusted mapUrl data.
    final uri = directionsUri(restaurant);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<bool> call(String phone) async {
    if (!RegExp(r'^\+?[0-9 ()-]{6,20}$').hasMatch(phone)) return false;
    try {
      return await launchUrl(Uri(scheme: 'tel', path: phone));
    } catch (_) {
      return false;
    }
  }
}
