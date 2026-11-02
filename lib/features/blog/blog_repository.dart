import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_repository.dart';
import '../../core/utils/geo.dart' as geo;
import '../restaurants/models/food_category.dart';

enum PostKind { meal, restaurant, place }

class PendingPublication implements Exception {
  const PendingPublication();
}

extension PostKindText on PostKind {
  String get label => switch (this) {
    PostKind.meal => 'Hôm nay ăn gì',
    PostKind.restaurant => 'Quán ăn ngon',
    PostKind.place => 'Địa điểm mới',
  };
}

class BlogPost {
  const BlogPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.kind,
    required this.title,
    required this.body,
    required this.category,
    required this.restaurantId,
    required this.restaurantName,
    required this.area,
    this.createdAt,
    this.pending = false,
    this.place,
  });
  final String id,
      authorId,
      authorName,
      title,
      body,
      category,
      restaurantId,
      restaurantName,
      area;
  final PostKind kind;
  final DateTime? createdAt;
  final bool pending;
  final geo.GeoPoint? place;
  static BlogPost fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return BlogPost(
      id: doc.id,
      authorId: d['authorId'] as String,
      authorName: d['authorName'] as String,
      kind: PostKind.values.byName(d['kind'] as String),
      title: d['title'] as String,
      body: d['body'] as String,
      category: d['category'] as String,
      restaurantId: d['restaurantId'] as String,
      restaurantName: d['restaurantName'] as String,
      area: d['area'] as String,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      pending: doc.metadata.hasPendingWrites,
      place: geo.GeoPoint.fromJson({
        'latitude': d['latitude'],
        'longitude': d['longitude'],
      }),
    );
  }
}

class PostDraft {
  const PostDraft({
    required this.kind,
    required this.title,
    required this.body,
    required this.category,
    this.restaurantId = '',
    this.restaurantName = '',
    this.area = '',
    this.place,
  });
  final PostKind kind;
  final String title, body, category, restaurantId, restaurantName, area;
  final geo.GeoPoint? place;
  String? get validationError {
    if (title.trim().length < 5 || title.trim().length > 100) {
      return 'Tiêu đề cần từ 5 đến 100 ký tự.';
    }
    if (body.trim().length < 20 || body.trim().length > 3000) {
      return 'Nội dung cần từ 20 đến 3.000 ký tự.';
    }
    if (restaurantId.length > 100 ||
        restaurantName.length > 200 ||
        area.length > 300) {
      return 'Thông tin quán quá dài.';
    }
    if (!foodCategories.any((c) => c.id == category)) {
      return 'Chọn kiểu món hợp lệ.';
    }
    if (kind != PostKind.meal && restaurantName.trim().isEmpty) {
      return 'Chọn hoặc nhập tên quán muốn chia sẻ.';
    }
    if (kind != PostKind.meal && area.trim().isEmpty) {
      return 'Nhập khu vực hoặc địa chỉ để mọi người tìm quán.';
    }
    if (kind == PostKind.place && (place == null || !place!.isValid)) {
      return 'Chọn vị trí quán trên bản đồ hoặc nhập tọa độ hợp lệ.';
    }
    if (kind == PostKind.place && restaurantId.isNotEmpty) {
      return 'Địa điểm thành viên chia sẻ không dùng ID của danh mục OSM.';
    }
    if (kind != PostKind.place && place != null) {
      return 'Chỉ địa điểm mới được đính kèm ghim vị trí.';
    }
    return null;
  }
}

abstract class BlogRepository {
  Stream<List<BlogPost>> latest();
  Future<void> publish(Member author, PostDraft draft);
  Future<void> delete(String id);
  Future<void> report(String postId, String reporterId, String reason);
  Stream<Set<String>> blocked(String memberId);
  Future<void> block(String memberId, String authorId);
  Future<void> unblockAll(String memberId);
  Future<void> deleteMemberContent(String memberId);
}

class FirestoreBlogRepository implements BlogRepository {
  FirestoreBlogRepository(this.db);
  final FirebaseFirestore db;
  CollectionReference<Map<String, dynamic>> get posts => db.collection('posts');
  @override
  Stream<List<BlogPost>> latest() => posts
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots(includeMetadataChanges: true)
      .map((s) => s.docs.map(BlogPost.fromDocument).toList());
  @override
  Future<void> publish(Member author, PostDraft draft) async {
    if (draft.validationError != null) {
      throw FormatException(draft.validationError!);
    }
    await posts
        .doc()
        .set({
          'authorId': author.id,
          'authorName': author.name.substring(
            0,
            author.name.length.clamp(0, 50),
          ),
          'kind': draft.kind.name,
          'title': draft.title.trim(),
          'body': draft.body.trim(),
          'category': draft.category,
          'restaurantId': draft.restaurantId,
          'restaurantName': draft.restaurantName.trim(),
          'area': draft.area.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'termsVersion': 1,
          if (draft.kind == PostKind.place) ...{
            'latitude': draft.place!.latitude,
            'longitude': draft.place!.longitude,
          },
        })
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw const PendingPublication(),
        );
  }

  @override
  Future<void> delete(String id) => posts.doc(id).delete();
  @override
  Future<void> report(String postId, String reporterId, String reason) =>
      db.collection('reports').doc('${reporterId}_$postId').set({
        'postId': postId,
        'reporterId': reporterId,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
  CollectionReference<Map<String, dynamic>> _blocks(String uid) =>
      db.collection('members').doc(uid).collection('blocked');
  @override
  Stream<Set<String>> blocked(String memberId) =>
      _blocks(memberId).snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  @override
  Future<void> block(String memberId, String authorId) => _blocks(
    memberId,
  ).doc(authorId).set({'createdAt': FieldValue.serverTimestamp()});
  Future<void> _deleteQuery(Query<Map<String, dynamic>> query) async {
    while (true) {
      final batch = await query
          .limit(100)
          .get(const GetOptions(source: Source.server));
      if (batch.docs.isEmpty) return;
      final writes = db.batch();
      for (final doc in batch.docs) {
        writes.delete(doc.reference);
      }
      await writes.commit();
    }
  }

  @override
  Future<void> unblockAll(String memberId) => _deleteQuery(_blocks(memberId));
  @override
  Future<void> deleteMemberContent(String memberId) async {
    await _deleteQuery(posts.where('authorId', isEqualTo: memberId));
    await _deleteQuery(
      db.collection('reports').where('reporterId', isEqualTo: memberId),
    );
    await unblockAll(memberId);
    await db.collection('profiles').doc(memberId).delete();
  }
}

final blogRepositoryProvider = Provider<BlogRepository>(
  (ref) => FirestoreBlogRepository(FirebaseFirestore.instance),
);
final postsProvider = StreamProvider.autoDispose<List<BlogPost>>((ref) {
  if (!ref.watch(backendReadyProvider) ||
      ref.watch(memberProvider).asData?.value == null) {
    return Stream.value([]);
  }
  return ref.watch(blogRepositoryProvider).latest();
});
final blockedAuthorsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final member = ref.watch(memberProvider).asData?.value;
  if (!ref.watch(backendReadyProvider) || member == null) {
    return Stream.value({});
  }
  return ref.watch(blogRepositoryProvider).blocked(member.id);
});
