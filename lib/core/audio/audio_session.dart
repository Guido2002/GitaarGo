import 'dart:async';

import 'package:flutter/widgets.dart';

import 'audio_input_service.dart';

/// Stops on navigation, interruptions and backgrounding. Resume is explicit.
class AudioSession extends ChangeNotifier with WidgetsBindingObserver {
  final AudioInputService input;
  final bool _ownsInput;
  StreamSubscription<AudioFrame>? _subscription;
  AudioFrame? frame;
  String? error;
  bool starting = false, _disposed = false;
  void Function(AudioFrame)? onFrame;
  VoidCallback? onStopped;
  AudioSession({AudioInputService? input})
    : input = input ?? AudioInputService(),
      _ownsInput = input == null {
    WidgetsBinding.instance.addObserver(this);
    _subscription = this.input.frames.listen(
      (f) {
        frame = f;
        onFrame?.call(f);
        if (!_disposed) notifyListeners();
      },
      onError: (Object e) {
        error = e.toString();
        unawaited(stop());
      },
    );
  }
  bool get active => input.active;
  Future<void> start(double gate) async {
    if (starting || active) return;
    starting = true;
    error = null;
    frame = null;
    notifyListeners();
    input.gate = gate;
    try {
      await input.start();
    } catch (e) {
      error = e.toString();
    } finally {
      starting = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> stop() async {
    onStopped?.call();
    await input.stop();
    frame = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(stop());
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    unawaited(_ownsInput ? input.dispose() : input.stop());
    super.dispose();
  }
}
