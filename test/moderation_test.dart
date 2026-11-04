import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hom_nay_an_gi/features/auth/auth_repository.dart';
import 'package:hom_nay_an_gi/features/blog/blog_repository.dart';
import 'package:hom_nay_an_gi/features/moderation/moderation_repository.dart';
import 'package:hom_nay_an_gi/features/moderation/moderation_screen.dart';

const report = ContentReport(
  id: 'r',
  postId: 'p',
  reason: 'Nội dung không phù hợp',
  reporterId: 'reader',
  resolved: false,
);

class MemoryModeration implements ModerationRepository {
  int queries = 0, writes = 0;
  bool? removed;
  @override
  Stream<bool> isAdmin(String uid) => Stream.value(true);
  @override
  Stream<List<ContentReport>> reports() {
    queries++;
    return Stream.value([report]);
  }

  @override
  Future<BlogPost?> post(String id) async => const BlogPost(
    id: 'p',
    authorId: 'writer',
    authorName: 'Tác giả',
    kind: PostKind.meal,
    title: 'Chia sẻ bữa ăn',
    body: 'Nội dung được báo cáo cần xem xét.',
    category: 'rice',
    restaurantId: '',
    restaurantName: '',
    area: '',
  );
  @override
  Future<void> resolve(
    ContentReport report,
    String moderatorId, {
    required bool removePost,
  }) async {
    expect(moderatorId, 'moderator');
    writes++;
    removed = removePost;
  }
}

Future<void> mount(
  WidgetTester tester,
  MemoryModeration repository, {
  Stream<bool>? access,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        moderationRepositoryProvider.overrideWithValue(repository),
        isAdminProvider.overrideWith((ref) => access ?? Stream.value(true)),
        memberProvider.overrideWith(
          (ref) =>
              Stream.value(const Member(id: 'moderator', name: 'Quản trị')),
        ),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          ref.watch(memberProvider);
          return const MaterialApp(home: ModerationScreen());
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('non-admin cannot query reports or act', (tester) async {
    final repository = MemoryModeration();
    await mount(tester, repository, access: Stream.value(false));
    expect(repository.queries, 0);
    expect(find.text(report.reason), findsNothing);
    expect(repository.writes, 0);
  });
  testWidgets(
    'keeping a reviewed post resolves the report without removing it',
    (tester) async {
      final repository = MemoryModeration();
      await mount(tester, repository);
      await tester.tap(find.text(report.reason));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Chia sẻ bữa ăn'), findsOneWidget);
      await tester.tap(find.text('Giữ bài, hoàn tất báo cáo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(repository.writes, 1);
      expect(repository.removed, false);
    },
  );
  testWidgets(
    'removing a post needs a second confirmation; cancel writes nothing',
    (tester) async {
      final repository = MemoryModeration();
      await mount(tester, repository);
      await tester.tap(find.text(report.reason));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Gỡ bài vi phạm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Hủy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(repository.writes, 0);
      await tester.tap(find.text(report.reason));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Gỡ bài vi phạm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Xác nhận gỡ bài'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(repository.writes, 1);
      expect(repository.removed, true);
    },
  );
  testWidgets('role revoked while reviewing prevents the write', (
    tester,
  ) async {
    final repository = MemoryModeration(),
        access = StreamController<bool>.broadcast();
    addTearDown(access.close);
    await mount(tester, repository, access: access.stream);
    access.add(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text(report.reason));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    access.add(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Giữ bài, hoàn tất báo cáo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(repository.writes, 0);
  });
}
