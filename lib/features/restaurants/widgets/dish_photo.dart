import 'package:flutter/material.dart';

String dishPhotoAsset(Iterable<String> categories) {
  const images = {
    'noodles': 'noodles',
    'rice': 'rice',
    'hotpot': 'hotpot',
    'grill': 'grill',
    'snacks': 'grill',
    'bread': 'bread',
    'healthy': 'salad',
    'cafe': 'cafe',
    'dessert': 'dessert',
    'late': 'noodles',
  };
  final name = categories
      .map((id) => images[id])
      .whereType<String>()
      .firstOrNull;
  return 'assets/images/${name ?? 'rice'}.jpg';
}

class DishPhoto extends StatelessWidget {
  const DishPhoto({super.key, required this.categories, this.height = 160});
  final Iterable<String> categories;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          dishPhotoAsset(categories),
          fit: BoxFit.cover,
          cacheWidth: 1000,
          semanticLabel: 'Ảnh món ăn minh họa, không phải ảnh của quán',
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              child: Text(
                'Ảnh món ăn minh họa',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
