import 'dart:async';
import 'package:hom_nay_an_gi/features/auth/auth_repository.dart';
import 'package:hom_nay_an_gi/features/blog/blog_repository.dart';

class MemoryAuth implements AuthRepository {
  MemoryAuth({this.current});
  Member? current;
  final changes = StreamController<Member?>.broadcast(sync: true);
  int calls = 0;
  SocialProvider? lastProvider;
  Object? failure;
  void setMember(Member? member) {
    current = member;
    changes.add(member);
  }

  @override
  Stream<Member?> session() async* {
    yield current;
    yield* changes.stream;
  }

  @override
  Future<void> signIn(SocialProvider provider) async {
    calls++;
    lastProvider = provider;
    if (failure != null) throw failure!;
    setMember(const Member(id: 'tester', name: 'Người thử nghiệm'));
  }

  @override
  Future<void> signOut() async => setMember(null);
  @override
  Future<void> reauthenticate() async {}
  @override
  Future<void> deleteAccount() async => setMember(null);
}

class MemoryBlog implements BlogRepository {
  final posts = <BlogPost>[];
  final changes = StreamController<List<BlogPost>>.broadcast(sync: true);
  final blocks = <String>{};
  final blockChanges = StreamController<Set<String>>.broadcast(sync: true);
  int reports = 0;
  PostDraft? lastDraft;
  void emit() => changes.add(List.of(posts));
  @override
  Stream<List<BlogPost>> latest() async* {
    yield List.of(posts);
    yield* changes.stream;
  }

  @override
  Future<void> publish(Member author, PostDraft draft) async {
    lastDraft = draft;
    posts.insert(
      0,
      BlogPost(
        id: '${posts.length}',
        authorId: author.id,
        authorName: author.name,
        kind: draft.kind,
        title: draft.title,
        body: draft.body,
        category: draft.category,
        restaurantId: draft.restaurantId,
        restaurantName: draft.restaurantName,
        area: draft.area,
        place: draft.place,
        createdAt: DateTime(2026, 10, 30),
      ),
    );
    emit();
  }

  @override
  Future<void> delete(String id) async {
    posts.removeWhere((p) => p.id == id);
    emit();
  }

  @override
  Future<void> report(String postId, String reporterId, String reason) async {
    reports++;
  }

  @override
  Stream<Set<String>> blocked(String memberId) async* {
    yield Set.of(blocks);
    yield* blockChanges.stream;
  }

  @override
  Future<void> block(String memberId, String authorId) async {
    blocks.add(authorId);
    blockChanges.add(Set.of(blocks));
  }

  @override
  Future<void> unblockAll(String memberId) async {
    blocks.clear();
    blockChanges.add({});
  }

  @override
  Future<void> deleteMemberContent(String memberId) async {
    posts.removeWhere((p) => p.authorId == memberId);
    emit();
  }

  Future<void> close() async {
    await changes.close();
    await blockChanges.close();
  }
}
