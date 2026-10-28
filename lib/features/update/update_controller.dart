import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'update_service.dart';

enum UpdatePhase {
  idle,
  checking,
  available,
  downloading,
  cancelling,
  downloaded,
  installerOpened,
  error,
}

class UpdateState {
  final UpdatePhase phase;
  final AppRelease? release;
  final double progress;
  final String? message;
  final String? version;
  const UpdateState({
    this.phase = UpdatePhase.idle,
    this.release,
    this.progress = 0,
    this.message,
    this.version,
  });
}

final updateServiceFactoryProvider = Provider<UpdateService Function()>(
  (ref) => UpdateService.new,
);
final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

class UpdateController extends Notifier<UpdateState> {
  UpdateService? _service;
  File? _downloaded;
  bool _autoChecked = false, _disposed = false, _checking = false;
  @override
  UpdateState build() {
    ref.onDispose(() {
      _disposed = true;
      _service?.close();
    });
    return const UpdateState();
  }

  bool get busy =>
      _checking ||
      state.phase == UpdatePhase.checking ||
      state.phase == UpdatePhase.downloading ||
      state.phase == UpdatePhase.cancelling;
  Future<void> check({bool automatic = false}) async {
    if (!Platform.isAndroid || busy || (automatic && _autoChecked)) return;
    _autoChecked = true;
    _checking = true;
    final previous = state;
    if (!automatic) {
      state = UpdateState(
        phase: UpdatePhase.checking,
        version: previous.version,
      );
    }
    final service = ref.read(updateServiceFactoryProvider)();
    _service = service;
    try {
      final info = await PackageInfo.fromPlatform();
      final release = await service.check(info.version);
      if (_disposed) return;
      state = UpdateState(
        phase: release == null ? UpdatePhase.idle : UpdatePhase.available,
        release: release,
        version: info.version,
        message: release == null
            ? 'Er is geen nieuwere release beschikbaar.'
            : null,
      );
    } catch (e) {
      if (!_disposed && !automatic) {
        state = UpdateState(
          phase: UpdatePhase.error,
          release: previous.release,
          version: previous.version,
          message:
              'Updates controleren lukt niet. Controleer je internetverbinding en probeer opnieuw. ($e)',
        );
      }
    } finally {
      _checking = false;
      service.close();
      if (identical(_service, service)) _service = null;
    }
  }

  Future<void> download() async {
    final release = state.release;
    if (release == null || busy) return;
    final version = state.version;
    state = UpdateState(
      phase: UpdatePhase.downloading,
      release: release,
      version: version,
    );
    final service = ref.read(updateServiceFactoryProvider)();
    _service = service;
    try {
      _downloaded = await service.download(
        release,
        Directory('${(await getTemporaryDirectory()).path}/gitaargo-updates'),
        onProgress: (progress) {
          if (!_disposed && state.phase == UpdatePhase.downloading) {
            state = UpdateState(
              phase: UpdatePhase.downloading,
              release: release,
              progress: progress,
              version: version,
            );
          }
        },
      );
      if (!_disposed) {
        state = UpdateState(
          phase: UpdatePhase.downloaded,
          release: release,
          version: version,
          message: 'Download gecontroleerd. Je kunt de update installeren.',
        );
      }
    } catch (e) {
      if (!_disposed &&
          (state.phase == UpdatePhase.downloading ||
              state.phase == UpdatePhase.cancelling)) {
        final cancelled = state.phase == UpdatePhase.cancelling;
        state = UpdateState(
          phase: cancelled ? UpdatePhase.available : UpdatePhase.error,
          release: release,
          version: version,
          message: cancelled ? 'Download geannuleerd.' : 'Download mislukt: $e',
        );
      }
    } finally {
      service.close();
      if (identical(_service, service)) _service = null;
    }
  }

  void cancel() {
    if (state.phase != UpdatePhase.downloading) return;
    state = UpdateState(
      phase: UpdatePhase.cancelling,
      release: state.release,
      version: state.version,
      progress: state.progress,
      message: 'Download wordt geannuleerd…',
    );
    _service?.close();
  }

  Future<void> install() async {
    final file = _downloaded;
    if (file == null) return;
    final previous = state;
    try {
      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );
      if (_disposed) return;
      state = UpdateState(
        phase: result.type == ResultType.done
            ? UpdatePhase.installerOpened
            : UpdatePhase.downloaded,
        release: previous.release,
        version: previous.version,
        message: result.type == ResultType.done
            ? 'Bevestig de update in Android. Geef GitaarGo zo nodig toestemming om apps te installeren en tik daarna opnieuw op Installeren. Dit venster weet alleen dat de installer is geopend; je huidige versie verandert pas na installatie.'
            : 'Android kon de installer niet openen: ${result.message}. Geef GitaarGo zo nodig installatietoestemming in Instellingen en probeer opnieuw.',
      );
    } catch (e) {
      if (!_disposed) {
        state = UpdateState(
          phase: UpdatePhase.downloaded,
          release: previous.release,
          version: previous.version,
          message: 'Installer openen mislukt: $e',
        );
      }
    }
  }
}
