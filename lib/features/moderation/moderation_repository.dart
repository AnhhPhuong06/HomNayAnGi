import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_repository.dart';
import '../blog/blog_repository.dart';

class ContentReport {
  const ContentReport({
    required this.id,
    required this.postId,
    required this.reason,
    required this.reporterId,
    required this.resolved,
    this.pending = false,
  });
  final String id, postId, reason, reporterId;
  final bool resolved, pending;
}

abstract class ModerationRepository {
  Stream<bool> isAdmin(String uid);
  Stream<List<ContentReport>> reports();
  Future<BlogPost?> post(String id);
  Future<void> resolve(
    ContentReport report,
    String moderatorId, {
    required bool removePost,
  });
}

class FirestoreModerationRepository implements ModerationRepository {
  FirestoreModerationRepository(this.db);
  final FirebaseFirestore db;
  @override
  Stream<bool> isAdmin(String uid) => db
      .collection('roles')
      .doc(uid)
      .snapshots(includeMetadataChanges: true)
      .map((doc) => !doc.metadata.isFromCache && doc.data()?['admin'] == true);
  @override
  Stream<List<ContentReport>> reports() => db
      .collection('reports')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final d = doc.data();
          return ContentReport(
            id: doc.id,
            postId: d['postId'] as String,
            reason: d['reason'] as String,
            reporterId: d['reporterId'] as String,
            resolved: d['status'] == 'resolved',
            pending: doc.metadata.hasPendingWrites,
          );
        }).toList(),
      );
  @override
  Future<BlogPost?> post(String id) async {
    final doc = await db
        .collection('posts')
        .doc(id)
        .get(const GetOptions(source: Source.server));
    return doc.exists ? BlogPost.fromDocument(doc) : null;
  }

  @override
  Future<void> resolve(
    ContentReport report,
    String moderatorId, {
    required bool removePost,
  }) => db
      .runTransaction((transaction) async {
        final reference = db.collection('reports').doc(report.id);
        final current = await transaction.get(reference);
        if (!current.exists || current.data()?['status'] == 'resolved') return;
        if (removePost) {
          transaction.delete(db.collection('posts').doc(report.postId));
        }
        transaction.update(reference, {
          'status': 'resolved',
          'resolvedAt': FieldValue.serverTimestamp(),
          'moderatorId': moderatorId,
        });
      })
      .timeout(const Duration(seconds: 20));
}

final moderationRepositoryProvider = Provider<ModerationRepository>(
  (ref) => FirestoreModerationRepository(FirebaseFirestore.instance),
);
final isAdminProvider = StreamProvider.autoDispose<bool>((ref) {
  final uid = ref.watch(memberProvider).asData?.value?.id;
  if (!ref.watch(backendReadyProvider) || uid == null) {
    return Stream.value(false);
  }
  return ref.watch(moderationRepositoryProvider).isAdmin(uid);
});
final moderationReportsProvider =
    StreamProvider.autoDispose<List<ContentReport>>((ref) {
      if (ref.watch(isAdminProvider).asData?.value != true) {
        return Stream.value([]);
      }
      return ref.watch(moderationRepositoryProvider).reports();
    });
