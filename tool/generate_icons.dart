// flutter test tool/generate_icons.dart
// Export platform sizes from the exact selected Facebook raster artwork.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hom_nay_an_gi/core/branding/brand_mark.dart';

Future<void> savePng(
  String path,
  int width,
  int height,
  void Function(ui.Canvas) draw, {
  bool opaque = false,
}) async {
  final recorder = ui.PictureRecorder();
  draw(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = opaque
      ? await opaquePng(image, width, height)
      : (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
  image.dispose();
  picture.dispose();
}

// Store icons are encoded as RGB PNG, not RGBA with a merely opaque alpha plane.
Future<Uint8List> opaquePng(ui.Image image, int width, int height) async {
  final pixels = (await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  ))!.buffer.asUint8List();
  final rows = Uint8List(height * (1 + width * 3));
  var target = 0;
  for (var y = 0; y < height; y++) {
    rows[target++] = 0; // PNG filter: none.
    for (var x = 0; x < width; x++) {
      final offset = (y * width + x) * 4;
      if (pixels[offset + 3] != 255) {
        throw StateError('Transparent pixel in an opaque icon');
      }
      rows[target++] = pixels[offset];
      rows[target++] = pixels[offset + 1];
      rows[target++] = pixels[offset + 2];
    }
  }
  final output = BytesBuilder()..add([137, 80, 78, 71, 13, 10, 26, 10]);
  void chunk(String type, List<int> payload) {
    final data = Uint8List.fromList([...type.codeUnits, ...payload]);
    var crc = 0xffffffff;
    for (final byte in data) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 1) == 1 ? 0xedb88320 ^ (crc >> 1) : crc >> 1;
      }
    }
    final length = ByteData(4)..setUint32(0, payload.length);
    final checksum = ByteData(4)..setUint32(0, crc ^ 0xffffffff);
    output
      ..add(length.buffer.asUint8List())
      ..add(data)
      ..add(checksum.buffer.asUint8List());
  }

  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8)
    ..setUint8(9, 2);
  chunk('IHDR', header.buffer.asUint8List());
  chunk('IDAT', ZLibEncoder().convert(rows));
  chunk('IEND', []);
  return output.takeBytes();
}

