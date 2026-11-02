import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/discover/screens/discover_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/recommendation/screens/result_screen.dart';
import '../../features/restaurants/screens/restaurant_detail_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../providers.dart';
import '../widgets/common.dart';
import '../branding/brand_mark.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/auth/login_screen.dart';
import '../../features/blog/blog_screen.dart';
import '../../features/blog/blog_repository.dart';
import '../../features/blog/compose_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(memberProvider, (_, _) => refresh.value++);
  final router = GoRouter(
    refreshListenable: refresh,
    redirect: (_, state) {
      if (!ref.read(authenticationRequiredProvider)) return null;
      final loggedIn = ref.read(memberProvider).asData?.value != null;
      if (!loggedIn && state.matchedLocation != '/login') return '/login';
      if (loggedIn && state.matchedLocation == '/login') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (_, state) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (_, state) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (_, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/blog', builder: (_, _) => const BlogScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/result', builder: (_, state) => const ResultScreen()),
      GoRoute(
        path: '/blog/new',
        builder: (_, state) => ComposeScreen(
          kind: state.uri.queryParameters['kind'] == 'restaurant'
              ? PostKind.restaurant
              : state.uri.queryParameters['kind'] == 'place'
              ? PostKind.place
              : PostKind.meal,
          restaurantId: state.uri.queryParameters['restaurant'],
        ),
      ),
      GoRoute(
        path: '/restaurant/:id',
        builder: (_, state) =>
            RestaurantDetailScreen(id: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: EmptyMessage(
        title: 'Không tìm thấy trang.',
        message: 'Hãy quay về để chọn một bữa ngon.',
        action: 'Về trang chủ',
        onAction: () => context.go('/'),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  ref.onDispose(refresh.dispose);
  return router;
});

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(storageErrorProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final rail =
            constraints.maxWidth >= 720 ||
            (constraints.maxWidth >= 600 &&
                constraints.maxHeight >= 300 &&
                constraints.maxHeight < 480);
        final extended =
            constraints.maxWidth >= 1200 && constraints.maxHeight >= 600;
        final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
        final colors = Theme.of(context).colorScheme;
        void select(int index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex);
        const items = [
          (Icons.home_outlined, Icons.home, 'Trang chủ'),
          (Icons.explore_outlined, Icons.explore, 'Khám phá'),
          (Icons.favorite_border, Icons.favorite, 'Yêu thích'),
          (Icons.article_outlined, Icons.article, 'Blog'),
          (Icons.settings_outlined, Icons.settings, 'Cài đặt'),
        ];
        return Scaffold(
          body: Row(
            children: [
              if (rail) ...[
                SafeArea(
                  child: NavigationRail(
                    extended: extended,
                    minExtendedWidth: 208,
                    scrollable: true,
                    groupAlignment: -1,
                    backgroundColor: colors.surface,
                    selectedIndex: shell.currentIndex,
                    onDestinationSelected: select,
                    labelType: extended || largeText
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: BrandMark(size: 42),
                    ),
                    destinations: [
                      for (final (icon, selected, label) in items)
                        NavigationRailDestination(
                          icon: Icon(icon),
                          selectedIcon: Icon(selected),
                          label: Text(label),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(
                child: Column(
                  children: [
                    if (error != null)
                      SafeArea(
                        bottom: false,
                        child: MaterialBanner(
                          content: Text(error),
                          actions: [
                            TextButton(
                              onPressed: () => ref
                                  .read(settingsProvider.notifier)
                                  .retrySave(),
                              child: const Text('Lưu lại'),
                            ),
                          ],
                        ),
                      ),
                    Expanded(child: shell),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: rail
              ? null
              : SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .035),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: NavigationBar(
                        animationDuration:
                            MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        labelBehavior: constraints.maxWidth < 360 || largeText
                            ? NavigationDestinationLabelBehavior
                                  .onlyShowSelected
                            : NavigationDestinationLabelBehavior.alwaysShow,
                        selectedIndex: shell.currentIndex,
                        onDestinationSelected: (index) => shell.goBranch(
                          index,
                          initialLocation: index == shell.currentIndex,
                        ),
                        destinations: const [
                          NavigationDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home),
                            label: 'Trang chủ',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.explore_outlined),
                            selectedIcon: Icon(Icons.explore),
                            label: 'Khám phá',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.favorite_border),
                            selectedIcon: Icon(Icons.favorite),
                            label: 'Yêu thích',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.article_outlined),
                            selectedIcon: Icon(Icons.article),
                            label: 'Blog',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.settings_outlined),
                            selectedIcon: Icon(Icons.settings),
                            label: 'Cài đặt',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
