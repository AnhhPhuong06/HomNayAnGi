import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hom_nay_an_gi/core/services/app_navigation.dart';
import 'package:hom_nay_an_gi/features/updates/update_controller.dart';
import 'package:hom_nay_an_gi/features/updates/update_models.dart';
import 'package:hom_nay_an_gi/features/updates/update_repository.dart';
import 'package:hom_nay_an_gi/features/updates/update_store.dart';
import 'package:hom_nay_an_gi/features/updates/update_widgets.dart';

const oldApp = InstalledApp(
  bundleId: 'vn.homnayangi.homNayAnGi',
  version: AppVersion(1, 1, 0, 2),
  channel: UpdateChannel.iosManual,
);
Map<String, dynamic> releaseData({
  String version = '1.2.0',
  int build = 3,
  String? url,
  String channel = 'iosManual',
}) => {
  'version': version,
  'build': build,
  'bundleId': oldApp.bundleId,
  'channel': channel,
  'url':
      url ??
      'https://github.com/AnhhPhuong06/HomNayAnGi/releases/tag/v$version+$build',
  'notes': 'Bổ sung ảnh và cải thiện trải nghiệm.',
};
UpdateManifest manifest({String version = '1.2.0', int build = 3}) =>
    UpdateManifest.parse({
      'schemaVersion': 1,
      'releases': [releaseData(version: version, build: build)],
    });

class MemoryUpdates extends UpdateStore {
  bool enabled = true;
  CachedUpdate? cache;
  String? snoozedKey;
  DateTime? until;
  @override
  Future<bool> automaticEnabled() async => enabled;
  @override
  Future<void> setAutomatic(bool value) async {
    enabled = value;
  }

  @override
  Future<CachedUpdate?> readCache() async => cache;
  @override
  Future<void> writeCache(UpdateManifest value, DateTime now) async {
    cache = CachedUpdate({
      'schemaVersion': 1,
      'releases': [
        for (final r in value.releases)
          {
            'bundleId': r.bundleId,
            'version': r.version.name,
            'build': r.version.build,
            'url': r.url.toString(),
            'notes': r.notes,
            'channel': r.channel.name,
          },
      ],
    }, now);
  }

  @override
  Future<bool> isSnoozed(String key, DateTime now) async =>
      key == snoozedKey && until != null && until!.isAfter(now);
  @override
  Future<void> snooze(String key, DateTime now) async {
    snoozedKey = key;
    until = now.add(const Duration(hours: 24));
  }
}

class FakeUpdates extends UpdateRepository {
  UpdateManifest response = manifest();
  int calls = 0;
  Object? failure;
  Completer<UpdateManifest>? pending;
  @override
  Future<UpdateManifest> fetch() async {
    calls++;
    if (failure != null) throw failure!;
    return pending?.future ?? response;
  }
}

