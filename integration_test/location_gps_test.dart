// Requires a test emulator with foreground location granted and an injected fix.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hom_nay_an_gi/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native foreground GPS resolves without background permissions', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cài đặt').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khu vực của bạn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dùng vị trí của tôi'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    // Plugin work arrives outside the Flutter frame loop on a real device.
    for (
      var i = 0;
      i < 160 && find.text('Vị trí hiện tại').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Vị trí hiện tại'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
