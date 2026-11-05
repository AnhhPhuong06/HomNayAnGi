import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/restaurant_photo.dart';
import 'venue_photo_unavailable.dart';

class VenuePhoto extends StatelessWidget {
  const VenuePhoto({super.key, required this.photo, required this.height});
  final RestaurantPhoto photo;
  final double height;

  Future<void> _open(BuildContext context, String url) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được nguồn ảnh. Hãy thử lại.')),
      );
    }
  }

  void _details(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheet).height * .8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nguồn ảnh tại quán',
                  style: Theme.of(sheet).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SelectableText(photo.caption),
                const SizedBox(height: 12),
                Text('Tác giả: ${photo.author}'),
                Text('Giấy phép: ${photo.license}'),
                Text('Ngày chụp theo nguồn: ${photo.capturedAt}'),
                Text('Đối chiếu với quán: ${photo.checkedAt}'),
                const SizedBox(height: 12),
                const Text(
                  'Ảnh được thu nhỏ, cắt theo khung hiển thị. Hình ảnh phản ánh thời điểm chụp; không xác nhận diện mạo hoặc tình trạng hoạt động hiện tại.',
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _open(sheet, photo.sourceUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Ảnh gốc trên Wikimedia Commons'),
                ),
                TextButton.icon(
                  onPressed: () => _open(sheet, photo.licenseUrl),
                  icon: const Icon(Icons.copyright_outlined),
                  label: Text('Xem giấy phép ${photo.license}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Image.asset(
    photo.asset,
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
    cacheWidth: 1000,
    semanticLabel: photo.caption,
    errorBuilder: (_, error, stack) =>
        const VenuePhotoUnavailable(failed: true),
    frameBuilder: (context, child, frame, synchronous) {
      if (frame == null && !synchronous) {
        return SizedBox(
          height: height,
          width: double.infinity,
          child: const Center(child: Icon(Icons.photo_outlined, size: 32)),
        );
      }
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Material(
                color: Colors.black.withValues(alpha: .78),
                child: InkWell(
                  onTap: () => _details(context),
                  child: Semantics(
                    button: true,
                    label:
                        'Nguồn ảnh tại quán: ${photo.author}, ${photo.license}',
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Ảnh tại quán · ${photo.author} · ${photo.license}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
