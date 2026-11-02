import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/adaptive_cards.dart';
import '../../core/widgets/editorial.dart';
import '../auth/auth_repository.dart';
import '../auth/account_action_lock.dart';
import 'story_card.dart';
import 'post_actions.dart';
import 'blog_repository.dart';

class BlogScreen extends ConsumerStatefulWidget {
  const BlogScreen({super.key});
  @override
  ConsumerState<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends ConsumerState<BlogScreen> {
  PostKind? _filter;
  bool _mine = false;
  Future<void> _action(BlogPost post, String action) =>
      performPostAction(context, ref, post, action);

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(accountActionLockProvider);
    final member = ref.watch(memberProvider).asData?.value;
    final blocked = ref.watch(blockedAuthorsProvider);
    final posts = ref.watch(postsProvider);
    final s = Theme.of(context).colorScheme;
    Widget message(String title, String detail, [VoidCallback? retry]) =>
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyMessage(
            title: title,
            message: detail,
            action: retry == null ? null : 'Thử lại',
            onAction: retry,
          ),
        );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog ăn ngon'),
        actions: [
          IconButton(
            tooltip: 'Làm mới blog',
            onPressed: () {
              ref.invalidate(postsProvider);
              ref.invalidate(blockedAuthorsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ContentWidth(
        maxWidth: 1120,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              sliver: SliverList.list(
                children: [
                  const PageIntro(
                    eyebrow: 'CHUYỆN BỮA NGON',
                    title: 'Ngon hơn,\nkhi cùng chia sẻ.',
                    description:
                        'Một bữa ăn đáng nhớ. Một địa chỉ đáng ghé. Kể câu chuyện của bạn ở đây.',
                  ),
                  const SizedBox(height: 22),
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () => context.push(
                        '/blog/new?kind=${(_filter ?? PostKind.meal).name}',
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: s.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.edit_note_rounded,
                                color: s.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Chia sẻ bữa ăn / quán ngon',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_outward_rounded,
                              size: 19,
                              color: s.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/blog/new?kind=place'),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Thêm địa điểm mới'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Tất cả'),
                        selected: _filter == null,
                        onSelected: (_) => setState(() => _filter = null),
                      ),
                      for (final k in PostKind.values)
                        FilterChip(
                          label: Text(k.label),
                          selected: _filter == k,
                          onSelected: (_) => setState(() => _filter = k),
                        ),
                      FilterChip(
                        label: const Text('Bài của tôi'),
                        selected: _mine,
                        onSelected: (v) => setState(() => _mine = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '30 bài mới nhất · Trải nghiệm từ thành viên, chưa được xác minh.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant),
                  ),
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
            blocked.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => message(
                'Chưa tải được danh sách chặn.',
                'Thử kết nối lại để xem blog.',
                () => ref.invalidate(blockedAuthorsProvider),
              ),
              data: (hidden) => posts.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => message(
                  'Chưa tải được blog.',
                  'Kiểm tra Internet rồi thử lại.',
                  () => ref.invalidate(postsProvider),
                ),
                data: (all) {
                  final visible = all
                      .where(
                        (p) =>
                            !hidden.contains(p.authorId) &&
                            (_filter == null || p.kind == _filter) &&
                            (!_mine || p.authorId == member?.id),
                      )
                      .toList();
                  if (visible.isEmpty) {
                    return message(
                      'Bữa ngon đầu tiên đang chờ.',
                      'Hãy kể về món bạn vừa ăn hoặc một quán đáng ghé.',
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: AdaptiveCards(
                      itemCount: visible.length,
                      itemBuilder: (_, i) => BlogStoryCard(
                        post: visible[i],
                        own: visible[i].authorId == member?.id,
                        busy: busy,
                        onAction: (action) => _action(visible[i], action),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
