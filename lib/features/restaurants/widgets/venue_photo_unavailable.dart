import 'package:flutter/material.dart';

class VenuePhotoUnavailable extends StatelessWidget {
  const VenuePhotoUnavailable({super.key, this.failed = false});
  final bool failed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Icon(
          Icons.storefront_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            failed
                ? 'Ảnh tại quán tạm chưa tải được.'
                : 'Quán chưa có ảnh thực tế.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    ),
  );
}
