import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/common.dart';
import '../../core/providers.dart';
import '../blog/blog_repository.dart';
import 'auth_repository.dart';
import 'account_action_lock.dart';

class AccountSection extends ConsumerStatefulWidget {
  const AccountSection({super.key});
  @override
  ConsumerState<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends ConsumerState<AccountSection> {
  bool _busy = false;
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    final lock = ref.read(accountActionLockProvider.notifier);
    if (!lock.begin()) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(accountError(e))));
      }
    } finally {
      lock.release();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Member member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản và bài viết?'),
        content: const Text(
          'Bạn sẽ xác nhận lại với nhà cung cấp đăng nhập. Tất cả bài blog, báo cáo, danh sách chặn và bản sao lưu trên tài khoản sẽ bị xóa. Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tiếp tục xóa'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await _run(() async {
      final auth = ref.read(authRepositoryProvider);
      final store = ref.read(localStoreProvider);
      final blog = ref.read(blogRepositoryProvider);
      await auth.reauthenticate();
      if (!mounted || ref.read(memberProvider).asData?.value?.id != member.id) {
        throw const SignInCancelled();
      }
      await blog.deleteMemberContent(member.id);
      if (!mounted || ref.read(memberProvider).asData?.value?.id != member.id) {
        throw const SignInCancelled();
      }
      await auth.deleteAccount();
      await store.removeAccount(member.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(memberProvider).asData?.value;
    final locked = _busy || ref.watch(accountActionLockProvider);
    if (member == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Tài khoản'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(member.name),
          subtitle: Text(
            member.email.isEmpty ? 'Thành viên yêu ẩm thực' : member.email,
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: locked
                  ? null
                  : () =>
                        _run(() => ref.read(authRepositoryProvider).signOut()),
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
            ),
            TextButton(
              onPressed: locked
                  ? null
                  : () => _run(() async {
                      await ref
                          .read(blogRepositoryProvider)
                          .unblockAll(member.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã bỏ chặn các tác giả.'),
                          ),
                        );
                      }
                    }),
              child: const Text('Bỏ chặn tất cả'),
            ),
            TextButton(
              onPressed: locked ? null : () => _delete(member),
              child: const Text('Xóa tài khoản'),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