ProviderContainer containerFor(
  FakeUpdates repository,
  MemoryUpdates store,
  DateTime Function() clock, {
  InstalledApp? app = oldApp,
}) {
  final container = ProviderContainer(
    overrides: [
      updateRepositoryProvider.overrideWithValue(repository),
      updateStoreProvider.overrideWithValue(store),
      updateClockProvider.overrideWithValue(clock),
      installedAppProvider.overrideWith((ref) async => app),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'manual iOS builds opt in explicitly and store builds stay on store',
    () {
      expect(
        iosUpdateChannel('com.apple', 'iosManual'),
        UpdateChannel.iosManual,
      );
      expect(
        iosUpdateChannel('com.apple', 'iosAppStore'),
        UpdateChannel.iosAppStore,
      );
      expect(iosUpdateChannel(null, ''), UpdateChannel.iosAppStore);
      expect(
        iosUpdateChannel('com.apple.testflight', 'iosManual'),
        UpdateChannel.iosTestFlight,
      );
    },
  );
  testWidgets('a response received in background waits until app resumes', (
    tester,
  ) async {
    final repository = FakeUpdates()..pending = Completer<UpdateManifest>();
    final c = containerFor(repository, MemoryUpdates(), DateTime.now);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          navigatorKey: c.read(appNavigatorKeyProvider),
          builder: (_, child) => UpdatePromptHost(child: child!),
          home: const Scaffold(body: Text('Đang xem')),
        ),
      ),
    );
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    repository.pending!.complete(manifest());
    await tester.pumpAndSettle();
    expect(find.text('Có phiên bản mới'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Có phiên bản mới'), findsOneWidget);
    expect(repository.calls, 1);
    await tester.tap(find.text('Nhắc sau'));
    await tester.pumpAndSettle();
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'numeric version comparison handles minor 10, build-only and older releases',
    () {
      expect(
        const AppVersion(1, 10, 0, 1).compareTo(const AppVersion(1, 9, 9, 100)),
        greaterThan(0),
      );
      expect(
        const AppVersion(1, 1, 0, 3).compareTo(oldApp.version),
        greaterThan(0),
      );
      expect(
        const AppVersion(1, 0, 9, 100).compareTo(oldApp.version),
        lessThan(0),
      );
      expect(AppVersion.parse('1.2.0-beta', '2'), isNull);
      expect(AppVersion.parse('1.2.0', 'bad'), isNull);
    },
  );
  test(
    'untrusted update links, duplicate channels and wrong app channels are rejected',
    () {
      for (final url in [
        'javascript:alert(1)',
        'http://github.com/AnhhPhuong06/HomNayAnGi/releases/tag/v1.2.0+3',
        'https://github.com.evil.example/AnhhPhuong06/HomNayAnGi/releases/tag/v1.2.0+3',
        'https://github.com/Someone/Another/releases/tag/v1.2.0+3',
        'https://user@github.com/AnhhPhuong06/HomNayAnGi/releases/tag/v1.2.0+3',
        'https://github.com/AnhhPhuong06/HomNayAnGi/releases/tag/v1.2.0+3?redirect=evil',
      ]) {
        expect(
          () => AppRelease.parse(releaseData(url: url)),
          throwsFormatException,
        );
      }
      expect(
        () => UpdateManifest.parse({
          'schemaVersion': 1,
          'releases': [releaseData(), releaseData()],
        }),
        throwsFormatException,
      );
      expect(
        manifest().forApp(
          const InstalledApp(
            bundleId: 'another.app',
            version: AppVersion(1, 0, 0, 1),
            channel: UpdateChannel.iosManual,
          ),
        ),
        isNull,
      );
      expect(
        manifest().forApp(
          const InstalledApp(
            bundleId: 'vn.homnayangi.homNayAnGi',
            version: AppVersion(1, 0, 0, 1),
            channel: UpdateChannel.iosAppStore,
          ),
        ),
        isNull,
      );
      expect(
        () => AppRelease.parse(releaseData(channel: 'iosAppStore')),
        throwsFormatException,
      );
    },
  );
  test(
    'automatic reminder is throttled and remind later survives a new session for 24 hours',
    () async {
      var now = DateTime.utc(2026, 11, 5);
      final repository = FakeUpdates(), store = MemoryUpdates();
      final c = containerFor(repository, store, () => now);
      final controller = c.read(updateControllerProvider.notifier);
      await controller.check();
      expect(c.read(updateControllerProvider).status, UpdateStatus.available);
      expect(c.read(updateControllerProvider).prompt, 1);
      await controller.remindLater();
      now = now.add(const Duration(minutes: 2));
      await controller.check();
      expect(repository.calls, 1);
      final second = containerFor(repository, store, () => now);
      await second.read(updateControllerProvider.notifier).check();
      expect(second.read(updateControllerProvider).prompt, 0);
      expect(repository.calls, 1);
      now = now.add(const Duration(hours: 25));
      await second.read(updateControllerProvider.notifier).check();
      expect(second.read(updateControllerProvider).prompt, 1);
      expect(repository.calls, 2);
    },
  );
  test(
    'manual checking bypasses snooze and cache; same or lower version never prompts',
    () async {
      final repository = FakeUpdates(), store = MemoryUpdates();
      final c = containerFor(
        repository,
        store,
        () => DateTime.utc(2026, 11, 5),
      );
      final controller = c.read(updateControllerProvider.notifier);
      await controller.check();
      await controller.remindLater();
      await controller.check(manual: true);
      expect(repository.calls, 2);
      expect(c.read(updateControllerProvider).prompt, 2);
      repository.response = manifest(version: '1.1.0', build: 2);
      await controller.check(manual: true);
      expect(c.read(updateControllerProvider).status, UpdateStatus.current);
      expect(c.read(updateControllerProvider).release, isNull);
      repository.response = manifest(version: '1.0.0', build: 1);
      await controller.check(manual: true);
      expect(c.read(updateControllerProvider).prompt, 2);
    },
  );
  test(
    'offline, missing native metadata and empty feed never claim up-to-date',
    () async {
      final repository = FakeUpdates()
        ..failure = const FormatException('offline');
      final c = containerFor(repository, MemoryUpdates(), DateTime.now);
      await c.read(updateControllerProvider.notifier).check();
      expect(c.read(updateControllerProvider).status, UpdateStatus.unavailable);
      expect(c.read(updateControllerProvider).prompt, 0);
      repository.failure = null;
      repository.response = const UpdateManifest([]);
      await c.read(updateControllerProvider.notifier).check(manual: true);
      expect(
        c.read(updateControllerProvider).status,
        UpdateStatus.unconfigured,
      );
      final missing = containerFor(
        repository,
        MemoryUpdates(),
        DateTime.now,
        app: null,
      );
      await missing.read(updateControllerProvider.notifier).check(manual: true);
      expect(
        missing.read(updateControllerProvider).status,
        UpdateStatus.unavailable,
      );
    },
  );
  test(
    'opt-out prevents automatic network checks; manual still works',
    () async {
      final repository = FakeUpdates(),
          store = MemoryUpdates()..enabled = false;
      final c = containerFor(repository, store, DateTime.now);
      await c.read(updateControllerProvider.notifier).check();
      expect(repository.calls, 0);
      await c.read(updateControllerProvider.notifier).check(manual: true);
      expect(repository.calls, 1);
      expect(c.read(updateControllerProvider).automatic, false);
    },
  );
  test(
    'concurrent resumes share one request and opt-out during request prevents prompt',
    () async {
      final repository = FakeUpdates()..pending = Completer<UpdateManifest>();
      final c = containerFor(repository, MemoryUpdates(), DateTime.now);
      final controller = c.read(updateControllerProvider.notifier);
      final request = controller.check();
      await Future<void>.delayed(Duration.zero);
      await controller.check();
      await controller.setAutomatic(false);
      repository.pending!.complete(manifest());
      await request;
      expect(repository.calls, 1);
      expect(c.read(updateControllerProvider).automatic, false);
      expect(c.read(updateControllerProvider).prompt, 0);
    },
  );
  test(
    'reminder preference, snooze and valid cache persist, corrupt cache recovers',
    () async {
      SharedPreferences.setMockInitialValues({
        'updates.cache': 'not-json',
        'updates.automatic': 'bad',
      });
      final store = PreferencesUpdateStore(), now = DateTime.utc(2026, 11, 5);
      expect(await store.readCache(), isNull);
      expect(await store.automaticEnabled(), true);
      await store.setAutomatic(false);
      expect(await store.automaticEnabled(), false);
      await store.writeCache(manifest(), now);
      expect(
        UpdateManifest.parse(
          (await store.readCache())!.document,
        ).forApp(oldApp),
        isNotNull,
      );
      await store.snooze('release-a', now);
      expect(await PreferencesUpdateStore().isSnoozed('release-a', now), true);
      expect(await store.isSnoozed('release-b', now), false);
      expect(
        await store.isSnoozed('release-a', now.add(const Duration(hours: 25))),
        false,
      );
    },
  );
  testWidgets(
    'startup shows one update prompt and remind later does not navigate away',
    (tester) async {
      final repository = FakeUpdates(), store = MemoryUpdates();
      final c = containerFor(
        repository,
        store,
        () => DateTime.utc(2026, 11, 5),
      );
      final key = c.read(appNavigatorKeyProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            navigatorKey: key,
            builder: (_, child) => UpdatePromptHost(child: child!),
            home: const Scaffold(body: Text('Nội dung đang xem')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Có phiên bản mới'), findsOneWidget);
      await tester.tap(find.text('Nhắc sau'));
      await tester.pumpAndSettle();
      expect(find.text('Nội dung đang xem'), findsOneWidget);
      expect(find.text('Có phiên bản mới'), findsNothing);
      expect(store.snoozedKey, manifest().releases.single.key);
    },
  );
  testWidgets('large text update dialog keeps both choices reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2.6)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AppUpdateDialog(
                  release: manifest().releases.single,
                  installed: oldApp,
                ),
              ),
              child: const Text('Mở'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    expect(find.text('Nhắc sau').hitTestable(), findsOneWidget);
    expect(find.text('Cập nhật').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
