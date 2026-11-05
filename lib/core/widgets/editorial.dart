import 'package:flutter/material.dart';
import '../branding/brand_mark.dart';

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.label, {super.key, this.color});
  final String label;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
      color: color ?? Theme.of(context).colorScheme.primary,
    ),
  );
}

class AppBrand extends StatelessWidget {
  const AppBrand({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BrandMark(),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Hôm Nay Ăn Gì?',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class PageIntro extends StatelessWidget {
  const PageIntro({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
  });
  final String eyebrow, title, description;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Eyebrow(eyebrow),
      const SizedBox(height: 8),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      Text(
        description,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.6,
        ),
      ),
    ],
  );
}

class MealIntroHero extends StatelessWidget {
  const MealIntroHero({
    super.key,
    required this.title,
    required this.eyebrow,
    this.description,
    this.action,
  });
  final String title, eyebrow;
  final String? description;
  final Widget? action;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(30),
    child: Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xff143a29), const Color(0xff0b241b)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    color: Color(0xffd6eead),
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Eyebrow(eyebrow, color: const Color(0xffd6eead)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(color: Colors.white),
              ),
              if (description != null) ...[
                const SizedBox(height: 12),
                Text(
                  description!,
                  style: const TextStyle(color: Color(0xffe0e9dc), height: 1.6),
                ),
              ],
              const SizedBox(height: 20),
              if (action != null) ...[
                FilledButtonTheme(
                  data: FilledButtonThemeData(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xffd6eead),
                      foregroundColor: const Color(0xff193222),
                      disabledBackgroundColor: const Color(0xffa2b890),
                      disabledForegroundColor: const Color(0xff193222),
                      minimumSize: const Size(48, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  child: action!,
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
