import 'package:flutter/material.dart';
import '../../restaurants/models/food_category.dart';

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
                            child: Container(
                              height: 72,
                              width: 72,
                              decoration: BoxDecoration(
                                color: s.primaryContainer,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: ExcludeSemantics(
                                  child: Icon(
                                    switch (c.id) {
                                      'noodles' => Icons.ramen_dining_outlined,
                                      'rice' => Icons.rice_bowl_outlined,
                                      'hotpot' => Icons.soup_kitchen_outlined,
                                      'grill' => Icons.outdoor_grill_outlined,
                                      'snacks' => Icons.tapas_outlined,
                                      'bread' => Icons.bakery_dining_outlined,
                                      'healthy' => Icons.eco_outlined,
                                      'cafe' => Icons.local_cafe_outlined,
                                      'dessert' => Icons.icecream_outlined,
                                      'late' => Icons.nights_stay_outlined,
                                      _ => Icons.restaurant_outlined,
                                    },
                                    size: 30,
                                    color: s.primary,
                                  ),
                                ),
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
