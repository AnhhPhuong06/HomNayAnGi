import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'moderation_test.dart' as fixtures;

void main() {
  testWidgets('review actions fit a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await fixtures.mount(tester, fixtures.MemoryModeration());
    await tester.scrollUntilVisible(
      find.text(fixtures.report.reason).hitTestable(),
      100,
    );
    await tester.tap(find.text(fixtures.report.reason));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);
    final dialogScroll = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Gỡ bài vi phạm').hitTestable(),
      100,
      scrollable: dialogScroll.first,
    );
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Giữ bài, hoàn tất báo cáo').hitTestable(),
      -80,
      scrollable: dialogScroll.first,
    );
    expect(
      find.text('Giữ bài, hoàn tất báo cáo').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Gỡ bài vi phạm').hitTestable(),
      100,
      scrollable: dialogScroll.first,
    );
    await tester.tap(find.text('Gỡ bài vi phạm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);
    expect(find.text('Xác nhận gỡ bài').hitTestable(), findsOneWidget);
    expect(find.text('Hủy').hitTestable(), findsOneWidget);
  });
}
