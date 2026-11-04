import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/app_navigation.dart';
import 'update_controller.dart';
import 'update_models.dart';
import 'update_repository.dart';

class UpdatePromptHost extends ConsumerStatefulWidget {
  const UpdatePromptHost({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<UpdatePromptHost> createState() => _UpdatePromptHostState();
}

class _UpdatePromptHostState extends ConsumerState<UpdatePromptHost>
    with WidgetsBindingObserver {
  bool _dialogOpen = false;
  UpdateState? _pendingPrompt;
  int _navigationRetries = 0;
  void _schedulePrompt() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_showPending());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(updateControllerProvider.notifier).check());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(ref.read(updateControllerProvider.notifier).check());
      _navigationRetries = 0;
      if (_pendingPrompt != null) _schedulePrompt();
    }
  }

  Future<void> _showPending() async {
    final state = _pendingPrompt;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!mounted ||
        _dialogOpen ||
        state == null ||
        state.release == null ||
        state.app == null ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
      return;
    }
    final context = ref.read(appNavigatorKeyProvider).currentContext;
    if (context == null) {
      if (_navigationRetries++ < 2) _schedulePrompt();
      return;
    }
    _pendingPrompt = null;
    _dialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        builder: (_) =>
            AppUpdateDialog(release: state.release!, installed: state.app!),
      );
      if (mounted) {
        await ref
            .read(updateControllerProvider.notifier)
            .remindLater(state.release);
      }
    } finally {
      _dialogOpen = false;
      if (mounted && _pendingPrompt != null) _schedulePrompt();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(updateControllerProvider, (previous, next) {
      if (next.prompt != (previous?.prompt ?? 0) && next.release != null) {
        _pendingPrompt = next;
        _navigationRetries = 0;
        _schedulePrompt();
      }
    });
    return widget.child;
  }
}

class AppUpdateDialog extends StatefulWidget {
  const AppUpdateDialog({
    super.key,
    required this.release,
    required this.installed,
  });
  final AppRelease release;
  final InstalledApp installed;
  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _opening = false;
  String? _error;
  Future<void> _open() async {
    setState(() {
      _opening = true;
      _error = null;
    });
    var success = false;
    try {
      success = await launchUrl(
        widget.release.url,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        _opening = false;
        _error = 'Không mở được trang cập nhật. Hãy thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Có phiên bản mới'),
    scrollable: true,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Bản mới: ${widget.release.version.name} (${widget.release.version.build})',
        ),
        Text(
          'Đang dùng: ${widget.installed.version.name} (${widget.installed.version.build})',
        ),
        if (widget.release.notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(widget.release.notes),
        ],
        if (widget.release.manual) ...[
          const SizedBox(height: 12),
          Text(
            widget.release.channel == UpdateChannel.iosManual
                ? 'Bản cài này cập nhật thủ công. Mở trang phát hành để tải bản mới; IPA cần được ký trước khi cài.'
                : 'Mở trang phát hành để xem và tải bản cài mới. Bạn sẽ tự xác nhận việc cài đặt.',
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: _opening ? null : () => Navigator.pop(context),
        child: const Text('Nhắc sau'),
      ),
      FilledButton(
        onPressed: _opening ? null : _open,
        child: Text(_opening ? 'Đang mở…' : 'Cập nhật'),
      ),
    ],
  );
}

class AppUpdateSection extends ConsumerWidget {
  const AppUpdateSection({super.key, required this.catalogSummary});
  final String catalogSummary;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(installedAppProvider).asData?.value;
    final state = ref.watch(updateControllerProvider);
    final checking = state.status == UpdateStatus.checking;
    final message = switch (state.status) {
      UpdateStatus.idle => 'Kiểm tra và nhận nhắc khi có phiên bản mới.',
      UpdateStatus.checking => 'Đang kiểm tra phiên bản mới…',
      UpdateStatus.available =>
        'Có bản ${state.release!.version.name} (${state.release!.version.build}).',
      UpdateStatus.current => 'Chưa có phiên bản mới hơn bản đang dùng.',
      UpdateStatus.unconfigured =>
        'Chưa có bản phát hành cho kênh cài đặt này.',
      UpdateStatus.unavailable =>
        'Chưa kiểm tra được phiên bản mới. Vui lòng thử lại.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.restaurant_menu),
          title: const Text('Hôm Nay Ăn Gì?'),
          subtitle: Text(
            '${app == null ? 'Phiên bản chưa xác định' : 'Phiên bản ${app.version.name} (${app.version.build})'} · $catalogSummary',
          ),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Nhắc khi có bản mới'),
          subtitle: const Text(
            'Kiểm tra khi mở hoặc quay lại app; “Nhắc sau” hoãn 24 giờ.',
          ),
          value: state.automatic,
          onChanged: (value) async {
            try {
              await ref
                  .read(updateControllerProvider.notifier)
                  .setAutomatic(value);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chưa lưu được lựa chọn nhắc cập nhật.'),
                  ),
                );
              }
            }
          },
        ),
        Text(message),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: checking
              ? null
              : () => ref
                    .read(updateControllerProvider.notifier)
                    .check(manual: true),
          icon: const Icon(Icons.system_update_outlined),
          label: const Text('Kiểm tra cập nhật'),
        ),
      ],
    );
  }
}
