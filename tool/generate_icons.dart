// Asset renderer: flutter test tool/generate_icons.dart
// Uses Flutter's own Canvas, with no image-generation dependency.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render application icon assets', () async {
    final outputs = <String, int>{
      for (final entry in {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      }.entries)
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png':
            entry.value,
      'web/favicon.png': 32,
      'web/icons/Icon-192.png': 192,
      'web/icons/Icon-512.png': 512,
      'web/icons/Icon-maskable-192.png': 192,
      'web/icons/Icon-maskable-512.png': 512,
    };
    final iosDirectory = Directory(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset',
    );
    for (final file in iosDirectory.listSync().whereType<File>()) {
      final match = RegExp(
        r'Icon-App-([0-9.]+)x[0-9.]+@([123])x\.png$',
      ).firstMatch(file.path);
      if (match != null) {
        outputs[file.path] = (double.parse(match[1]!) * int.parse(match[2]!))
            .round();
      }
    }
    for (final entry in outputs.entries) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)..scale(entry.value / 100);
      canvas.drawColor(const ui.Color(0xffa83b16), ui.BlendMode.src);
      final white = ui.Paint()..color = const ui.Color(0xfffff6e9);
      final bowl = ui.Path()
        ..moveTo(20, 49)
        ..lineTo(80, 49)
        ..cubicTo(78, 70, 66, 79, 50, 79)
        ..cubicTo(34, 79, 22, 70, 20, 49)
        ..close();
      canvas.drawPath(bowl, white);
      canvas.drawRRect(
        ui.RRect.fromLTRBR(40, 80, 60, 84, const ui.Radius.circular(2)),
        white,
      );
      final stick = ui.Paint()
        ..color = const ui.Color(0xffffd895)
        ..strokeWidth = 3.5
        ..strokeCap = ui.StrokeCap.round;
      canvas.drawLine(const ui.Offset(59, 20), const ui.Offset(38, 43), stick);
      canvas.drawLine(const ui.Offset(75, 24), const ui.Offset(47, 44), stick);
      canvas.drawCircle(const ui.Offset(29, 32), 3, white);
      canvas.drawCircle(const ui.Offset(35, 23), 2, white);
      final picture = recorder.endRecording();
      final image = await picture.toImage(entry.value, entry.value);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(entry.key).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }
  });
}
