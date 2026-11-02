import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Member {
  const Member({required this.id, required this.name, this.email = ''});
  final String id, name, email;
}

enum SocialProvider { google, facebook, apple }

class SignInCancelled implements Exception {
  const SignInCancelled();
}

abstract class AuthRepository {
  Stream<Member?> session();
  Future<void> signIn(SocialProvider provider);
  Future<void> signOut();
  Future<void> reauthenticate();
  Future<void> deleteAccount();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this.auth);
  final FirebaseAuth auth;
  Future<void>? _googleInitialization;
  Future<AuthCredential> _credential(SocialProvider provider) async {
    if (provider == SocialProvider.google) {
      _googleInitialization ??= GoogleSignIn.instance.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID')
            : null,
        serverClientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
      );
      await _googleInitialization;
      final account = await GoogleSignIn.instance.authenticate();
      return GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      );
    }
    final random = Random.secure();
    final nonce = base64Url.encode(
      List.generate(32, (_) => random.nextInt(256)),
    );
    final result = await FacebookAuth.instance.login(
      nonce: sha256.convert(utf8.encode(nonce)).toString(),
      loginTracking: LoginTracking.limited,
    );
    if (result.status == LoginStatus.cancelled) throw const SignInCancelled();
    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw StateError('Facebook sign in failed');
    }
    final token = result.accessToken!;
    return token is LimitedToken
        ? OAuthProvider(
            'facebook.com',
          ).credential(idToken: token.tokenString, rawNonce: nonce)
        : FacebookAuthProvider.credential(token.tokenString);
  }

  AuthProvider _provider(SocialProvider p) => switch (p) {
    SocialProvider.google => GoogleAuthProvider(),
    SocialProvider.facebook => FacebookAuthProvider(),
    SocialProvider.apple => AppleAuthProvider(),
  };
  @override
  Stream<Member?> session() => auth.userChanges().map(
    (u) => u == null
        ? null
        : Member(
            id: u.uid,
            name: u.displayName?.trim().isNotEmpty == true
                ? u.displayName!
                : 'Bạn yêu ẩm thực',
            email: u.email ?? '',
          ),
  );
  @override
  Future<void> signIn(SocialProvider provider) async {
    if (kIsWeb) {
      await auth.signInWithPopup(_provider(provider));
    } else if (provider == SocialProvider.apple) {
      await auth.signInWithProvider(AppleAuthProvider());
    } else {
      await auth.signInWithCredential(await _credential(provider));
    }
  }

  @override
  Future<void> signOut() async {
    await auth.signOut();
    // Provider SDK cleanup cannot keep an application session alive.
    try {
      if (_googleInitialization != null) await GoogleSignIn.instance.signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }

  @override
  Future<void> reauthenticate() async {
    final user = auth.currentUser!;
    final id = user.providerData.first.providerId;
    final provider = id == 'apple.com'
        ? SocialProvider.apple
        : id == 'facebook.com'
        ? SocialProvider.facebook
        : SocialProvider.google;
    if (kIsWeb) {
      await user.reauthenticateWithPopup(_provider(provider));
    } else if (provider == SocialProvider.apple) {
      final result = await user.reauthenticateWithProvider(AppleAuthProvider());
      final code = result.additionalUserInfo?.authorizationCode;
      if (code != null) await auth.revokeTokenWithAuthorizationCode(code);
    } else {
      await user.reauthenticateWithCredential(await _credential(provider));
    }
  }

  @override
  Future<void> deleteAccount() => auth.currentUser!.delete();
}

final backendReadyProvider = Provider<bool>((ref) => false);
// Tests override this explicitly; the shipping application always requires login.
final authenticationRequiredProvider = Provider<bool>((ref) => true);
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);
final memberProvider = StreamProvider<Member?>((ref) {
  if (!ref.watch(backendReadyProvider)) return Stream.value(null);
  return ref.watch(authRepositoryProvider).session();
});

String accountError(Object error) {
  if (error is SignInCancelled ||
      error is GoogleSignInException &&
          error.code == GoogleSignInExceptionCode.canceled) {
    return 'Bạn đã hủy đăng nhập.';
  }
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'account-exists-with-different-credential' =>
        'Email này đã dùng cách đăng nhập khác. Hãy chọn nhà cung cấp đã dùng trước đó.',
      'popup-closed-by-user' ||
      'web-context-cancelled' ||
      'canceled' => 'Bạn đã hủy đăng nhập.',
      'too-many-requests' => 'Bạn đã thử nhiều lần. Vui lòng đợi rồi thử lại.',
      'network-request-failed' => 'Không kết nối được. Hãy kiểm tra Internet.',
      'requires-recent-login' =>
        'Hãy đăng nhập lại rồi thực hiện thao tác này.',
      _ => 'Chưa đăng nhập được. Vui lòng thử lại.',
    };
  }
  return 'Chưa thực hiện được. Hãy kiểm tra kết nối và thử lại.';
}
