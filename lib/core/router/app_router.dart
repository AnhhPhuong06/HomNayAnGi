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

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
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
  return router;
});

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(storageErrorProvider);
    return Scaffold(
      body: Column(
        children: [
          if (error != null)
            SafeArea(
              bottom: false,
              child: MaterialBanner(
                content: Text(error),
                actions: [
                  TextButton(
                    onPressed: () =>
                        ref.read(settingsProvider.notifier).retrySave(),
                    child: const Text('Lưu lại'),
                  ),
                ],
              ),
            ),
          Expanded(child: shell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
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
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
