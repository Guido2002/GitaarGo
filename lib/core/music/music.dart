import 'dart:math';

double frequencyFor(num midi, [double reference = 440]) =>
    reference * pow(2, (midi - 69) / 12);
double midiFor(double frequency, [double reference = 440]) =>
    69 + 12 * log(frequency / reference) / ln2;
String noteName(int midi) =>
    '${['C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B'][midi % 12]}${midi ~/ 12 - 1}';
double centsFor(double frequency, int midi, [double reference = 440]) =>
    (midiFor(frequency, reference) - midi) * 100;

/// String order is always 1 (high e) through 6 (low E).
const tunings = <String, List<int>>{
  'Standaard': [64, 59, 55, 50, 45, 40],
  'Drop D': [64, 59, 55, 50, 45, 38],
  'Halve toon lager': [63, 58, 54, 49, 44, 39],
  'Hele toon lager': [62, 57, 53, 48, 43, 38],
  'Open G': [62, 59, 55, 50, 43, 38],
  'Open D': [62, 57, 54, 50, 45, 38],
  'DADGAD': [62, 57, 55, 50, 45, 38],
};

class GuitarChord {
  final String name;
  final List<int> frets; // Low E to high e for conventional diagram reading.
  final List<int> fingers;
  final int barre;
  const GuitarChord(this.name, this.frets, this.fingers, {this.barre = 0});
}

const chords = [
  GuitarChord('C majeur', [-1, 3, 2, 0, 1, 0], [0, 3, 2, 0, 1, 0]),
  GuitarChord('G majeur', [3, 2, 0, 0, 0, 3], [2, 1, 0, 0, 0, 3]),
  GuitarChord('D majeur', [-1, -1, 0, 2, 3, 2], [0, 0, 0, 1, 3, 2]),
  GuitarChord('A mineur', [-1, 0, 2, 2, 1, 0], [0, 0, 2, 3, 1, 0]),
  GuitarChord('E mineur', [0, 2, 2, 0, 0, 0], [0, 2, 3, 0, 0, 0]),
  GuitarChord('A7', [-1, 0, 2, 0, 2, 0], [0, 0, 1, 0, 2, 0]),
  GuitarChord('Cmaj7', [-1, 3, 2, 0, 0, 0], [0, 3, 2, 0, 0, 0]),
  GuitarChord('Am7', [-1, 0, 2, 0, 1, 0], [0, 0, 2, 0, 1, 0]),
  GuitarChord('Dsus2', [-1, -1, 0, 2, 3, 0], [0, 0, 0, 1, 3, 0]),
  GuitarChord('Dsus4', [-1, -1, 0, 2, 3, 3], [0, 0, 0, 1, 3, 4]),
  GuitarChord('E5', [0, 2, 2, -1, -1, -1], [0, 1, 3, 0, 0, 0]),
  GuitarChord('F majeur', [1, 3, 3, 2, 1, 1], [1, 3, 4, 2, 1, 1], barre: 1),
];
GuitarChord dailyChord(DateTime date) =>
    chords[DateTime.utc(
          date.year,
          date.month,
          date.day,
        ).difference(DateTime.utc(2026)).inDays %
        chords.length];
