import 'package:flutter/material.dart';
import '../../restaurants/models/food_category.dart';
import '../../restaurants/widgets/dish_photo.dart';

class CategoryStrip extends StatelessWidget {
  const CategoryStrip({
    super.key,
    required this.selected,
    required this.onToggle,
  });
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in foodCategories)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Semantics(
                button: true,
                selected: selected.contains(c.id),
                label: c.name,
                child: SizedBox(
                  width: 94,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onToggle(c.id),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: selected.contains(c.id)
                                    ? s.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                dishPhotoAsset([c.id]),
                                height: 72,
                                width: 72,
                                fit: BoxFit.cover,
                                cacheWidth: 220,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          ExcludeSemantics(
                            child: Text(
                              c.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: selected.contains(c.id)
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 11,
                                color: selected.contains(c.id)
                                    ? s.primary
                                    : s.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
