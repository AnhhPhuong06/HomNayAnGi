import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/appearance.dart';

class MealApp extends ConsumerWidget {
  const MealApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(settingsProvider.select((s) => s.appearance));
    return MaterialApp.router(
      title: 'Hôm Nay Ăn Gì?',
      debugShowCheckedModeBanner: false,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: appTheme(Brightness.light, accent: appearance.accent),
      darkTheme: appTheme(Brightness.dark, accent: appearance.accent),
      themeAnimationDuration: appearance.reduceMotion || reducedMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: PersonalTextScaler(
              media.textScaler,
              appearance.textSize,
            ),
            disableAnimations:
                media.disableAnimations ||
                appearance.reduceMotion ||
                View.of(
                  context,
                ).platformDispatcher.accessibilityFeatures.reduceMotion,
          ),
          child: child!,
        );
      },
      themeMode: ref.watch(settingsProvider.select((s) => s.theme)),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
