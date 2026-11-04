import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/common.dart';
import '../auth/auth_repository.dart';
import '../auth/account_action_lock.dart';
import 'moderation_repository.dart';

class ModerationScreen extends ConsumerStatefulWidget {
  const ModerationScreen({super.key});
  @override
  ConsumerState<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends ConsumerState<ModerationScreen> {
  bool _onlyOpen = true;
  String? _busy;
  Future<void> _review(ContentReport report) async {
    if (_busy != null || report.pending || report.resolved) return;
    setState(() => _busy = report.id);
    try {
      final post = await ref
          .read(moderationRepositoryProvider)
          .post(report.postId);
      if (!mounted || ref.read(isAdminProvider).asData?.value != true) return;
      final remove = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xử lý báo cáo'),
          scrollable: true,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Lý do: ${report.reason}'),
              const SizedBox(height: 12),
              if (post == null)
                const Text('Bài viết đã được xóa.')
              else ...[
                Text(
                  post.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('Tác giả: ${post.authorName}'),
                const SizedBox(height: 8),
                SelectableText(post.body),
                if (post.restaurantName.isNotEmpty)
                  Text('${post.restaurantName} · ${post.area}'),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Giữ bài, hoàn tất báo cáo'),
                  ),
                  if (post != null)
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Gỡ bài vi phạm'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
      if (remove == null || !mounted) return;
      if (remove) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Gỡ bài viết này?'),
            scrollable: true,
            content: const Text(
              'Bài viết sẽ bị xóa khỏi cộng đồng. Thao tác không thể hoàn tác.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xác nhận gỡ bài'),
              ),
            ],
          ),
        );
        if (confirm != true || !mounted) return;
      }
      final member = ref.read(memberProvider).asData?.value;
      if (member == null || ref.read(isAdminProvider).asData?.value != true) {
        return;
      }
      final lock = ref.read(accountActionLockProvider.notifier);
      if (!lock.begin()) return;
      try {
        await ref
            .read(moderationRepositoryProvider)
            .resolve(report, member.id, removePost: remove);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã xử lý báo cáo.')));
        }
      } finally {
        lock.release();
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Máy chủ chưa xác nhận. Hãy làm mới danh sách trước khi xử lý lại.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa xử lý được báo cáo. Hãy kiểm tra kết nối và quyền quản trị.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(isAdminProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Quản trị cộng đồng')),
      body: ContentWidth(
        child: access.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Không kiểm tra được quyền quản trị.')),
          data: (admin) {
            if (!admin) {
              return const Center(
                child: Text('Tài khoản này không có quyền quản trị.'),
              );
            }
            final reports = ref.watch(moderationReportsProvider);
            return reports.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => EmptyMessage(
                title: 'Không tải được báo cáo.',
                message: 'Kiểm tra kết nối rồi thử lại.',
                action: 'Thử lại',
                onAction: () => ref.invalidate(moderationReportsProvider),
              ),
              data: (items) => ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    '100 báo cáo gần nhất. Chỉ tài khoản được cấp quyền trên máy chủ mới xem và xử lý được.',
                  ),
                  const SizedBox(height: 12),
                  FilterChip(
                    label: const Text('Chưa xử lý'),
                    selected: _onlyOpen,
                    onSelected: (value) => setState(() => _onlyOpen = value),
                  ),
                  for (final report in items.where(
                    (r) => !_onlyOpen || !r.resolved || r.pending,
                  ))
                    Card(
                      child: ListTile(
                        title: Text(report.reason),
                        subtitle: Text(
                          report.pending
                              ? 'Đang chờ máy chủ xác nhận'
                              : report.resolved
                              ? 'Đã xử lý'
                              : 'Bài ${report.postId}',
                        ),
                        trailing: _busy == report.id
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap:
                            _busy != null || report.pending || report.resolved
                            ? null
                            : () => _review(report),
                      ),
                    ),
                  if (items
                      .where((r) => !_onlyOpen || !r.resolved || r.pending)
                      .isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Không có báo cáo trong mục này.'),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
