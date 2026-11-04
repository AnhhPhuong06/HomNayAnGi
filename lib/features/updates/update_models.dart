enum UpdateChannel {
  iosManual,
  iosAppStore,
  iosTestFlight,
  androidManual,
  androidPlay,
}

class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch, this.build);
  final int major, minor, patch, build;
  static AppVersion? parse(String version, String build) {
    final parts = version.split('.');
    if (parts.length < 2 ||
        parts.length > 3 ||
        parts.any((p) => !RegExp(r'^\d{1,9}$').hasMatch(p)) ||
        !RegExp(r'^\d{1,9}$').hasMatch(build)) {
      return null;
    }
    return AppVersion(
      int.parse(parts[0]),
      int.parse(parts[1]),
      parts.length == 3 ? int.parse(parts[2]) : 0,
      int.parse(build),
    );
  }

  String get name => '$major.$minor.$patch';
  @override
  int compareTo(AppVersion other) {
    final a = [major, minor, patch, build],
        b = [other.major, other.minor, other.patch, other.build];
    for (var i = 0; i < a.length; i++) {
      final comparison = a[i].compareTo(b[i]);
      if (comparison != 0) return comparison;
    }
    return 0;
  }
}

class InstalledApp {
  const InstalledApp({
    required this.bundleId,
    required this.version,
    required this.channel,
  });
  final String bundleId;
  final AppVersion version;
  final UpdateChannel channel;
}

class AppRelease {
  const AppRelease({
    required this.bundleId,
    required this.version,
    required this.channel,
    required this.url,
    required this.notes,
  });
  final String bundleId, notes;
  final AppVersion version;
  final UpdateChannel channel;
  final Uri url;
  String get key => '${channel.name}:${version.name}+${version.build}';
  bool get manual =>
      channel == UpdateChannel.iosManual ||
      channel == UpdateChannel.androidManual;

  static AppRelease parse(Map<String, dynamic> data) {
    final version = AppVersion.parse(
      data['version'] is String ? data['version'] as String : '',
      '${data['build']}',
    );
    final channel = UpdateChannel.values
        .where((c) => c.name == data['channel'])
        .firstOrNull;
    final bundle = data['bundleId'];
    final uri = data['url'] is String
        ? Uri.tryParse(data['url'] as String)
        : null;
    final notes = data['notes'];
    if (version == null ||
        version.build < 1 ||
        channel == null ||
        bundle is! String ||
        bundle.length > 160 ||
        !RegExp(r'^[A-Za-z0-9_.]+$').hasMatch(bundle) ||
        notes is! String ||
        notes.length > 2000 ||
        uri == null ||
        !trustedReleaseUrl(uri, channel, bundle, version)) {
      throw const FormatException('Invalid update release');
    }
    return AppRelease(
      bundleId: bundle,
      version: version,
      channel: channel,
      url: uri,
      notes: notes,
    );
  }
}

bool trustedReleaseUrl(
  Uri uri,
  UpdateChannel channel,
  String bundle,
  AppVersion version,
) {
  if (uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort ||
      uri.hasFragment) {
    return false;
  }
  switch (channel) {
    case UpdateChannel.iosManual:
    case UpdateChannel.androidManual:
      return uri.host == 'github.com' &&
          !uri.hasQuery &&
          [
            '/AnhhPhuong06/HomNayAnGi/releases/tag/v${version.name}',
            '/AnhhPhuong06/HomNayAnGi/releases/tag/v${version.name}+${version.build}',
          ].contains(uri.path);
    case UpdateChannel.iosAppStore:
      return uri.host == 'apps.apple.com' &&
          RegExp(r'^/(?:[a-z]{2}/)?app/(?:[^/]+/)?id\d+$').hasMatch(uri.path);
    case UpdateChannel.iosTestFlight:
      return uri.host == 'testflight.apple.com' &&
          RegExp(r'^/join/[A-Za-z0-9]+$').hasMatch(uri.path) &&
          !uri.hasQuery;
    case UpdateChannel.androidPlay:
      return uri.host == 'play.google.com' &&
          uri.path == '/store/apps/details' &&
          uri.queryParameters['id'] == bundle;
  }
}

class UpdateManifest {
  const UpdateManifest(this.releases);
  final List<AppRelease> releases;
  static UpdateManifest parse(Object? data) {
    if (data is! Map<String, dynamic> ||
        data['schemaVersion'] != 1 ||
        data['releases'] is! List ||
        (data['releases'] as List).length > 10) {
      throw const FormatException('Invalid update manifest');
    }
    final releases = (data['releases'] as List).map((r) {
      if (r is! Map<String, dynamic>) {
        throw const FormatException('Invalid release');
      }
      return AppRelease.parse(r);
    }).toList();
    final keys = releases.map((r) => '${r.channel.name}:${r.bundleId}');
    if (keys.toSet().length != releases.length) {
      throw const FormatException('Duplicate update channel');
    }
    return UpdateManifest(List.unmodifiable(releases));
  }

  AppRelease? forApp(InstalledApp app) => releases
      .where((r) => r.channel == app.channel && r.bundleId == app.bundleId)
      .firstOrNull;
}
