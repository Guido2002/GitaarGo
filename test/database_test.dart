import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitaargo/core/database/app_database.dart';

PracticeResult result(String id, String day, {int hits = 1}) => PracticeResult(
  id: id,
  exercise: 'Test',
  day: day,
  score: hits * 100,
  hits: hits,
  total: 1,
  perfects: hits,
  maxCombo: hits,
  seconds: 10,
  xp: hits > 0 ? 25 : 0,
);
void main() {
  test(
    'transactionele beloningen zijn idempotent en daguitdaging telt eenmaal',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final first = await db.complete(result('first', '2026-10-28', hits: 9));
      expect(first.xp, 55);
      final second = await db.complete(result('second', '2026-10-28', hits: 1));
      expect(second.xp, 125);
      expect(
        (await db.complete(result('second', '2026-10-28', hits: 1))).xp,
        125,
      );
      final third = await db.complete(result('third', '2026-10-28', hits: 1));
      expect(third.xp, 25);
      final silent = await db.complete(result('silent', '2026-10-28', hits: 0));
      expect(silent.xp, 0);
      expect((await db.results()).length, 4);
      await db.close();
    },
  );

  test(
    'sessies en instellingen overleven heropenen; sessie-id is uniek',
    () async {
      final dir = await Directory.systemTemp.createTemp('gitaargo-test');
      final file = File('${dir.path}/test.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      await db.setting('reference', 442);
      await db.setting('onboarded', true);
      await db.save(result('1', '2026-10-28'));
      await db.save(result('1', '2026-10-28'));
      expect((await db.results()).length, 1);
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      expect((await db.settings())['reference'], 442);
      expect((await db.results()).single.xp, 25);
      await db.clearResults();
      expect(await db.results(), isEmpty);
      expect((await db.settings())['onboarded'], true);
      await db.close();
      await dir.delete(recursive: true);
    },
  );
  test('streak telt gespeelde kalenderdagen, met gisteren en lege input', () {
    final r = [
      result('1', '2026-10-27'),
      result('2', '2026-10-26'),
      result('3', '2026-10-28', hits: 0),
    ];
    expect(practiceStreak(r, DateTime(2026, 10, 28)), 2);
    expect(practiceStreak(r, DateTime(2026, 10, 29)), 0);
    expect(
      practiceStreak([
        result('x', '2026-03-29'),
        result('y', '2026-03-28'),
      ], DateTime(2026, 3, 30)),
      2,
    );
  });
}
