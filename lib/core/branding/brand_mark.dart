import 'package:flutter/material.dart';

/// Selected Facebook artwork is bundled unchanged and works offline.
abstract final class BrandArtwork {
  static const asset = 'assets/branding/facebook-logo-source.png';
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Logo Hôm Nay Ăn Gì',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * .24),
      child: Image.asset(
        BrandArtwork.asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    ),
  );
}
