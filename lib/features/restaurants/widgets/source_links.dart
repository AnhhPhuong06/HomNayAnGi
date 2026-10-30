import 'package:flutter/material.dart';
import '../../../core/services/maps_service.dart';
import '../models/restaurant.dart';
import '../models/source_link.dart';

class RestaurantSourceLinks extends StatefulWidget {
  const RestaurantSourceLinks({super.key, required this.restaurant});
  final Restaurant restaurant;
  @override
  State<RestaurantSourceLinks> createState() => _RestaurantSourceLinksState();
}

class _RestaurantSourceLinksState extends State<RestaurantSourceLinks> {
  bool _busy = false;
  Future<void> _open(Future<bool> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final success = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được liên kết. Hãy thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    final source = SourceLink.fromJson({
      'platform': 'openStreetMap',
      'url': r.sourceUrl,
      'label': 'Xem bản ghi OpenStreetMap',
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (source != null)
          TextButton.icon(
            onPressed: _busy
                ? null
                : () => _open(() => MapsService().openSource(source)),
            icon: const Icon(Icons.source_outlined),
            label: const Text('Xem nguồn OpenStreetMap'),
          ),
        if (r.sourceUpdatedAt != null)
          Text(
            'Bản ghi nguồn cập nhật: ${r.sourceUpdatedAt!.split('T').first}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        for (final link in r.sourceLinks)
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _open(() => MapsService().openSource(link)),
            icon: const Icon(Icons.open_in_new),
            label: Text(link.label),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => _open(() => MapsService().searchTikTok(r)),
          icon: const Icon(Icons.search),
          label: const Text('Tìm video trên TikTok'),
        ),
        const SizedBox(height: 6),
        const Text(
          'Mở trang tìm kiếm TikTok theo tên quán và khu vực; chưa phải video review đã đối chiếu.',
          style: TextStyle(fontSize: 12, height: 1.5),
        ),
      ],
    );
  }
}
