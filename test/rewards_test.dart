import 'package:flutter_test/flutter_test.dart';
import 'package:gitaargo/core/scoring/rewards.dart';

void main() {
  test('XP vereist echte hits, record en drempelpassage', () {
    expect(sessionXp(hits: 0, score: 0, personalBest: 0, todayHits: 0), 0);
    expect(sessionXp(hits: 1, score: 100, personalBest: 0, todayHits: 0), 55);
    expect(
      sessionXp(hits: 2, score: 100, personalBest: 100, todayHits: 9),
      125,
    );
    expect(
      sessionXp(hits: 2, score: 100, personalBest: 100, todayHits: 10),
      25,
    );
  });
}