Future<void> saveText(String path, String contents) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(contents);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('export selected Facebook artwork for all platforms', () async {
    final codec = await ui.instantiateImageCodec(
      await File(BrandArtwork.asset).readAsBytes(),
    );
    final source = (await codec.getNextFrame()).image;
    codec.dispose();
    addTearDown(source.dispose);
    void drawLogo(ui.Canvas canvas, double size, {double inset = 0}) {
      canvas.drawColor(const ui.Color(0xffffffff), ui.BlendMode.src);
      canvas.drawImageRect(
        source,
        ui.Rect.fromLTWH(
          0,
          0,
          source.width.toDouble(),
          source.height.toDouble(),
        ),
        ui.Rect.fromLTWH(
          size * inset,
          size * inset,
          size * (1 - 2 * inset),
          size * (1 - 2 * inset),
        ),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
    }

    final outputs = <String, int>{
      for (final e in {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      }.entries)
        'android/app/src/main/res/mipmap-${e.key}/ic_launcher.png': e.value,
      'web/favicon.png': 32,
      'web/icons/Icon-192.png': 192,
      'web/icons/Icon-512.png': 512,
      'assets/branding/app-icon-1024.png': 1024,
      'assets/branding/app-icon-512.png': 512,
    };
    for (final f in Directory(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset',
    ).listSync().whereType<File>()) {
      final match = RegExp(
        r'Icon-App-([0-9.]+)x[0-9.]+@([123])x\.png$',
      ).firstMatch(f.path);
      if (match != null) {
        outputs[f.path] = (double.parse(match[1]!) * int.parse(match[2]!))
            .round();
      }
    }
    for (final e in outputs.entries) {
      await savePng(
        e.key,
        e.value,
        e.value,
        (c) => drawLogo(c, e.value.toDouble()),
        opaque: true,
      );
    }
    for (final size in [192, 512]) {
      await savePng(
        'web/icons/Icon-maskable-$size.png',
        size,
        size,
        (c) => drawLogo(c, size.toDouble(), inset: .20),
        opaque: true,
      );
    }
    for (final (file, size) in [
      ('LaunchImage.png', 160),
      ('LaunchImage@2x.png', 320),
      ('LaunchImage@3x.png', 480),
    ]) {
      await savePng(
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/$file',
        size,
        size,
        (c) => drawLogo(c, size.toDouble()),
      );
    }
    await savePng(
      'assets/branding/logo-preview.png',
      768,
      768,
      (c) => drawLogo(c, 768),
    );
    await savePng('assets/branding/small-size-preview.png', 720, 200, (c) {
      c.drawColor(const ui.Color(0xfff7f8f2), ui.BlendMode.src);
      var x = 60.0;
      for (final size in [24.0, 32.0, 48.0, 64.0, 96.0, 128.0]) {
        c.save();
        c.translate(x, (200 - size) / 2);
        c.clipRect(ui.Rect.fromLTWH(0, 0, size, size));
        drawLogo(c, size);
        c.restore();
        x += size + 28;
      }
    });
    const base = 'android/app/src/main/res';
    // A 60% artwork width fits inside the circular adaptive-icon safe region.
    await savePng(
      '$base/drawable-nodpi/ic_launcher_foreground.png',
      432,
      432,
      (c) => drawLogo(c, 432, inset: .20),
    );
    await saveText(
      '$base/drawable/brand_splash_logo.xml',
      '''<?xml version="1.0" encoding="utf-8"?>
<bitmap xmlns:android="http://schemas.android.com/apk/res/android" android:src="@drawable/brand_splash_bitmap" android:gravity="center" android:filter="true"/>
''',
    );
    // Density-specific splash bitmaps keep the intended native size at 112dp.
    for (final e in {
      'mdpi': 112,
      'hdpi': 168,
      'xhdpi': 224,
      'xxhdpi': 336,
      'xxxhdpi': 448,
    }.entries) {
      await savePng(
        '$base/drawable-${e.key}/brand_splash_bitmap.png',
        e.value,
        e.value,
        (c) => drawLogo(c, e.value.toDouble()),
      );
    }
    for (final version in [26, 33]) {
      await saveText(
        '$base/mipmap-anydpi-v$version/ic_launcher.xml',
        '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
<background android:drawable="@color/brand_icon_background"/>
<foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
''',
      );
    }
    for (final folder in ['drawable', 'drawable-v21']) {
      await saveText(
        '$base/$folder/launch_background.xml',
        '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
<item android:drawable="@color/brand_splash_background"/>
<item android:gravity="center" android:drawable="@drawable/brand_splash_logo"/>
</layer-list>
''',
      );
    }
    final font = FontLoader('BeVietnamPro')
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Bold.ttf'));
    await font.load();
    await savePng('assets/branding/wordmark.png', 1100, 240, (c) {
      c.drawColor(const ui.Color(0xfff7f8f2), ui.BlendMode.src);
      c.save();
      c.translate(28, 28);
      c.clipRect(const ui.Rect.fromLTWH(0, 0, 184, 184));
      drawLogo(c, 184);
      c.restore();
      final paragraph =
          (ui.ParagraphBuilder(
                  ui.ParagraphStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 51,
                    fontWeight: ui.FontWeight.w700,
                  ),
                )
                ..pushStyle(ui.TextStyle(color: const ui.Color(0xff163f30)))
                ..addText('Hôm Nay Ăn Gì?'))
              .build()
            ..layout(const ui.ParagraphConstraints(width: 800));
      c.drawParagraph(paragraph, const ui.Offset(250, 79));
      paragraph.dispose();
    });
  });
}
