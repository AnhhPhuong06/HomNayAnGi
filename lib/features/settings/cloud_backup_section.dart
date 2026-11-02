import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../auth/auth_repository.dart';
import '../auth/account_action_lock.dart';
import 'personal_backup.dart';

class CloudBackupSection extends ConsumerStatefulWidget {
  const CloudBackupSection({super.key});
  @override
  ConsumerState<CloudBackupSection> createState() => _CloudBackupSectionState();
}

class _CloudBackupSectionState extends ConsumerState<CloudBackupSection> {
  bool _busy = false;
  String? _notice;
  bool _same(String uid) =>
      mounted && ref.read(memberProvider).asData?.value?.id == uid;
  Future<bool> _confirm(String title, String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _run(String uid, Future<String?> Function() action) async {
    if (_busy) return;
    final lock = ref.read(accountActionLockProvider.notifier);
    if (!lock.begin()) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final notice = await action();
      if (_same(uid)) setState(() => _notice = notice);
    } catch (e) {
      if (_same(uid)) {
        setState(
          () => _notice = e is BackupConflict
              ? 'Bản sao lưu đã thay đổi trên thiết bị khác. Hãy thực hiện lại để xem bản mới nhất.'
              : e is FormatException
              ? e.message
              : 'Chưa kết nối được để đồng bộ. Dữ liệu trên máy vẫn được giữ; hãy thử lại khi có mạng.',
        );
      }
    } finally {
      lock.release();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(String uid) => _run(uid, () async {
    final snapshot = PersonalBackup.fromSettings(ref.read(settingsProvider));
    final repository = ref.read(personalBackupRepositoryProvider);
    final previous = await repository.load(uid);
    if (!_same(uid)) return null;
    if (previous != null &&
        !await _confirm(
          'Thay bản sao lưu trên tài khoản?',
          'Bản đang lưu có ${previous.favorites.length} quán yêu thích. Bản trên máy này có ${snapshot.favorites.length} quán. Tiếp tục sẽ thay bản trên tài khoản bằng dữ liệu trên máy này.',
        )) {
      return null;
    }
    if (!_same(uid)) return null;
    await repository.save(
      uid,
      snapshot,
      expectedRevision: previous?.revision ?? 0,
    );
    return 'Đã lưu lên tài khoản. Bạn có thể khôi phục trên thiết bị khác.';
  });
  Future<void> _restore(String uid) => _run(uid, () async {
    final backup = await ref.read(personalBackupRepositoryProvider).load(uid);
    if (!_same(uid)) return null;
    if (backup == null) {
      return 'Tài khoản chưa có bản sao lưu. Hãy chọn Lưu lên tài khoản trên thiết bị đang có dữ liệu.';
    }
    if (!await _confirm(
      'Khôi phục từ tài khoản?',
      'Thay yêu thích, lịch sử, bộ lọc và khẩu vị trên máy bằng bản lưu có ${backup.favorites.length} quán yêu thích. Khu vực và giao diện hiện tại được giữ.',
    )) {
      return null;
    }
    if (!_same(uid)) return null;
    await ref
        .read(settingsProvider.notifier)
        .restorePersonalData(
          favorites: backup.favorites,
          history: backup.history,
          preference: backup.preference,
          taste: backup.taste,
        );
    return 'Đã khôi phục dữ liệu trong ứng dụng.';
  });
  Future<void> _importLegacy(String uid) => _run(uid, () async {
    final old = ref.read(localStoreProvider).read();
    if (!await _confirm(
      'Nhập dữ liệu cũ trên máy?',
      'Thay dữ liệu cá nhân của tài khoản này bằng ${old.favorites.length} quán yêu thích và lịch sử từ phiên bản cũ trên thiết bị. Hãy chỉ nhập nếu đây là dữ liệu của bạn.',
    )) {
      return null;
    }
    if (!_same(uid)) return null;
    await ref
        .read(settingsProvider.notifier)
        .restorePersonalData(
          favorites: old.favorites,
          history: old.history,
          preference: old.preference,
          taste: old.taste,
        );
    return 'Đã nhập dữ liệu cũ vào tài khoản trên thiết bị này. Bấm Lưu lên tài khoản nếu muốn sao lưu.';
  });
  @override
  Widget build(BuildContext context) {
    final member = ref.watch(memberProvider).asData?.value;
    final locked = _busy || ref.watch(accountActionLockProvider);
    if (member == null || !ref.watch(backendReadyProvider)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Mang sở thích theo bạn'),
        const SizedBox(height: 10),
        const Text(
          'Sao lưu và khôi phục thủ công yêu thích, lịch sử, bộ lọc và khẩu vị. Khu vực, GPS và giao diện ở lại trên thiết bị.',
        ),
        const SizedBox(height: 12),
        if (_busy) const LinearProgressIndicator(),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: locked ? null : () => _save(member.id),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Lưu lên tài khoản'),
            ),
            OutlinedButton.icon(
              onPressed: locked ? null : () => _restore(member.id),
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Khôi phục từ tài khoản'),
            ),
          ],
        ),
        TextButton(
          onPressed: locked ? null : () => _importLegacy(member.id),
          child: const Text('Nhập dữ liệu từ phiên bản cũ trên máy'),
        ),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(liveRegion: true, child: Text(_notice!)),
          ),
        const SizedBox(height: 28),
      ],
    );
  }
}
