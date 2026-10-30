// Prepare the emulator permission state as documented in README before running.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hom_nay_an_gi/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native GPS denied forever retains manual selection', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cài đặt').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khu vực của bạn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dùng vị trí của tôi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Quyền vị trí đã bị khóa'), findsOneWidget);
    expect(find.text('Chọn khu vực thủ công'), findsOneWidget);
    await tester.tap(find.text('Bắc Ninh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khu vực Bắc Ninh (demo)'));
    await tester.pumpAndSettle();
    expect(find.text('Khu vực Bắc Ninh (demo), Bắc Ninh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
