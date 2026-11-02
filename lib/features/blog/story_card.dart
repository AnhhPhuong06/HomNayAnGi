import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/maps_service.dart';
import '../restaurants/widgets/dish_photo.dart';
import 'blog_repository.dart';

class BlogStoryCard extends StatelessWidget {
  const BlogStoryCard({
    super.key,
    required this.post,
    required this.own,
    required this.busy,
    required this.onAction,
  });
  final BlogPost post;
  final bool own, busy;
  final ValueChanged<String> onAction;
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final p = post;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: s.primaryContainer,
                  foregroundColor: s.primary,
                  child: Text(
                    p.authorName.trim().isEmpty
                        ? 'B'
                        : p.authorName.trim().characters.first.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        p.kind.label,
                        style: TextStyle(
                          color: s.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  enabled: !busy,
                  tooltip: 'Tùy chọn bài viết',
                  onSelected: onAction,
                  itemBuilder: (_) => [
                    if (own)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa bài'),
                      ),
                    if (!own) ...[
                      const PopupMenuItem(
                        value: 'report',
                        child: Text('Báo cáo bài viết'),
                      ),
                      const PopupMenuItem(
                        value: 'block',
                        child: Text('Chặn tác giả'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: DishPhoto(categories: [p.category], height: 190),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title, style: Theme.of(context).textTheme.titleLarge),
                if (p.kind == PostKind.place)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Địa điểm do thành viên chia sẻ · Chưa xác minh',
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  p.body,
                  style: TextStyle(height: 1.8, color: s.onSurfaceVariant),
                ),
                if (p.restaurantName.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: s.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: s.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${p.restaurantName}${p.area.isEmpty ? '' : ' · ${p.area}'}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (p.restaurantId.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => context.push(
                        '/restaurant/${Uri.encodeComponent(p.restaurantId)}',
                      ),
                      icon: const Icon(Icons.north_east, size: 15),
                      label: const Text('Xem quán & chỉ đường'),
                    ),
                  if (p.place != null && !p.pending)
                    TextButton.icon(
                      onPressed: () async {
                        final opened = await MapsService().sharedPlace(
                          p.place!,
                        );
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Chưa mở được bản đồ. Hãy thử lại.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.directions_outlined),
                      label: const Text('Chỉ đường đến địa điểm'),
                    ),
                ],
                const SizedBox(height: 14),
                Text(
                  p.pending
                      ? 'Đang chờ đồng bộ — bài chưa được xác nhận trên máy chủ'
                      : p.createdAt == null
                      ? 'Đang cập nhật thời gian'
                      : '${p.createdAt!.day}/${p.createdAt!.month}/${p.createdAt!.year}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
