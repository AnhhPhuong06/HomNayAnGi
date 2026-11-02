import 'package:flutter/material.dart';

/// Lazy rows with natural height: long titles and large text cannot overflow
/// a fixed grid aspect ratio. The available pane width determines the columns.
class AdaptiveCards extends StatelessWidget {
  const AdaptiveCards({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final minWidth = scale > 1.4 ? 480.0 : 300.0;
      final columns = ((constraints.crossAxisExtent + 16) / (minWidth + 16))
          .floor()
          .clamp(1, itemCount.clamp(1, 3));
      return SliverList.builder(
        itemCount: (itemCount / columns).ceil(),
        itemBuilder: (context, row) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var col = 0; col < columns; col++) ...[
              if (col > 0) const SizedBox(width: 16),
              Expanded(
                child: row * columns + col < itemCount
                    ? itemBuilder(context, row * columns + col)
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    },
  );
}
