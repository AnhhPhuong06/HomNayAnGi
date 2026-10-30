import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../home/widgets/filter_sheet.dart';
import '../../home/widgets/location_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final demo = ref.watch(repositoryProvider).isDemo;
    final restaurantCount = ref.watch(
      restaurantsProvider.select((data) => data.asData?.value.length),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionTitle('Giao diện'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mode in ThemeMode.values)
                  ChoiceChip(
                    label: Text(switch (mode) {
                      ThemeMode.system => 'Theo hệ thống',
                      ThemeMode.light => 'Sáng',
                      ThemeMode.dark => 'Tối',
                    }),
                    selected: settings.theme == mode,
                    onSelected: (_) =>
                        ref.read(settingsProvider.notifier).setTheme(mode),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            const SectionTitle('Vị trí & sở thích'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Khu vực của bạn'),
              subtitle: Text(settings.location?.label ?? 'Chưa chọn vị trí'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLocationPicker(context),
            ),
            if (settings.location != null)
              TextButton.icon(
                onPressed: () =>
                    ref.read(settingsProvider.notifier).clearLocation(),
                icon: const Icon(Icons.location_off_outlined),
                label: const Text('Xóa vị trí đã chọn'),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune),
              title: const Text('Ngân sách & khoảng cách mặc định'),
              subtitle: const Text('Dùng chung cho gợi ý và khám phá'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showFilters(context),
            ),
            const SizedBox(height: 28),
            const SectionTitle('Về ứng dụng'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('Hôm Nay Ăn Gì?'),
              subtitle: Text(
                demo
                    ? 'Phiên bản 1.0.0 · Dữ liệu demo'
                    : 'Phiên bản 1.0.0 · ${restaurantCount ?? "…"} quán từ dữ liệu mở Việt Nam',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Chính sách quyền riêng tư'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Quyền riêng tư'),
                  scrollable: true,
                  content: const Text(
                    'Ứng dụng không có tài khoản, quảng cáo, analytics hay theo dõi nền.\n\n'
                    'Vị trí chỉ được xin khi bạn chọn dùng GPS. Tọa độ GPS chỉ giữ trong phiên; không được gửi đến máy chủ của ứng dụng. '
                    'Khu vực chọn thủ công, yêu thích, cài đặt và tối đa 20 gợi ý được lưu trên thiết bị.\n\n'
                    'Khi mở chỉ đường, tọa độ đích được chuyển cho Google Maps hoặc trình duyệt; dịch vụ đó áp dụng chính sách riêng. '
                    'Danh mục quán đi kèm app hoạt động ngoại tuyến. Dữ liệu thật có nguồn từ OpenStreetMap; chế độ demo được đánh dấu riêng. '
                    'Khi bạn bấm liên kết TikTok hoặc nguồn dữ liệu, ứng dụng mở dịch vụ ngoài với tên quán hoặc đường dẫn tương ứng; chính sách của dịch vụ đó được áp dụng.\n\n'
                    'Bạn có thể xóa vị trí trong Cài đặt hoặc xóa dữ liệu ứng dụng từ cài đặt thiết bị.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đã hiểu'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const DataSourceNotice(),
          ],
        ),
      ),
    );
  }
}
