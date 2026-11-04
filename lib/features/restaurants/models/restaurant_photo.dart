class RestaurantPhoto {
  const RestaurantPhoto({
    required this.asset,
    required this.sourceUrl,
    required this.author,
    required this.license,
    required this.licenseUrl,
    required this.caption,
    required this.checkedAt,
    required this.capturedAt,
  });

  final String asset, sourceUrl, author, license, licenseUrl, caption;
  final String checkedAt, capturedAt;

  static RestaurantPhoto? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    String text(String key) =>
        value[key] is String ? (value[key] as String).trim() : '';
    final asset = text('asset');
    final source = Uri.tryParse(text('sourceUrl'));
    final licenseUri = Uri.tryParse(text('licenseUrl'));
    if (!RegExp(r'^assets/venue_photos/[a-z0-9_-]+\.jpg$').hasMatch(asset) ||
        source?.scheme != 'https' ||
        source?.host != 'commons.wikimedia.org' ||
        !source!.path.startsWith('/wiki/File:') ||
        source.hasFragment ||
        licenseUri?.scheme != 'https' ||
        licenseUri?.host != 'creativecommons.org' ||
        ![
          'CC0',
          'Public domain',
          'CC BY 2.0',
          'CC BY 3.0',
          'CC BY 4.0',
          'CC BY-SA 2.0',
          'CC BY-SA 2.5',
          'CC BY-SA 3.0',
          'CC BY-SA 4.0',
        ].contains(text('license')) ||
        text('author').isEmpty ||
        text('caption').isEmpty ||
        DateTime.tryParse(text('checkedAt')) == null ||
        text('capturedAt').isEmpty) {
      return null;
    }
    return RestaurantPhoto(
      asset: asset,
      sourceUrl: source.toString(),
      author: text('author'),
      license: text('license'),
      licenseUrl: licenseUri.toString(),
      caption: text('caption'),
      checkedAt: text('checkedAt'),
      capturedAt: text('capturedAt'),
    );
  }
}
