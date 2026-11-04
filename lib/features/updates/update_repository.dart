import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'update_models.dart';

const updateManifestUrl =
    'https://raw.githubusercontent.com/AnhhPhuong06/HomNayAnGi/main/config/app_updates.json';

// iOS package_info_plus reports com.apple even when no receipt exists.
// Manual IPA builds must opt in explicitly; store builds default to App Store.
UpdateChannel iosUpdateChannel(String? installer, String configured) {
  if (installer == 'com.apple.testflight') {
    return UpdateChannel.iosTestFlight;
  }
  return configured == 'iosManual'
      ? UpdateChannel.iosManual
      : UpdateChannel.iosAppStore;
}

abstract class UpdateRepository {
  Future<UpdateManifest> fetch();
}

class GithubUpdateRepository implements UpdateRepository {
  GithubUpdateRepository([Dio? client])
    : _client =
          client ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
          );
  final Dio _client;
  @override
  Future<UpdateManifest> fetch() async {
    final token = CancelToken();
    Future<UpdateManifest> download() async {
      final response = await _client.get<ResponseBody>(
        updateManifestUrl,
        cancelToken: token,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
          validateStatus: (status) => status == 200,
        ),
      );
      if (response.data == null) {
        throw const FormatException('Empty update response');
      }
      final bytes = <int>[];
      await for (final chunk in response.data!.stream) {
        if (bytes.length + chunk.length > 65536) {
          throw const FormatException('Update response too large');
        }
        bytes.addAll(chunk);
      }
      return UpdateManifest.parse(jsonDecode(utf8.decode(bytes)));
    }

    return download().timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        token.cancel('Update check timed out');
        throw const FormatException('Update check timed out');
      },
    );
  }
}

final installedAppProvider = FutureProvider<InstalledApp?>((ref) async {
  if (kIsWeb) return null;
  try {
    final package = await PackageInfo.fromPlatform();
    final version = AppVersion.parse(package.version, package.buildNumber);
    if (version == null) return null;
    final UpdateChannel channel;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        channel = iosUpdateChannel(
          package.installerStore,
          const String.fromEnvironment(
            'APP_UPDATE_CHANNEL',
            defaultValue: 'iosAppStore',
          ),
        );
      case TargetPlatform.android:
        channel = package.installerStore == 'com.android.vending'
            ? UpdateChannel.androidPlay
            : UpdateChannel.androidManual;
      default:
        return null;
    }
    return InstalledApp(
      bundleId: package.packageName,
      version: version,
      channel: channel,
    );
  } catch (_) {
    return null;
  }
});

final updateRepositoryProvider = Provider<UpdateRepository>(
  (ref) => GithubUpdateRepository(),
);
