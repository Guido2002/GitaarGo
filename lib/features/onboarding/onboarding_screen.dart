import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  int step = 0;
  String level = 'Ik begin net', instrument = 'Akoestische gitaar';
  bool saving = false;
  String? error;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(32),
            shrinkWrap: true,
            children: [
              Icon(
                Icons.music_note_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                [
                  'Welkom bij GitaarGo!',
                  'Waar begin jij?',
                  'Jouw instrument',
                  'Speel. Leer. Groei.',
                ][step],
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              if (step == 0)
                const Text(
                  'Maak ruimte voor muziek. Stem je gitaar, leer je eerste noten en speel originele oefeningen. Zonder account, ook offline.',
                ),
              if (step == 1)
                ...[
                  'Ik begin net',
                  'Ik speel al een beetje',
                  'Ik speel regelmatig',
                ].map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: () => setState(() => level = s),
                      child: Text('${level == s ? '✓ ' : ''}$s'),
                    ),
                  ),
                ),
              if (step == 2)
                ...['Akoestische gitaar', 'Elektrische gitaar'].map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: () => setState(() => instrument = s),
                      child: Text('${instrument == s ? '✓ ' : ''}$s'),
                    ),
                  ),
                ),
              if (step == 3)
                const Text(
                  'Begin bij Stemmen en speel daarna een losse snaar. We vragen pas microfoontoegang als je op Luisteren drukt. Je audio blijft op je telefoon en wordt niet bewaard.',
                ),
              const SizedBox(height: 32),
              Text('Stap ${step + 1} van 4'),
              const SizedBox(height: 12),
              if (error != null) Text(error!),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (step < 3) {
                          setState(() => step++);
                          return;
                        }
                        setState(() => saving = true);
                        try {
                          final db = ref.read(databaseProvider);
                          await db.setting('level', level);
                          await db.setting('instrument', instrument);
                          await db.setting('onboarded', true);
                          ref.invalidate(settingsProvider);
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              error = 'Opslaan mislukt: $e';
                              saving = false;
                            });
                          }
                        }
                      },
                child: Text(step < 3 ? 'Verder' : 'Begin met spelen'),
              ),
              if (step > 0)
                TextButton(
                  onPressed: saving ? null : () => setState(() => step--),
                  child: const Text('Terug'),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
