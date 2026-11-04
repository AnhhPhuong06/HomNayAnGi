import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'update_models.dart';

class CachedUpdate {
  const CachedUpdate(this.document, this.checkedAt);
  final Map<String, dynamic> document;
  final DateTime checkedAt;
}

abstract class UpdateStore {
  Future<bool> automaticEnabled();
  Future<void> setAutomatic(bool value);
  Future<CachedUpdate?> readCache();
  Future<void> writeCache(UpdateManifest value, DateTime now);
  Future<bool> isSnoozed(String releaseKey, DateTime now);
  Future<void> snooze(String releaseKey, DateTime now);
}

class PreferencesUpdateStore implements UpdateStore {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();
  @override
  Future<bool> automaticEnabled() async {
    try {
      return (await _prefs).getBool('updates.automatic') ?? true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> setAutomatic(bool value) async {
    if (!await (await _prefs).setBool('updates.automatic', value)) {
      throw StateError('Could not save reminder setting');
    }
  }

  @override
  Future<CachedUpdate?> readCache() async {
    try {
      final raw = (await _prefs).getString('updates.cache');
      if (raw == null || raw.length > 65536) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final date = DateTime.tryParse(json['checkedAt'] as String);
      if (date == null) return null;
      final data = json['document'] as Map<String, dynamic>;
      UpdateManifest.parse(data);
      return CachedUpdate(data, date);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeCache(UpdateManifest value, DateTime now) async {
    final document = {
      'schemaVersion': 1,
      'releases': [
        for (final r in value.releases)
          {
            'bundleId': r.bundleId,
            'version': r.version.name,
            'build': r.version.build,
            'channel': r.channel.name,
            'url': r.url.toString(),
            'notes': r.notes,
          },
      ],
    };
    if (!await (await _prefs).setString(
      'updates.cache',
      jsonEncode({
        'checkedAt': now.toUtc().toIso8601String(),
        'document': document,
      }),
    )) {
      throw StateError('Could not cache updates');
    }
  }

  @override
  Future<bool> isSnoozed(String releaseKey, DateTime now) async {
    try {
      final p = await _prefs;
      final until = DateTime.tryParse(
        p.getString('updates.snoozedUntil') ?? '',
      );
      return p.getString('updates.snoozedKey') == releaseKey &&
          until != null &&
          until.isAfter(now) &&
          until.difference(now) <= const Duration(hours: 24);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> snooze(String releaseKey, DateTime now) async {
    final p = await _prefs;
    if (!await p.setString('updates.snoozedKey', releaseKey) ||
        !await p.setString(
          'updates.snoozedUntil',
          now.add(const Duration(hours: 24)).toUtc().toIso8601String(),
        )) {
      throw StateError('Could not snooze reminder');
    }
  }
}

final updateStoreProvider = Provider<UpdateStore>(
  (ref) => PreferencesUpdateStore(),
);
