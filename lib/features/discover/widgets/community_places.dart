import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/geo.dart';
import '../../../core/widgets/adaptive_cards.dart';
import '../../../core/widgets/common.dart';
import '../../auth/auth_repository.dart';
import '../../auth/account_action_lock.dart';
import '../../blog/blog_repository.dart';
import '../../blog/post_actions.dart';
import '../../blog/story_card.dart';

class CommunityPlaces extends ConsumerWidget {
  const CommunityPlaces({super.key, required this.query});
  final String query;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postsProvider);
    final blocked = ref.watch(blockedAuthorsProvider);
    final uid = ref.watch(memberProvider).asData?.value?.id;
    final busy = ref.watch(accountActionLockProvider);
    Widget message(String title, String body, {VoidCallback? retry}) =>
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyMessage(
            title: title,
            message: body,
            action: retry == null ? null : 'Thử lại',
            onAction: retry,
          ),
        );
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Địa điểm thành viên chia sẻ',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Từ 30 bài viết mới nhất. Chưa xác minh; kiểm tra địa chỉ trước khi ghé. Bộ lọc danh mục OSM không áp dụng ở đây.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/blog/new?kind=place'),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Thêm địa điểm mới'),
                ),
              ],
            ),
          ),
        ),
        blocked.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => message(
            'Chưa tải được danh sách chặn.',
            'Kiểm tra kết nối để xem địa điểm.',
            retry: () => ref.invalidate(blockedAuthorsProvider),
          ),
          data: (hidden) => posts.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => message(
              'Chưa tải được địa điểm.',
              'Dữ liệu cộng đồng cần kết nối Internet.',
              retry: () => ref.invalidate(postsProvider),
            ),
            data: (all) {
              final normalized = normalizeSearch(query);
              final visible = all
                  .where(
                    (p) =>
                        p.kind == PostKind.place &&
                        !p.pending &&
                        p.place != null &&
                        !hidden.contains(p.authorId) &&
                        normalizeSearch(
                          '${p.restaurantName} ${p.area} ${p.title}',
                        ).contains(normalized),
                  )
                  .toList();
              if (visible.isEmpty) {
                return message(
                  'Chưa có địa điểm phù hợp.',
                  'Hãy thử từ khóa khác hoặc chia sẻ địa chỉ bạn yêu thích.',
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: AdaptiveCards(
                  itemCount: visible.length,
                  itemBuilder: (context, i) => BlogStoryCard(
                    post: visible[i],
                    own: visible[i].authorId == uid,
                    busy: busy,
                    onAction: (action) =>
                        performPostAction(context, ref, visible[i], action),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
