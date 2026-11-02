import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hom_nay_an_gi/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'shipping app requires login; all social providers are visible without backend config',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle();
      expect(find.text('CHỌN GIÚP TÔI'), findsNothing);
      for (final name in ['Google', 'Facebook', 'Apple']) {
        await tester.ensureVisible(find.text('Tiếp tục với $name'));
        await tester.pumpAndSettle();
        expect(find.text('Tiếp tục với $name'), findsOneWidget);
      }
      expect(find.text('Ảnh món ăn minh họa'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
