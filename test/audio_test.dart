import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitaargo/core/audio/pitch_detector.dart';
import 'package:gitaargo/core/music/music.dart';

Float64List tone(
  double hz,
  int rate, {
  double amplitude = .3,
  bool harmonics = false,
}) => Float64List.fromList(
  List.generate(4096, (i) {
    final t = 2 * pi * hz * i / rate;
    return amplitude *
        (sin(t) + (harmonics ? .8 * sin(2 * t) + .5 * sin(3 * t) : 0));
  }),
);
void main() {
  for (final rate in [44100, 48000]) {
    for (final midi in [38, 40, 45, 50, 55, 59, 64, 76]) {
      test('YIN ${noteName(midi)} bij $rate Hz en harmonischen', () {
        for (final harmonics in [false, true]) {
          final result = PitchDetector(sampleRate: rate)
              .detect(tone(frequencyFor(midi), rate, harmonics: harmonics));
          expect(result, isNotNull);
          expect(centsFor(result!.frequency, midi).abs(), lessThan(3));
          expect(result.confidence, greaterThan(.85));
        }
      });
    }
  }
  test('stilte, lage amplitude en breedbandruis worden onzeker', () {
    final detector = PitchDetector();
    expect(detector.detect(Float64List(4096)), isNull);
    expect(detector.detect(tone(110, 48000, amplitude: .001)), isNull);
    final random = Random(19);
    expect(
      detector.detect(
        Float64List.fromList(
          List.generate(4096, (_) => random.nextDouble() * .5 - .25),
        ),
      ),
      isNull,
    );
    expect(detector.detect(tone(110, 48000, amplitude: .014)), isNotNull);
  });
  test('aangehouden noot telt eenmaal, release en nieuwe pitch heropenen', () {
    final onset = OnsetDetector();
    expect(onset.process(.1, 40, 0, .008), true);
    for (var i = 1; i < 100; i++) {
      expect(onset.process(.1, 40, i * .03, .008), false);
    }
    expect(onset.process(0, null, 3, .008), false);
    expect(onset.process(.1, 40, 3.1, .008), true);
    expect(onset.process(.1, 45, 3.4, .008), true);
    expect(onset.process(.3, 45, 3.45, .008), false);
  });
}
