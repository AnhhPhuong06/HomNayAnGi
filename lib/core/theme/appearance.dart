import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

enum AppAccent { forest, ocean, berry }

extension AppAccentStyle on AppAccent {
  String get label => switch (this) {
    AppAccent.forest => 'Xanh rừng',
    AppAccent.ocean => 'Đại dương',
    AppAccent.berry => 'Dâu tím',
  };
  Color get color => switch (this) {
    AppAccent.forest => const Color(0xff24553d),
    AppAccent.ocean => const Color(0xff165c86),
    AppAccent.berry => const Color(0xff873f69),
  };
}

class Appearance {
  const Appearance({
    this.accent = AppAccent.forest,
    this.textSize = 1,
    this.compactCards = false,
    this.reduceMotion = false,
  });
  final AppAccent accent;
  // Multiplies the system scaler; it never caps the accessibility font size.
  final double textSize;
  final bool compactCards, reduceMotion;
  Appearance copyWith({
    AppAccent? accent,
    double? textSize,
    bool? compactCards,
    bool? reduceMotion,
  }) => Appearance(
    accent: accent ?? this.accent,
    textSize: textSize ?? this.textSize,
    compactCards: compactCards ?? this.compactCards,
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );
  Map<String, Object> toJson() => {
    'accent': accent.name,
    'textSize': textSize,
    'compactCards': compactCards,
    'reduceMotion': reduceMotion,
  };
  factory Appearance.fromJson(Object? value) {
    if (value is! Map) return const Appearance();
    final size = value['textSize'];
    return Appearance(
      accent:
          AppAccent.values
              .where((a) => a.name == value['accent'])
              .firstOrNull ??
          AppAccent.forest,
      textSize: size is num && const [1, 1.15, 1.3].contains(size)
          ? size.toDouble()
          : 1,
      compactCards: value['compactCards'] == true,
      reduceMotion: value['reduceMotion'] == true,
    );
  }
}

class PersonalTextScaler extends TextScaler {
  const PersonalTextScaler(this.system, this.multiplier);
  final TextScaler system;
  final double multiplier;
  @override
  double scale(double fontSize) => system.scale(fontSize) * multiplier;
  @override
  double get textScaleFactor => scale(14) / 14;
}

bool reducedMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;

class RespectfulCupertinoTransitions extends CupertinoPageTransitionsBuilder {
  const RespectfulCupertinoTransitions();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => reducedMotion(context)
      ? child
      : super.buildTransitions(
          route,
          context,
          animation,
          secondaryAnimation,
          child,
        );
}

class GentlePageTransitions extends PageTransitionsBuilder {
  const GentlePageTransitions();
  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reducedMotion(context)) return child;
    return FadeTransition(
      opacity: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
      child: SlideTransition(
        position: animation.drive(
          Tween(
            begin: const Offset(0, .025),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        ),
        child: child,
      ),
    );
  }
}
