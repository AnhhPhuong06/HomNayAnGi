import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/providers.dart';
import 'core/services/local_store.dart';
import 'core/services/firebase_bootstrap.dart';
import 'features/auth/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final communityReady = await initializeCommunity();
  try {
    final store = LocalStore(await SharedPreferences.getInstance());
    var settings = const LocalSettings();
    String? notice;
    try {
      settings = store.read();
    } on StorageFailure catch (e) {
      notice = e.message;
    }
    runApp(
      ProviderScope(
        overrides: [
          backendReadyProvider.overrideWithValue(communityReady),
          localStoreProvider.overrideWithValue(store),
          initialSettingsProvider.overrideWithValue(settings),
          startupNoticeProvider.overrideWithValue(notice),
        ],
        child: const MealApp(),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Không thể mở bộ nhớ ứng dụng. Hãy thử lại.'),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: main, child: const Text('Thử lại')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
