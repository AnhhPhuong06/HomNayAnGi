import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import 'location_sheet.dart';

class ChooseButton extends ConsumerStatefulWidget {
  const ChooseButton({super.key, this.label = 'CHỌN GIÚP TÔI'});
  final String label;
  @override
  ConsumerState<ChooseButton> createState() => _ChooseButtonState();
}

class _ChooseButtonState extends ConsumerState<ChooseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _busy = false;
  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    if (_busy || ref.read(recommendationProvider).busy) return;
    setState(() => _busy = true);
    if (!ref.read(repositoryProvider).isDemo &&
        ref.read(settingsProvider).location == null) {
      await showLocationPicker(context);
      if (!mounted) return;
      if (ref.read(settingsProvider).location == null) {
        setState(() => _busy = false);
        return;
      }
    }
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final operation = ref.read(recommendationProvider.notifier).choose();
    if (!reduceMotion) {
      try {
        await _animation.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
    }
    final success = await operation;
    if (!mounted) return;
    setState(() => _busy = false);
    if (success) {
      if (GoRouterState.of(context).uri.path != '/result') {
        context.push('/result');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(recommendationProvider).message ??
                'Chưa có gợi ý. Hãy thử lại.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerBusy = ref.watch(
      recommendationProvider.select((s) => s.busy),
    );
    final busy = _busy || controllerBusy;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: busy ? null : _choose,
        icon: const Icon(Icons.casino_outlined),
        label: AnimatedBuilder(
          animation: _animation,
          builder: (_, child) {
            const dishes = [
              'Phở thơm nóng…',
              'Cơm ngon…',
              'Bún bò…',
              'Lẩu nghi ngút…',
              'Bánh mì giòn…',
            ];
            return Text(
              busy
                  ? dishes[(_animation.value * dishes.length).floor().clamp(
                      0,
                      dishes.length - 1,
                    )]
                  : widget.label,
            );
          },
        ),
      ),
    );
  }
}
