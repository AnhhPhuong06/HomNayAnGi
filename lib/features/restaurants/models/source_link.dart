class SourceLink {
  const SourceLink._(this.platform, this.url, this.label);
  final String platform, url, label;

  static SourceLink? fromJson(Object? json) {
    if (json is! Map) return null;
    final platform = json['platform'];
    final raw = json['url'];
    final label = json['label'];
    if (platform is! String ||
        raw is! String ||
        label is! String ||
        label.trim().isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasFragment) {
      return null;
    }
    final valid = switch (platform) {
      'tiktok' =>
        {'www.tiktok.com', 'tiktok.com'}.contains(uri.host) &&
            RegExp(r'^/@[^/]+(?:/video/\d+)?/?$').hasMatch(uri.path),
      'openStreetMap' =>
        {'www.openstreetmap.org', 'openstreetmap.org'}.contains(uri.host) &&
            RegExp(r'^/(node|way|relation)/\d+/?$').hasMatch(uri.path),
      'googleMaps' =>
        {'www.google.com', 'google.com'}.contains(uri.host) &&
            uri.path.startsWith('/maps'),
      _ => false,
    };
    return valid ? SourceLink._(platform, uri.toString(), label.trim()) : null;
  }
}
