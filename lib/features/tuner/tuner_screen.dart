import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state.dart';
import '../../core/audio/audio_session.dart';
import '../../core/music/music.dart';
import '../../core/widgets/page_layout.dart';

class TunerScreen extends ConsumerStatefulWidget {
  const TunerScreen({super.key});
  @override
  ConsumerState<TunerScreen> createState() => _TunerState();
}

class _TunerState extends ConsumerState<TunerScreen> {
  late final audio = AudioSession(input: ref.read(audioInputProvider));
  int? manual, detectedMidi;
  double? smooth;
  double last = 0;
  @override
  void initState() {
    super.initState();
    audio.addListener(_changed);
    audio.onFrame = (f) {
      if (f.frequency == null) {
        if (f.seconds - last > .3) {
          smooth = null;
          detectedMidi = null;
        }
        return;
      }
      last = f.seconds;
      final note = midiFor(f.frequency!, reference).round();
      if (detectedMidi != note) {
        smooth = f.frequency;
        detectedMidi = note;
      } else {
        smooth = (smooth ?? f.frequency!) * .65 + f.frequency! * .35;
      }
    };
  }

  double get reference =>
      (ref.read(settingsProvider).asData?.value['reference'] as num?)
          ?.toDouble() ??
      440;
  void _changed() {
    if (!audio.active) {
      smooth = null;
      detectedMidi = null;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    audio.removeListener(_changed);
    audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider).asData?.value ?? {};
    final tuning = s['tuning'] as String? ?? 'Standaard';
    final strings = tunings[tuning]!;
    var target = strings.first;
    if (smooth != null) {
      target = strings.reduce(
        (a, b) =>
            (midiFor(smooth!, reference) - a).abs() <
                (midiFor(smooth!, reference) - b).abs()
            ? a
            : b,
      );
    }
    if (manual != null) target = strings[manual!];
    final cents = smooth == null ? 0.0 : centsFor(smooth!, target, reference);
    final tuned = smooth != null && cents.abs() < 5;
    return PageLayout(
      eyebrow: 'Luister. Draai. Stem.',
      title: 'Een goede start klinkt zuiver.',
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: tuning,
          decoration: const InputDecoration(labelText: 'Stemming'),
          items: tunings.keys
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: audio.active
              ? null
              : (v) async {
                  if (v == null) return;
                  try {
                    await updateSetting(ref, 'tuning', v);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Stemming opslaan mislukt: $e')),
                      );
                    }
                  }
                },
        ),
        const SizedBox(height: 20),
        InfoCard(
          child: Column(
            children: [
              Text(
                audio.active ? '● Microfoon actief · lokaal' : 'Microfoon uit',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                smooth == null ? '—' : noteName(detectedMidi!),
                style: Theme.of(context).textTheme.displayLarge
                    ?.copyWith(fontSize: 80, fontWeight: FontWeight.bold),
              ),
              Text(
                smooth == null
                    ? 'Speel één snaar en laat die klinken'
                    : '${smooth!.toStringAsFixed(2)} Hz • doel ${noteName(target)}',
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 64,
                child: LayoutBuilder(
                  builder: (context, c) => Stack(
                    children: [
                      Positioned(
                        top: 30,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 3,
                          height: 48,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      if (smooth != null)
                        AnimatedAlign(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 100),
                          alignment: Alignment((cents / 50).clamp(-1, 1), 0),
                          child: Icon(
                            Icons.arrow_drop_down,
                            size: 48,
                            color: tuned
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('Te laag')),
                  Expanded(child: Text('Zuiver', textAlign: TextAlign.center)),
                  Expanded(child: Text('Te hoog', textAlign: TextAlign.right)),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                smooth == null
                    ? 'Wacht op een duidelijke toon'
                    : tuned
                    ? 'Goed gestemd ✓'
                    : '${cents > 0 ? '+' : ''}${cents.toStringAsFixed(1)} cents • ${cents < 0 ? 'span de snaar' : 'ontspan de snaar'}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Automatisch'),
              selected: manual == null,
              onSelected: (_) => setState(() => manual = null),
            ),
            ...List.generate(
              6,
              (i) => ChoiceChip(
                label: Text('${i + 1} · ${noteName(strings[i])}'),
                selected: manual == i,
                onSelected: (_) => setState(() => manual = i),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (audio.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              audio.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        FilledButton.icon(
          onPressed: audio.starting
              ? null
              : () async {
                  if (audio.active) {
                    await audio.stop();
                  } else {
                    await audio.start((s['gate'] as num?)?.toDouble() ?? .008);
                  }
                },
          icon: Icon(audio.active ? Icons.stop : Icons.mic),
          label: Text(
            audio.starting
                ? 'Microfoon starten…'
                : audio.active
                ? 'Stop luisteren'
                : 'Luisteren',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'A4 = ${reference.toStringAsFixed(0)} Hz. Snaren: 1 = hoge e, 6 = lage E. Speel in een rustige omgeving.',
        ),
      ],
    );
  }
}
