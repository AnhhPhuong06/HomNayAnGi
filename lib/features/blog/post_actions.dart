import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_repository.dart';
import '../auth/account_action_lock.dart';
import 'blog_repository.dart';

Future<void> performPostAction(
  BuildContext context,
  WidgetRef ref,
  BlogPost post,
  String action,
) async {
  final member = ref.read(memberProvider).asData?.value;
  if (member == null || !{'delete', 'report', 'block'}.contains(action)) return;
  final repository = ref.read(blogRepositoryProvider);
  if (action == 'delete') {
    if (post.authorId != member.id) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài viết?'),
        content: const Text(
          'Bài viết và địa điểm đính kèm sẽ bị xóa khỏi phần cộng đồng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa bài'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
  }
  if (!context.mounted ||
      ref.read(memberProvider).asData?.value?.id != member.id) {
    return;
  }
  final lock = ref.read(accountActionLockProvider.notifier);
  if (!lock.begin()) return;
  try {
    switch (action) {
      case 'delete':
        await repository.delete(post.id);
      case 'report':
        await repository.report(post.id, member.id, 'Nội dung cần xem xét');
      case 'block':
        await repository.block(member.id, post.authorId);
    }
    if (context.mounted &&
        ref.read(memberProvider).asData?.value?.id == member.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (action) {
            'delete' => 'Đã xóa bài.',
            'block' => 'Đã chặn tác giả.',
            _ => 'Đã gửi báo cáo cho người quản trị.',
          }),
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa thực hiện được. Hãy kiểm tra kết nối.'),
        ),
      );
    }
  } finally {
    lock.release();
  }
}
