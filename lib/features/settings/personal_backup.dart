import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/local_store.dart';
import '../recommendation/models/meal_preference.dart';
import '../recommendation/models/taste_preference.dart';

class BackupConflict implements Exception {
  const BackupConflict();
}

class PersonalBackup {
  const PersonalBackup({
    required this.favorites,
    required this.history,
    required this.preference,
    required this.taste,
    this.revision = 0,
    this.updatedAt,
  });
  final Set<String> favorites;
  final List<String> history;
  final MealPreference preference;
  final TastePreference taste;
  final int revision;
  final DateTime? updatedAt;
  factory PersonalBackup.fromSettings(LocalSettings settings) => PersonalBackup(
    favorites: Set.unmodifiable(settings.favorites),
    history: List.unmodifiable(settings.history),
    preference: settings.preference,
    taste: settings.taste,
  );

  // Device theme and all location data intentionally stay outside the backup.
  Map<String, Object?> toData() {
    if (favorites.length > 1000 || taste.hiddenRestaurantIds.length > 1000) {
      throw const FormatException(
        'Bản sao lưu hỗ trợ tối đa 1.000 quán yêu thích và 1.000 quán ẩn.',
      );
    }
    return {
      'favorites': favorites.toList(),
      'history': history.take(20).toList(),
      'preference': preference.toJson(),
      'taste': taste.toJson(),
    };
  }

  factory PersonalBackup.fromData(
    Map<String, dynamic> data, {
    int revision = 0,
    DateTime? updatedAt,
  }) {
    List<String> ids(String key, int limit) {
      final value = data[key];
      if (value is! List ||
          value.length > limit ||
          value.any((id) => id is! String || id.isEmpty || id.length > 100)) {
        throw const FormatException('Bản sao lưu không hợp lệ.');
      }
      return List<String>.from(value);
    }

    if (data.keys.any(
          (key) =>
              !{'favorites', 'history', 'preference', 'taste'}.contains(key),
        ) ||
        data['preference'] is! Map<String, dynamic> ||
        data['taste'] is! Map<String, dynamic>) {
      throw const FormatException('Bản sao lưu không tương thích.');
    }
    return PersonalBackup(
      favorites: Set.unmodifiable(ids('favorites', 1000)),
      history: List.unmodifiable(ids('history', 20)),
      preference: MealPreference.fromJson(
        data['preference'] as Map<String, dynamic>,
      ),
      taste: TastePreference.fromJson(data['taste'] as Map<String, dynamic>),
      revision: revision,
      updatedAt: updatedAt,
    );
  }
}

abstract class PersonalBackupRepository {
  Future<PersonalBackup?> load(String uid);
  Future<void> save(
    String uid,
    PersonalBackup backup, {
    required int expectedRevision,
  });
}

class FirestorePersonalBackupRepository implements PersonalBackupRepository {
  FirestorePersonalBackupRepository(this.db);
  final FirebaseFirestore db;
  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      db.collection('profiles').doc(uid);
  @override
  Future<PersonalBackup?> load(String uid) async {
    final doc = await _doc(uid)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 15));
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['version'] != 1 ||
        data['revision'] is! int ||
        data['data'] is! Map<String, dynamic>) {
      throw const FormatException('Bản sao lưu không tương thích.');
    }
    return PersonalBackup.fromData(
      data['data'] as Map<String, dynamic>,
      revision: data['revision'] as int,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  Future<void> save(
    String uid,
    PersonalBackup backup, {
    required int expectedRevision,
  }) async {
    final payload = backup.toData();
    // Transactions fail offline, so a timed-out save cannot silently queue a set().
    await db.runTransaction(
      (tx) async {
        final current = await tx.get(_doc(uid));
        final revision = current.data()?['revision'] ?? 0;
        if (revision != expectedRevision) throw const BackupConflict();
        tx.set(_doc(uid), {
          'version': 1,
          'revision': expectedRevision + 1,
          'updatedAt': FieldValue.serverTimestamp(),
          'data': payload,
        });
      },
      maxAttempts: 3,
      timeout: const Duration(seconds: 15),
    );
  }
}

final personalBackupRepositoryProvider = Provider<PersonalBackupRepository>(
  (ref) => FirestorePersonalBackupRepository(FirebaseFirestore.instance),
);
