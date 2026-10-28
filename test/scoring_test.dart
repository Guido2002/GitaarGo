import 'package:flutter_test/flutter_test.dart';
import 'package:gitaargo/core/scoring/score_engine.dart';

void main() {
  const e = Exercise('test', 'Test', 60, [
    TargetNote(40, 0, 6, 0),
    TargetNote(45, 1, 5, 0),
  ]);
  test('muzikale tijdlijn rekent BPM en aftellen om', () {
    expect(e.timeAt(e.notes[0]), 2);
    expect(e.timeAt(e.notes[1]), 3);
    expect(e.duration, 4.5);
  });
  for (final (delta, judgment, points) in [
    (0.05, Judgment.perfect, 100),
    (.1, Judgment.great, 75),
    (.16, Judgment.good, 50),
  ]) {
    test('timingvenster $delta inclusief grens', () {
      final s = ScoreEngine(e);
      expect(s.input(40, 2 + delta, .95), judgment);
      expect(s.score, points);
    });
  }
  test('verkeerde, onzekere en herhaalde invoer geven geen gratis score', () {
    final s = ScoreEngine(e);
    expect(s.input(41, 2, .99), isNull);
    expect(s.input(40, 2, .5), isNull);
    expect(s.score, 0);
    expect(s.input(40, 2, .99), Judgment.perfect);
    expect(s.input(40, 2, .99), isNull);
    expect(s.score, 100);
    s.expire(3.17);
    expect(s.combo, 0);
    expect(s.hits, 1);
    expect(s.accuracy, .5);
  });
  test('latency corrigeert audio en miss-vensters', () {
    final s = ScoreEngine(e, latencySeconds: .1);
    expect(s.input(40, 2.1, .99), Judgment.perfect);
  });
  test('combo multiplier en stilte', () {
    final exercise = Exercise(
      'long',
      'Lang',
      60,
      List.generate(51, (i) => TargetNote(40, i.toDouble(), 6, 0)),
    );
    final s = ScoreEngine(exercise);
    for (var i = 0; i < 50; i++) {
      s.input(40, 2 + i.toDouble(), .99);
    }
    expect(s.maxCombo, 50);
    expect(s.multiplier, 4);
    s.expire(99);
    expect(s.combo, 0);
    final silence = ScoreEngine(exercise)..expire(99);
    expect(silence.score, 0);
    expect(silence.hits, 0);
    expect(silence.judged.length, 51);
  });
}
