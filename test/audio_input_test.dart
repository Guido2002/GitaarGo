import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:gitaargo/core/audio/audio_input_service.dart';
import 'package:gitaargo/core/music/music.dart';

class TestRecorder implements AudioRecorder {
  final stream = StreamController<Uint8List>.broadcast();
  final states = StreamController<RecordState>.broadcast();
  bool allowed = true, recording = false;
  Completer<bool>? permission;
  @override
  Future<bool> hasPermission({bool request = true}) async =>
      permission == null ? allowed : await permission!.future;
  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async {
    expect(config.encoder, AudioEncoder.pcm16bits);
    recording = true;
    return stream.stream;
  }

  @override
  Stream<RecordState> onStateChanged() => states.stream;
  @override
  Future<String?> stop() async {
    recording = false;
    return null;
  }

  @override
  Future<void> dispose() async {
    await stream.close();
    await states.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'PCM-stream wordt via echte DSP-isolate een toon; stop sluit invoer',
    () async {
      final recorder = TestRecorder();
      final audio = AudioInputService(recorder: recorder);
      final frames = <AudioFrame>[];
      final subscription = audio.frames.listen(frames.add);
      await audio.start();
      for (var chunk = 0; chunk < 18; chunk++) {
        final pcm = ByteData(2048);
        for (var i = 0; i < 1024; i++) {
          pcm.setInt16(
            i * 2,
            (10000 * sin(2 * pi * 110 * (chunk * 1024 + i) / 48000)).round(),
            Endian.little,
          );
        }
        recorder.stream.add(pcm.buffer.asUint8List());
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      final recognized = frames.where((f) => f.frequency != null).toList();
      expect(recognized, isNotEmpty);
      expect(centsFor(recognized.last.frequency!, 45).abs(), lessThan(3));
      expect(frames.where((f) => f.onset).length, 1);
      await audio.stop();
      expect(audio.active, false);
      expect(recorder.recording, false);
      await subscription.cancel();
      await audio.dispose();
    },
  );
  test(
    'geen toestemming levert expliciete fout en geen actieve microfoon',
    () async {
      final recorder = TestRecorder()..allowed = false;
      final audio = AudioInputService(recorder: recorder);
      await expectLater(audio.start(), throwsStateError);
      expect(audio.active, false);
      await audio.dispose();
    },
  );
  test('weg navigeren tijdens permissiedialoog annuleert start', () async {
    final recorder = TestRecorder()..permission = Completer<bool>();
    final audio = AudioInputService(recorder: recorder);
    final start = audio.start();
    await Future<void>.delayed(Duration.zero);
    final stop = audio.stop();
    recorder.permission!.complete(true);
    await start;
    await stop;
    expect(audio.active, false);
    expect(recorder.recording, false);
    await audio.dispose();
  });
}
