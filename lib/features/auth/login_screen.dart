import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/editorial.dart';
import 'auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;
  String? _message;
  Future<void> _signIn(SocialProvider provider) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(provider);
    } catch (e) {
      if (mounted) setState(() => _message = accountError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(backendReadyProvider);
    final s = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: [
              const AppBrand(),
              const SizedBox(height: 24),
              const _WelcomePanel(),
              const SizedBox(height: 24),
              Text(
                'Bữa ngon bắt đầu từ đây',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Chọn món hợp ý. Lưu quán yêu thích. Chia sẻ chuyện ăn ngon.',
                style: TextStyle(color: s.onSurfaceVariant, height: 1.6),
              ),
              const SizedBox(height: 20),
              if (!ready)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: s.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: s.onSecondaryContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dịch vụ tài khoản chưa sẵn sàng. Vui lòng liên hệ người quản trị ứng dụng.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.6,
                            color: s.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              for (final (provider, icon, label, color) in [
                (
                  SocialProvider.google,
                  Icons.g_mobiledata,
                  'Tiếp tục với Google',
                  const Color(0xff4285f4),
                ),
                (
                  SocialProvider.facebook,
                  Icons.facebook,
                  'Tiếp tục với Facebook',
                  const Color(0xff1877f2),
                ),
                (
                  SocialProvider.apple,
                  Icons.apple,
                  'Tiếp tục với Apple',
                  s.onSurface,
                ),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton(
                    onPressed: !ready || _busy ? null : () => _signIn(provider),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: s.surfaceContainerLow,
                      disabledForegroundColor: s.onSurfaceVariant.withValues(
                        alpha: .7,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 27,
                          color: ready && !_busy ? color : s.onSurfaceVariant,
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text(label)),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 17,
                          color: s.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: s.error),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color: s.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mật khẩu của bạn được giữ bởi nhà cung cấp đăng nhập. Tên hiển thị và bài bạn đăng sẽ xuất hiện trong blog.',
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.6,
                        color: s.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(30),
    child: Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [.25, 1],
                colors: [const Color(0xff275b42), const Color(0xff102b20)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffe4f2c9),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Eyebrow(
                  'ĂN NGON MỖI NGÀY',
                  color: Color(0xff24432d),
                ),
              ),
              const SizedBox(height: 86),
              Text(
                'Một bữa ngon.\nMột ngày vui.',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 30,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
