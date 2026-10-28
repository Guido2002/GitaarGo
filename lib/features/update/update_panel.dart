import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state.dart';
import '../../core/widgets/page_layout.dart';
import 'update_controller.dart';

class UpdatePanel extends ConsumerWidget {
  const UpdatePanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isAndroid) return const SizedBox.shrink();
    final s = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    final settings = ref.watch(settingsProvider).asData?.value ?? {};
    final downloading =
        s.phase == UpdatePhase.downloading || s.phase == UpdatePhase.cancelling;
    final downloaded =
        s.phase == UpdatePhase.downloaded ||
        s.phase == UpdatePhase.installerOpened;
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('App-updates', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (s.version != null) Text('Geïnstalleerd: ${s.version}'),
          const Text(
            'Download nieuwe versies rechtstreeks van GitHub. Je oefengegevens blijven bewaard.',
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Automatisch controleren bij opstarten'),
            value: settings['autoUpdates'] != false,
            onChanged: (value) async {
              try {
                await updateSetting(ref, 'autoUpdates', value);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Instelling opslaan mislukt: $e')),
                  );
                }
              }
            },
          ),
          if (s.release != null) ...[
            Text(
              'Versie ${s.release!.version} beschikbaar',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('${(s.release!.apk.size / 1000000).toStringAsFixed(1)} MB'),
            if (s.release!.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  s.release!.notes,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          if (s.message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(s.message!),
            ),
          if (downloading) ...[
            LinearProgressIndicator(value: s.progress),
            Text('${(s.progress * 100).round()}% gedownload'),
            TextButton(
              onPressed: s.phase == UpdatePhase.cancelling
                  ? null
                  : controller.cancel,
              child: const Text('Download annuleren'),
            ),
          ] else if (downloaded)
            FilledButton.icon(
              onPressed: controller.install,
              icon: const Icon(Icons.system_update),
              label: const Text('Installeren'),
            )
          else if (s.release != null)
            FilledButton.icon(
              onPressed: controller.download,
              icon: const Icon(Icons.download),
              label: const Text('Update downloaden'),
            ),
          if (!downloading && !downloaded)
            TextButton.icon(
              onPressed: controller.busy ? null : () => controller.check(),
              icon: const Icon(Icons.refresh),
              label: Text(
                s.phase == UpdatePhase.checking
                    ? 'Controleren…'
                    : 'Controleren op updates',
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Android vraagt altijd om bevestiging. Bij geweigerde installatietoestemming kun je die in de systeeminstellingen voor GitaarGo inschakelen.',
          ),
        ],
      ),
    );
  }
}

/// Checks once per app session after onboarding. A non-blocking banner keeps
/// discovery out of microphone/gameplay screens; installation stays explicit.
class UpdateStartup extends ConsumerStatefulWidget {
  final Widget child;
  const UpdateStartup({super.key, required this.child});
  @override
  ConsumerState<UpdateStartup> createState() => _UpdateStartupState();
}

class _UpdateStartupState extends ConsumerState<UpdateStartup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          ref.read(settingsProvider).asData?.value['autoUpdates'] != false) {
        ref.read(updateControllerProvider.notifier).check(automatic: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
