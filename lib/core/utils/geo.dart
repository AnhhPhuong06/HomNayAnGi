import 'dart:math';

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180;

  Map<String, Object> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
  static GeoPoint? fromJson(Object? value) {
    if (value is! Map) return null;
    final lat = value['latitude'];
    final lon = value['longitude'];
    if (lat is! num || lon is! num) return null;
    final point = GeoPoint(lat.toDouble(), lon.toDouble());
    return point.isValid ? point : null;
  }
}

double distanceKm(GeoPoint a, GeoPoint b) {
  if (!a.isValid || !b.isValid) throw ArgumentError('Invalid coordinates');
  const earthRadiusKm = 6371.0088;
  final lat = (b.latitude - a.latitude) * pi / 180;
  final lon = (b.longitude - a.longitude) * pi / 180;
  final h =
      pow(sin(lat / 2), 2) +
      cos(a.latitude * pi / 180) *
          cos(b.latitude * pi / 180) *
          pow(sin(lon / 2), 2);
  return earthRadiusKm * 2 * asin(sqrt(h.clamp(0, 1)));
}

String formatDistance(double km) =>
    km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

String formatPrice(int? min, int? max) {
  String amount(int value) => value % 1000 == 0
      ? '${value ~/ 1000}K'
      : '${(value / 1000).toStringAsFixed(1)}K';
  if (min == null && max == null) return 'Chưa có giá';
  if (min == null) return 'Đến ${amount(max!)} đ';
  if (max == null) return 'Từ ${amount(min)} đ';
  return '${amount(min)}–${amount(max)} đ';
}

String normalizeSearch(String input) {
  const accents = [
    'àáạảãâầấậẩẫăằắặẳẵ',
    'èéẹẻẽêềếệểễ',
    'ìíịỉĩ',
    'òóọỏõôồốộổỗơờớợởỡ',
    'ùúụủũưừứựửữ',
    'ỳýỵỷỹ',
    'đ',
  ];
  const plain = ['a', 'e', 'i', 'o', 'u', 'y', 'd'];
  var result = input.toLowerCase().trim();
  for (var i = 0; i < accents.length; i++) {
    result = result.replaceAll(RegExp('[${accents[i]}]'), plain[i]);
  }
  return result;
}
