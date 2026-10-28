import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'pitch_detector.dart';
import '../music/music.dart';

class AudioFrame {
  final double? frequency;
  final double confidence, rms, seconds;
  final bool onset;
  const AudioFrame(
    this.frequency,
    this.confidence,
    this.rms,
    this.seconds,
    this.onset,
  );
}

void _analyze(SendPort main) {
  final inbox = ReceivePort();
  main.send(inbox.sendPort);
  var candidate = -1, stable = 0;
  final onset = OnsetDetector();
  inbox.listen((message) {
    final data = message as List;
    final samples = data[0] as Float64List;
    final time = data[1] as double;
    final gate = data[2] as double;
    final pitch = PitchDetector(noiseGate: gate).detect(samples);
    final rms =
        pitch?.rms ??
        sqrt(samples.fold<double>(0, (sum, x) => sum + x * x) / samples.length);
    final midi = pitch == null ? -1 : midiFor(pitch.frequency).round();
    if (midi == candidate) {
      stable++;
    } else {
      candidate = midi;
      stable = 1;
    }
    final confident = pitch != null && pitch.confidence >= .85 && stable >= 2;
    final attack = onset.process(rms, confident ? midi : null, time, gate);
    main.send(
      AudioFrame(
        confident ? pitch.frequency : null,
        pitch?.confidence ?? 0,
        rms,
        time,
        attack,
      ),
    );
  });
}

/// One DSP worker, at most one frame in flight. Time is from a shared monotonic
/// clock at PCM arrival, corrected by the analysis window midpoint. Native
/// capture timestamps are unavailable in record: hardware latency is estimated.
class AudioInputService {
  final AudioRecorder _recorder;
  AudioInputService({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();
  final Stopwatch clock = Stopwatch()..start();
  final _frames = StreamController<AudioFrame>.broadcast();
  Stream<AudioFrame> get frames => _frames.stream;
  StreamSubscription<Uint8List>? _subscription;
  StreamSubscription<RecordState>? _stateSubscription;
  ReceivePort? _results;
  Isolate? _worker;
  SendPort? _send;
  final _buffer = Float64List(4096);
  int _position = 0, _hop = 0;
  int? _lowByte;
  bool _busy = false, active = false, _starting = false;
  int _generation = 0;
  double gate = .008;
  double get seconds => clock.elapsedMicroseconds / 1e6;
  Future<void> _operations = Future.value();
  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _operations.then((_) => operation());
    _operations = next.catchError((Object _) {});
    return next;
  }

  Future<void> start() {
    final generation = ++_generation;
    return _enqueue(() => _start(generation));
  }

  Future<void> _start(int generation) async {
    if (active || _starting) return;
    _starting = true;
    try {
      if (!await _recorder.hasPermission()) {
        throw StateError(
          'Microfoontoegang geweigerd. Geef toestemming via de systeeminstellingen en probeer opnieuw.',
        );
      }
      if (generation != _generation) return;
      final ready = Completer<void>();
      _results = ReceivePort();
      _results!.listen((message) {
        if (message is SendPort) {
          _send = message;
          ready.complete();
        }
        if (message is AudioFrame) {
          _busy = false;
          if (active) _frames.add(message);
        }
      });
      _worker = await Isolate.spawn(_analyze, _results!.sendPort);
      await ready.future;
      if (generation != _generation) {
        await _shutdown();
        return;
      }
      _position = 0;
      _hop = 0;
      _lowByte = null;
      _busy = false;
      _buffer.fillRange(0, _buffer.length, 0);
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 48000,
          numChannels: 1,
          androidConfig: AndroidRecordConfig(
            manageBluetooth: false,
            audioSource: AndroidAudioSource.unprocessed,
          ),
          iosConfig: IosRecordConfig(
            categoryOptions: [],
            allowHapticsAndSystemSoundsDuringRecording: true,
          ),
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        ),
      );
      if (generation != _generation) {
        await _shutdown();
        return;
      }
      active = true;
      _stateSubscription = _recorder.onStateChanged().listen((state) {
        if (active && state != RecordState.record) {
          _frames.addError(
            StateError('Audio onderbroken. Start de microfoon opnieuw.'),
          );
          unawaited(stop());
        }
      });
      _subscription = stream.listen(
        _accept,
        onError: (Object e) {
          _frames.addError(StateError('Microfoonfout: $e'));
          unawaited(stop());
        },
        onDone: () {
          if (active) {
            _frames.addError(
              StateError('Microfoonstream gestopt. Probeer opnieuw.'),
            );
            unawaited(stop());
          }
        },
      );
    } catch (_) {
      await _shutdown();
      rethrow;
    } finally {
      _starting = false;
    }
  }

  void _accept(Uint8List bytes) {
    final arrival = seconds;
    for (var offset = 0; offset < bytes.length; offset++) {
      final byte = bytes[offset];
      if (_lowByte == null) {
        _lowByte = byte;
        continue;
      }
      var value = _lowByte! | (byte << 8);
      _lowByte = null;
      if (value >= 32768) value -= 65536;
      _buffer[_position++ % _buffer.length] = value / 32768;
      _hop++;
      if (_position >= _buffer.length && _hop >= 1024 && !_busy) {
        _hop = 0;
        _busy = true;
        final window = Float64List(_buffer.length);
        final start = _position % _buffer.length;
        for (var i = 0; i < window.length; i++) {
          window[i] = _buffer[(start + i) % _buffer.length];
        }
        _send?.send([
          window,
          arrival - (bytes.length - offset - 1) / 96000 - window.length / 96000,
          gate,
        ]);
      }
    }
  }

  Future<void> stop() {
    _generation++;
    active = false;
    return _enqueue(_shutdown);
  }

  Future<void> _shutdown() async {
    active = false;
    await _subscription?.cancel();
    _subscription = null;
    await _stateSubscription?.cancel();
    _stateSubscription = null;
    try {
      await _recorder.stop();
    } finally {
      _worker?.kill(priority: Isolate.immediate);
      _worker = null;
      _results?.close();
      _results = null;
      _send = null;
      _busy = false;
    }
  }

  Future<void> dispose() async {
    try {
      await stop();
    } finally {
      try {
        await _recorder.dispose();
      } finally {
        await _frames.close();
      }
    }
  }
}
