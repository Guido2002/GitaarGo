/// All rewards require actual correct input. A challenge is awarded only when
/// crossing its threshold; persistence applies this inside one transaction.
int sessionXp({
  required int hits,
  required int score,
  required int personalBest,
  required int todayHits,
}) {
  if (hits <= 0) return 0;
  return 25 +
      (score > personalBest ? 30 : 0) +
      (todayHits < 10 && todayHits + hits >= 10 ? 100 : 0);
}
