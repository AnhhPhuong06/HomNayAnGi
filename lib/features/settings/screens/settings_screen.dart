import 'package:flutter/material.dart';
import '../appearance_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../home/widgets/filter_sheet.dart';
import '../../home/widgets/location_sheet.dart';
import '../../auth/account_section.dart';
import 'taste_sheet.dart';
import '../cloud_backup_section.dart';
import '../../auth/auth_repository.dart';

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
            const AccountSection(),
            CloudBackupSection(
              key: ValueKey(ref.watch(memberProvider).asData?.value?.id),
            ),
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
            const AppearanceSection(),
            const SizedBox(height: 28),
            const SectionTitle('Vị trí & sở thích'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restaurant_menu_rounded),
              title: const Text('Khẩu vị của bạn'),
              subtitle: Text(
                '${settings.taste.dislikedCategories.length} kiểu món muốn tránh · ${settings.taste.hiddenRestaurantIds.length} quán đã ẩn',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showTastePreferences(context),
            ),
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
                    'Ứng dụng dùng Firebase Authentication để đăng nhập bằng Google, Facebook hoặc Apple. Ứng dụng không nhận mật khẩu nhà cung cấp. Phiên đăng nhập được SDK lưu trên thiết bị.\n\n'
                    'Tên hiển thị, nội dung và quán/khu vực bạn đính kèm bài blog được lưu trên Cloud Firestore và hiển thị cho thành viên khác. Khi chia sẻ địa điểm mới, tọa độ quán bạn chủ động chọn hoặc nhập cũng được công khai trong bài viết và mục Cộng đồng. Email không được ghi vào bài blog. Bạn có thể xóa bài và tài khoản trong ứng dụng. Báo cáo và danh sách chặn chỉ được bạn và người quản trị truy cập.\n\n'
                    'Vị trí chỉ được xin khi bạn chọn dùng GPS. Tọa độ GPS chỉ giữ trong phiên; ứng dụng không tự điền hay tự đăng GPS khi chia sẻ địa điểm. '
                    'Khu vực chọn thủ công, yêu thích, khẩu vị, cài đặt và tối đa 20 gợi ý được lưu trên thiết bị. Dữ liệu cá nhân được tách theo tài khoản. Khi bạn bấm Lưu lên tài khoản, yêu thích, lịch sử, bộ lọc và khẩu vị được gửi tới Cloud Firestore, chỉ tài khoản đó được truy cập. GPS, khu vực và giao diện không nằm trong bản sao lưu.\n\n'
                    'Khi mở chế độ Bản đồ trong Khám phá hoặc chọn ghim quán, ứng dụng tải nền từ máy chủ OpenStreetMap. Máy chủ bản đồ nhận địa chỉ IP và các ô bản đồ của vùng đang xem. Danh sách quán vẫn hoạt động ngoại tuyến.\n\n'
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
