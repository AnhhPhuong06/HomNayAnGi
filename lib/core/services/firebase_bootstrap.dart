import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future<bool> initializeCommunity() async {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const sender = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  const androidId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  const iosId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  const webId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  final appId = kIsWeb
      ? webId
      : defaultTargetPlatform == TargetPlatform.iOS
      ? iosId
      : androidId;
  if ([apiKey, projectId, sender, appId].any((s) => s.isEmpty)) return false;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: sender,
          projectId: projectId,
          authDomain: '$projectId.firebaseapp.com',
          iosBundleId: 'vn.homnayangi.homNayAnGi',
        ),
      );
    }
    return true;
  } catch (_) {
    return false;
  }
}
