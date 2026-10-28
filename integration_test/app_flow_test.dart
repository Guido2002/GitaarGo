import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gitaargo/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('app start en navigatie op apparaat', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    if (find.text('Welkom bij GitaarGo!').evaluate().isNotEmpty) {
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Verder'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Begin met spelen'));
      await tester.pumpAndSettle();
    }
    for (final tab in ['Leren', 'Spelen', 'Stemmen', 'Profiel', 'Vandaag']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
