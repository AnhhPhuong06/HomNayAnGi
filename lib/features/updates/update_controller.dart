import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'update_models.dart';
import 'update_repository.dart';
import 'update_store.dart';

enum UpdateStatus {
  idle,
  checking,
  available,
  current,
  unconfigured,
  unavailable,
}

class UpdateState {
  const UpdateState({
    this.status = UpdateStatus.idle,
    this.app,
    this.release,
    this.automatic = true,
    this.prompt = 0,
    this.checkedAt,
  });
  final UpdateStatus status;
  final InstalledApp? app;
  final AppRelease? release;
  final bool automatic;
  final int prompt;
  final DateTime? checkedAt;
}

final updateClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

class UpdateController extends Notifier<UpdateState> {
  bool _busy = false;
  DateTime? _lastAttempt;
  String? _promptedThisSession;
  DateTime? _lastPromptAt;
  @override
  UpdateState build() => const UpdateState();

  Future<void> check({bool manual = false}) async {
    if (_busy) return;
    _busy = true;
    final now = ref.read(updateClockProvider)();
    final store = ref.read(updateStoreProvider);
    try {
      final enabled = await store.automaticEnabled();
      if (!ref.mounted) return;
      state = UpdateState(
        status: state.status,
        app: state.app,
        release: state.release,
        automatic: enabled,
        prompt: state.prompt,
        checkedAt: state.checkedAt,
      );
      if (!manual && !enabled) return;
      if (!manual &&
          _lastAttempt != null &&
          !now.isBefore(_lastAttempt!) &&
          now.difference(_lastAttempt!) < const Duration(minutes: 15)) {
        return;
      }
      _lastAttempt = now;
      state = UpdateState(
        status: UpdateStatus.checking,
        app: state.app,
        automatic: enabled,
        prompt: state.prompt,
        checkedAt: state.checkedAt,
      );
      final app = await ref.read(installedAppProvider.future);
      if (!ref.mounted) return;
      if (app == null) {
        state = UpdateState(
          status: UpdateStatus.unavailable,
          automatic: enabled,
          prompt: state.prompt,
        );
        return;
      }
      final cache = await store.readCache();
      final fresh =
          cache != null &&
          !now.isBefore(cache.checkedAt) &&
          now.difference(cache.checkedAt) < const Duration(hours: 6);
      final manifest = !manual && fresh
          ? UpdateManifest.parse(cache.document)
          : await ref.read(updateRepositoryProvider).fetch();
      if (!ref.mounted) return;
      if (manual || !fresh) {
        try {
          await store.writeCache(manifest, now);
        } catch (_) {}
      }
      if (!ref.mounted) return;
      final release = manifest.forApp(app);
      final available =
          release != null && release.version.compareTo(app.version) > 0;
      final snoozed = available && !manual
          ? await store.isSnoozed(release.key, now)
          : false;
      if (!ref.mounted) return;
      final enabledNow = state.automatic;
      final prompt =
          available &&
          (manual ||
              (enabledNow &&
                  !snoozed &&
                  (_promptedThisSession != release.key ||
                      _lastPromptAt == null ||
                      now.difference(_lastPromptAt!) >=
                          const Duration(hours: 24))));
      if (prompt) {
        _promptedThisSession = release.key;
        _lastPromptAt = now;
      }
      state = UpdateState(
        status: release == null
            ? UpdateStatus.unconfigured
            : available
            ? UpdateStatus.available
            : UpdateStatus.current,
        app: app,
        release: available ? release : null,
        automatic: enabledNow,
        prompt: state.prompt + (prompt ? 1 : 0),
        checkedAt: fresh && !manual ? cache.checkedAt : now,
      );
    } catch (_) {
      if (ref.mounted) {
        state = UpdateState(
          status: UpdateStatus.unavailable,
          app: state.app,
          automatic: state.automatic,
          prompt: state.prompt,
          checkedAt: state.checkedAt,
        );
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> remindLater([AppRelease? shown]) async {
    final release = shown ?? state.release;
    if (release != null) {
      try {
        await ref
            .read(updateStoreProvider)
            .snooze(release.key, ref.read(updateClockProvider)());
      } catch (_) {}
    }
  }

  Future<void> setAutomatic(bool enabled) async {
    await ref.read(updateStoreProvider).setAutomatic(enabled);
    if (!ref.mounted) return;
    state = UpdateState(
      status: state.status,
      app: state.app,
      release: state.release,
      automatic: enabled,
      prompt: state.prompt,
      checkedAt: state.checkedAt,
    );
  }
}
