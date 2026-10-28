import 'dart:math';
import 'dart:io';
import 'dart:typed_data';

import 'package:gitaargo/core/audio/pitch_detector.dart';

void main() {
  final detector = PitchDetector();
  final samples = Float64List.fromList(
    List.generate(
      4096,
      (i) =>
          .3 * sin(2 * pi * 82.406889 * i / 48000) +
          .12 * sin(4 * pi * 82.406889 * i / 48000),
    ),
  );
  for (var i = 0; i < 30; i++) {
    detector.detect(samples);
  }
  final timings = <double>[];
  for (var i = 0; i < 100; i++) {
    final watch = Stopwatch()..start();
    detector.detect(samples);
    watch.stop();
    timings.add(watch.elapsedMicroseconds / 1000);
  }
  timings.sort();
  stdout.writeln('YIN 4096 samples / 48 kHz; 100 frames; desktop Dart JIT');
  stdout.writeln(
    'median: ${timings[50].toStringAsFixed(2)} ms; p95: ${timings[95].toStringAsFixed(2)} ms; budget per hop: 21.33 ms',
  );
}
