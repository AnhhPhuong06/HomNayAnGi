import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../services/maps_service.dart';

class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: child,
    ),
  );
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.ramen_dining,
    this.action,
    this.onAction,
  });
  final String title, message;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}

class DataSourceNotice extends ConsumerWidget {
  const DataSourceNotice({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(repositoryProvider).isDemo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(demo ? Icons.science_outlined : Icons.public, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  demo
                      ? 'DEMO DATA · Quán, giá và đánh giá là dữ liệu minh họa. Không dùng để đi ăn thực tế.'
                      : 'Dữ liệu quán từ OpenStreetMap. Thông tin cộng đồng có thể thiếu hoặc đã thay đổi; hãy kiểm tra trước khi đến.',
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
          if (!demo)
            TextButton(
              onPressed: () async {
                final opened = await MapsService().openDataLicense();
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không mở được trang nguồn dữ liệu.'),
                    ),
                  );
                }
              },
              child: const Text('© OpenStreetMap contributors · ODbL'),
            ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}
