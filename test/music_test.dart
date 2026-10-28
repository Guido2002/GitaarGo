import 'package:flutter_test/flutter_test.dart';
import 'package:gitaargo/core/music/music.dart';

void main() {
  test('frequentie, MIDI en cents bij instelbare referentie', () {
    for (var midi = 36; midi <= 88; midi++) {
      expect(midiFor(frequencyFor(midi)), closeTo(midi.toDouble(), 1e-9));
      expect(centsFor(frequencyFor(midi + .14), midi), closeTo(14, 1e-7));
    }
    expect(frequencyFor(69, 442), 442);
    expect(noteName(40), 'E2');
    expect(noteName(64), 'E4');
  });
  test('stemmingen gebruiken snaar 1 hoog tot snaar 6 laag', () {
    expect(tunings.length, 7);
    expect(tunings['Standaard'], [64, 59, 55, 50, 45, 40]);
    expect(tunings['Drop D']!.last, 38);
    for (final t in tunings.values) {
      expect(t.length, 6);
      expect(t.first, greaterThan(t.last));
    }
  });
  test('alle akkoordvoicings zijn geldige drieklanken of varianten', () {
    const roots = [0, 7, 2, 9, 4, 9, 0, 9, 2, 2, 4, 5];
    const intervals = [
      {0, 4, 7},
      {0, 4, 7},
      {0, 4, 7},
      {0, 3, 7},
      {0, 3, 7},
      {0, 4, 7, 10},
      {0, 4, 7, 11},
      {0, 3, 7, 10},
      {0, 2, 7},
      {0, 5, 7},
      {0, 7},
      {0, 4, 7},
    ];
    for (var c = 0; c < chords.length; c++) {
      final pcs = <int>{};
      final open = tunings['Standaard']!.reversed.toList();
      for (var s = 0; s < 6; s++) {
        if (chords[c].frets[s] >= 0) {
          pcs.add((open[s] + chords[c].frets[s] - roots[c]) % 12);
        }
      }
      expect(pcs, intervals[c], reason: chords[c].name);
    }
  });
  test('dagakkoord verandert op lokale kalenderdag, niet tijdens herstart', () {
    expect(
      dailyChord(DateTime(2026, 10, 28, 1)),
      same(dailyChord(DateTime(2026, 10, 28, 23))),
    );
    expect(
      dailyChord(DateTime(2026, 10, 28)),
      isNot(same(dailyChord(DateTime(2026, 10, 29)))),
    );
  });
}
