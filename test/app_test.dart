import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitaargo/app/app.dart';
import 'package:gitaargo/app/state.dart';
import 'package:gitaargo/core/database/app_database.dart';

void main() {
  testWidgets(
    'onboarding, vijf tabs, oefening en geen verzonnen statistieken',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const GitaarGoApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Welkom bij GitaarGo!'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Verder'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Begin met spelen'));
      await tester.pumpAndSettle();
      expect(find.text('Jouw dagelijkse dosis gitaar.'), findsOneWidget);
      expect(await db.results(), isEmpty);
      for (final tab in ['Leren', 'Spelen', 'Stemmen', 'Profiel', 'Vandaag']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.text('Leren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start nootoefening'));
      await tester.pumpAndSettle();
      expect(find.text('Start met microfoon'), findsOneWidget);
      expect(await db.results(), isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await db.close();
    },
  );
}
