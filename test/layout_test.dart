import 'dart:convert';

import 'package:drift/native.dart';
import 'package:gitaargo/features/learning/learning_screen.dart';
import 'package:gitaargo/core/scoring/score_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitaargo/app/app.dart';
import 'package:gitaargo/app/state.dart';
import 'package:gitaargo/core/database/app_database.dart';

void main() {
  late List<Exercise> exercises;
  setUpAll(() async {
    exercises = (jsonDecode(
      await rootBundle.loadString('assets/exercises/library.json'),
    ) as List).map((j) => Exercise.fromJson(j)).toList();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final font = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await font.load();
  });
  for (final light in [false, true]) {
    testWidgets(
      '${light ? 'licht' : 'donker'}: compacte layout en grote tekst',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await db.setting('onboarded', true);
        await db.setting('theme', light ? 'light' : 'dark');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              nowProvider.overrideWithValue(DateTime(2026, 10, 28)),
              exercisesProvider.overrideWith((ref) async => exercises),
            ],
            child: const GitaarGoApp(),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(GitaarGoApp),
          matchesGoldenFile('goldens/home_${light ? 'light' : 'dark'}.png'),
        );
        tester.platformDispatcher.textScaleFactorTestValue = 1.8;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        for (final tab in [
          'Leren',
          'Spelen',
          'Stemmen',
          'Profiel',
          'Vandaag',
        ]) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }
}
