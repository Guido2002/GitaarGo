import 'dart:math';
import 'dart:typed_data';

class PitchEstimate {
  final double frequency, confidence, rms;
  const PitchEstimate(this.frequency, this.confidence, this.rms);
}

/// YIN cumulative mean normalized difference. Selects the first strong minimum,
/// rather than the strongest harmonic. No estimate is emitted below the gate.
class PitchDetector {
  final int sampleRate;
  final double noiseGate;
  PitchDetector({this.sampleRate = 48000, this.noiseGate = .008});
  PitchEstimate? detect(Float64List input) {
    if (input.length < 4) return null;
    final mean = input.reduce((a, b) => a + b) / input.length;
    var energy = 0.0;
    for (final v in input) {
      energy += (v - mean) * (v - mean);
    }
    final rms = sqrt(energy / input.length);
    if (rms < noiseGate) return null;
    final maxTau = min(sampleRate ~/ 65, input.length ~/ 2 - 1);
    final minTau = sampleRate ~/ 1400;
    final difference = Float64List(maxTau + 1);
    final window = input.length - maxTau;
    for (var tau = 1; tau <= maxTau; tau++) {
      var sum = 0.0;
      for (var i = 0; i < window; i++) {
        final d = input[i] - input[i + tau];
        sum += d * d;
      }
      difference[tau] = sum;
    }
    var cumulative = 0.0;
    for (var tau = 1; tau <= maxTau; tau++) {
      cumulative += difference[tau];
      difference[tau] = cumulative == 0
          ? 1
          : difference[tau] * tau / cumulative;
    }
    for (var tau = minTau; tau < maxTau - 1; tau++) {
      if (difference[tau] > .15) continue;
      while (tau + 1 < maxTau && difference[tau + 1] < difference[tau]) {
        tau++;
      }
      final a = difference[tau - 1],
          b = difference[tau],
          c = difference[tau + 1];
      final denominator = a - 2 * b + c;
      final refined =
          tau + (denominator.abs() < 1e-12 ? 0 : .5 * (a - c) / denominator);
      return PitchEstimate(sampleRate / refined, (1 - b).clamp(0, 1), rms);
    }
    return null;
  }
}

/// Rearms only after a release, a fresh energy transient or a stable pitch change.
class OnsetDetector {
  double _previous = 0;
  double _lastOnset = -100;
  int? _lastMidi;
  bool _silent = true;
  bool process(double rms, int? midi, double seconds, double gate) {
    if (rms < gate) {
      _silent = true;
      _previous = rms;
      return false;
    }
    final attack =
        _silent ||
        rms > max(gate * 2, _previous * 1.65) ||
        (midi != null && _lastMidi != null && midi != _lastMidi);
    _previous = rms;
    if (midi == null || !attack || seconds - _lastOnset < .14) return false;
    _silent = false;
    _lastMidi = midi;
    _lastOnset = seconds;
    return true;
  }
}
