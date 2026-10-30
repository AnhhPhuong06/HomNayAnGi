import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/geo.dart';

enum LocationIssue { denied, deniedForever, disabled, timeout, unavailable }

class LocationFailure implements Exception {
  const LocationFailure(this.issue);
  final LocationIssue issue;
  String get message => switch (issue) {
    LocationIssue.denied =>
      'Bạn chưa cấp quyền vị trí. Có thể chọn khu vực thủ công.',
    LocationIssue.deniedForever =>
      'Quyền vị trí đã bị khóa. Mở cài đặt ứng dụng hoặc chọn khu vực thủ công.',
    LocationIssue.disabled =>
      'Dịch vụ vị trí đang tắt. Bật GPS hoặc chọn khu vực thủ công.',
    LocationIssue.timeout =>
      'Chưa lấy được vị trí kịp thời. Thử lại hoặc chọn khu vực.',
    LocationIssue.unavailable =>
      'Không lấy được vị trí. Bạn vẫn có thể chọn khu vực thủ công.',
  };
}

class LocationService {
  Future<GeoPoint> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 5),
      )) {
        throw const LocationFailure(LocationIssue.disabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationFailure(LocationIssue.deniedForever);
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw const LocationFailure(LocationIssue.denied);
      }
      final position = await Geolocator.getCurrentPosition(
        // A one-shot native GPS fix works offline and does not ask the user to
        // enable Google Location Accuracy / Wi-Fi scanning on Android.
        locationSettings:
            !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? AndroidSettings(
                forceLocationManager: true,
                accuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 12),
              )
            : const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 12),
              ),
      ).timeout(const Duration(seconds: 15));
      final point = GeoPoint(position.latitude, position.longitude);
      if (!point.isValid) {
        throw const LocationFailure(LocationIssue.unavailable);
      }
      return point;
    } on LocationFailure {
      rethrow;
    } on TimeoutException {
      throw const LocationFailure(LocationIssue.timeout);
    } catch (_) {
      throw const LocationFailure(LocationIssue.unavailable);
    }
  }
}
