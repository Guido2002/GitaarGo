import 'dart:convert';
import 'dart:io';

import '../scoring/rewards.dart';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PracticeResult {
  final String id, exercise, day;
  final int score, hits, total, perfects, maxCombo, seconds, xp;
  const PracticeResult({
    required this.id,
    required this.exercise,
    required this.day,
    required this.score,
    required this.hits,
    required this.total,
    required this.perfects,
    required this.maxCombo,
    required this.seconds,
    required this.xp,
  });
  Map<String, Object> toJson() => {
    'id': id,
    'exercise': exercise,
    'day': day,
    'score': score,
    'hits': hits,
    'total': total,
    'perfects': perfects,
    'maxCombo': maxCombo,
    'seconds': seconds,
    'xp': xp,
  };
  factory PracticeResult.fromJson(Map<String, dynamic> j) => PracticeResult(
    id: j['id'],
    exercise: j['exercise'],
    day: j['day'],
    score: j['score'],
    hits: j['hits'],
    total: j['total'],
    perfects: j['perfects'],
    maxCombo: j['maxCombo'],
    seconds: j['seconds'],
    xp: j['xp'],
  );
}

String localDay(DateTime time) =>
    '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
int practiceStreak(List<PracticeResult> results, DateTime now) {
  final days = results.where((r) => r.hits > 0).map((r) => r.day).toSet();
  var date = DateTime.utc(now.year, now.month, now.day);
  if (!days.contains(localDay(date))) {
    date = date.subtract(const Duration(days: 1));
  }
  var streak = 0;
  while (days.contains(localDay(date))) {
    streak++;
    date = date.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Small explicit SQL schema; Drift owns transactions and background execution.
class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.executor);
  factory AppDatabase.open() => AppDatabase(
    LazyDatabase(() async {
      final dir = await getApplicationSupportDirectory();
      return NativeDatabase.createInBackground(
        File(p.join(dir.path, 'gitaargo.sqlite')),
      );
    }),
  );
  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await customStatement(
        'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
      await customStatement(
        'CREATE TABLE sessions (id TEXT PRIMARY KEY, data TEXT NOT NULL)',
      );
    },
  );
  Future<Map<String, dynamic>> settings() async => {
    for (final row in await customSelect('SELECT * FROM settings').get())
      row.read<String>('key'): jsonDecode(row.read<String>('value')),
  };
  Future<void> setting(String key, Object value) => customStatement(
    'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)',
    [key, jsonEncode(value)],
  );
  Future<List<PracticeResult>> results() async =>
      (await customSelect('SELECT data FROM sessions ORDER BY rowid DESC')
              .get())
          .map(
            (r) => PracticeResult.fromJson(jsonDecode(r.read<String>('data'))),
          )
          .toList();
  Future<void> save(PracticeResult result) => customStatement(
    'INSERT OR IGNORE INTO sessions (id, data) VALUES (?, ?)',
    [result.id, jsonEncode(result.toJson())],
  );
  Future<PracticeResult> complete(PracticeResult pending) =>
      transaction(() async {
        final prior = await results();
        for (final existing in prior) {
          if (existing.id == pending.id) return existing;
        }
        final todayHits = prior
            .where((r) => r.day == pending.day)
            .fold(0, (v, r) => v + r.hits);
        final personalBest = prior
            .where((r) => r.exercise == pending.exercise)
            .fold(0, (v, r) => r.score > v ? r.score : v);
        final data = pending.toJson();
        data['xp'] = sessionXp(
          hits: pending.hits,
          score: pending.score,
          personalBest: personalBest,
          todayHits: todayHits,
        );
        final awarded = PracticeResult.fromJson(data);
        await save(awarded);
        return awarded;
      });
  Future<void> clearResults() => customStatement('DELETE FROM sessions');
}
