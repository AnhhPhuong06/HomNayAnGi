import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/recommendation/models/meal_preference.dart';
import '../../features/recommendation/models/taste_preference.dart';
import '../utils/geo.dart';
import '../theme/appearance.dart';

class SavedLocation {
  const SavedLocation(this.label, this.point, {this.isGps = false});
  final String label;
  final GeoPoint point;
  final bool isGps;
  Map<String, Object> toJson() => {'label': label, 'point': point.toJson()};
  static SavedLocation? fromJson(Object? value) {
    if (value is! Map || value['label'] is! String) return null;
    final point = GeoPoint.fromJson(value['point']);
    return point == null
        ? null
        : SavedLocation(value['label'] as String, point);
  }
}

class LocalSettings {
  const LocalSettings({
    this.theme = ThemeMode.system,
    this.favorites = const {},
    this.history = const [],
    this.preference = const MealPreference(),
    this.taste = const TastePreference(),
    this.appearance = const Appearance(),
    this.location,
  });
  final ThemeMode theme;
  final Set<String> favorites;

  /// Newest first. Bounded to twenty, including repeated visits.
  final List<String> history;
  final MealPreference preference;
  final TastePreference taste;
  final Appearance appearance;
  final SavedLocation? location;
  LocalSettings copyWith({
    ThemeMode? theme,
    Set<String>? favorites,
    List<String>? history,
    MealPreference? preference,
    TastePreference? taste,
    Appearance? appearance,
    SavedLocation? location,
    bool clearLocation = false,
  }) => LocalSettings(
    theme: theme ?? this.theme,
    favorites: Set.unmodifiable(favorites ?? this.favorites),
    history: List.unmodifiable((history ?? this.history).take(20)),
    preference: preference ?? this.preference,
    taste: taste ?? this.taste,
    appearance: appearance ?? this.appearance,
    location: clearLocation ? null : location ?? this.location,
  );
  Map<String, Object?> toJson() => {
    'version': 1, 'theme': theme.name,
    'favorites': favorites.toList(), 'history': history.take(20).toList(),
    'preference': preference.toJson(),
    'taste': taste.toJson(),
    'appearance': appearance.toJson(),
    // A precise GPS fix stays in memory only.
    'location': location?.isGps == false ? location!.toJson() : null,
  };
  factory LocalSettings.fromJson(Map<String, dynamic> json) => LocalSettings(
    appearance: Appearance.fromJson(json['appearance']),
    theme:
        ThemeMode.values.where((t) => t.name == json['theme']).firstOrNull ??
        ThemeMode.system,
    favorites: Set.unmodifiable(
      (json['favorites'] as List? ?? []).whereType<String>(),
    ),
    history: List.unmodifiable(
      (json['history'] as List? ?? []).whereType<String>().take(20),
    ),
    preference: json['preference'] is Map<String, dynamic>
        ? MealPreference.fromJson(json['preference'] as Map<String, dynamic>)
        : const MealPreference(),
    location: SavedLocation.fromJson(json['location']),
    taste: json['taste'] is Map<String, dynamic>
        ? TastePreference.fromJson(json['taste'] as Map<String, dynamic>)
        : const TastePreference(),
  );
}

class LocalStore {
  LocalStore(this._preferences);
  final SharedPreferences _preferences;
  static const key = 'meal_app.settings.v1';
  Future<void> _pending = Future.value();
  static String accountKey(String uid) =>
      '$key.account.${base64Url.encode(utf8.encode(uid))}';
  LocalSettings readAccount(String uid, {ThemeMode theme = ThemeMode.system}) {
    try {
      final raw = _preferences.getString(accountKey(uid));
      if (raw == null) return LocalSettings(theme: theme);
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) throw const FormatException();
      return LocalSettings.fromJson(json);
    } catch (_) {
      throw const StorageFailure(
        'Chưa đọc được dữ liệu của tài khoản này. Hãy thử lại.',
      );
    }
  }

  LocalSettings read() {
    try {
      final raw = _preferences.getString(key);
      if (raw == null) return const LocalSettings();
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Invalid preferences');
      }
      return LocalSettings.fromJson(json);
    } on FormatException {
      throw const StorageFailure(
        'Dữ liệu lưu chưa đọc được. Bạn có thể tiếp tục và lưu lại cài đặt.',
      );
    } on TypeError {
      throw const StorageFailure(
        'Dữ liệu lưu không tương thích. Bạn có thể tiếp tục và lưu lại cài đặt.',
      );
    }
  }

  Future<void> write(LocalSettings settings, {String? accountId}) {
    final encoded = jsonEncode(settings.toJson());
    final target = accountId == null ? key : accountKey(accountId);
    final operation = _pending.then((_) async {
      if (!await _preferences.setString(target, encoded)) {
        throw const StorageFailure('Không lưu được thay đổi. Hãy thử lại.');
      }
    });
    _pending = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        // Caller receives the failure; keep the queue usable for the next write.
      },
    );
    return operation;
  }

  Future<void> removeAccount(String uid) {
    final operation = _pending.then((_) async {
      if (!await _preferences.remove(accountKey(uid))) {
        throw const StorageFailure('Chưa xóa được dữ liệu tài khoản trên máy.');
      }
    });
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}

class StorageFailure implements Exception {
  const StorageFailure(this.message);
  final String message;
}
