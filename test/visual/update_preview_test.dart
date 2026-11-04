// Shipping update dialog with fixture versions; not a published 1.2.0 release.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hom_nay_an_gi/core/theme/app_theme.dart';
import 'package:hom_nay_an_gi/features/updates/update_widgets.dart';
import '../update_test.dart' as fixtures;

void main() {
  const enabled = bool.fromEnvironment('RENDER_UPDATE_PREVIEW');
  testWidgets('update_dialog_fixture', (tester) async {
    final font = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final capture = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: capture,
        child: MaterialApp(
          theme: appTheme(Brightness.light),
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            appBar: AppBar(title: const Text('Hôm Nay Ăn Gì?')),
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => AppUpdateDialog(
                      release: fixtures.manifest().releases.single,
                      installed: fixtures.oldApp,
                    ),
                  ),
                  child: const Text('Kiểm tra cập nhật'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Kiểm tra cập nhật'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image =
          await (capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('artifacts').create(recursive: true);
      await File(
        'artifacts/update_dialog_fixture.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }, skip: !enabled);
}
