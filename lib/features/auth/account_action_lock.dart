import 'package:flutter_riverpod/flutter_riverpod.dart';

// Serialize account deletion/sign-out with personal backup operations.
final accountActionLockProvider = NotifierProvider<AccountActionLock, bool>(
  AccountActionLock.new,
);

class AccountActionLock extends Notifier<bool> {
  @override
  bool build() => false;
  bool begin() {
    if (state) return false;
    state = true;
    return true;
  }

  void release() {
    if (ref.mounted) state = false;
  }
}
