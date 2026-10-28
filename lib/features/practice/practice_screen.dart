import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state.dart';
import '../../core/audio/audio_input_service.dart';
import '../../core/audio/audio_session.dart';
import '../../core/database/app_database.dart';
import '../../core/music/music.dart';
import '../../core/scoring/score_engine.dart';
import '../learning/learning_screen.dart';
import '../solo_hero/note_highway.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  final String? exerciseId;
  final bool game;
  const PracticeScreen({super.key, this.exerciseId, this.game = false});
  @override
  ConsumerState<PracticeScreen> createState() => _PracticeState();
}

class _PracticeState extends ConsumerState<PracticeScreen> {
  late final audio = AudioSession(input: ref.read(audioInputProvider));
  final watch = Stopwatch();
  ScoreEngine? engine;
  NoteHighway? highway;
  Timer? ticker;
  Exercise? exercise;
  double origin = 0;
  int index = 0, attempts = 0, calmCombo = 0, maxCalmCombo = 0;
  String feedback = 'Stem je gitaar en start wanneer je klaar bent.';
  bool finishing = false, finished = false, saved = false;
  PracticeResult? result;
  String? saveError;
  final id = DateTime.now().microsecondsSinceEpoch.toString();
  @override
  void initState() {
    super.initState();
    audio.addListener(_change);
    audio.onFrame = _frame;
    audio.onStopped = () {
      watch.stop();
      highway?.pauseEngine();
    };
  }

  void _change() {
    if (mounted) setState(() {});
  }

  double get elapsed => watch.elapsedMicroseconds / 1e6;
  Future<void> _start() async {
    final s = ref.read(settingsProvider).asData?.value ?? {};
    await audio.start((s['gate'] as num?)?.toDouble() ?? .008);
    if (!mounted || !audio.active) return;
    origin = audio.input.seconds - elapsed;
    watch.start();
    highway?.resumeEngine();
    setState(
      () => feedback = widget.game
          ? 'Bereid je voor…'
          : 'Speel ${noteName(exercise!.notes[index].midi)}',
    );
    ticker ??= Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted || !watch.isRunning || finishing) return;
      if (widget.game) {
        if (elapsed > exercise!.duration + engine!.latencySeconds) {
          unawaited(_finish());
        }
      }
      if (mounted) setState(() {});
    });
  }

  void _frame(AudioFrame f) {
    // Expire against analyzed PCM time, not a UI tick ahead of in-flight DSP.
    if (widget.game && watch.isRunning && !finishing) {
      engine!.expire(f.seconds - origin - engine!.latencySeconds);
    }
    if (!watch.isRunning || finishing || !f.onset || f.frequency == null) {
      return;
    }
    final reference =
        (ref.read(settingsProvider).asData?.value['reference'] as num?)
            ?.toDouble() ??
        440;
    final midi = midiFor(f.frequency!, reference).round();
    if (widget.game) {
      final judgment = engine!.input(midi, f.seconds - origin, f.confidence);
      if (judgment != null) {
        feedback = judgment.label;
        _haptic();
      }
    } else {
      attempts++;
      if (midi == exercise!.notes[index].midi) {
        index++;
        calmCombo++;
        maxCalmCombo = max(maxCalmCombo, calmCombo);
        _haptic();
        feedback = 'Goed gespeeld! ${noteName(midi)} herkend.';
        if (index >= exercise!.notes.length) unawaited(_finish());
      } else {
        calmCombo = 0;
        feedback =
            'Je speelde ${noteName(midi)}. Probeer ${noteName(exercise!.notes[index].midi)}.';
      }
    }
  }

  void _haptic() {
    if (ref.read(settingsProvider).asData?.value['haptics'] != false) {
      unawaited(HapticFeedback.lightImpact());
    }
  }

  Future<void> _finish() async {
    if (finishing) return;
    finishing = true;
    watch.stop();
    ticker?.cancel();
    try {
      await audio.stop();
    } catch (e) {
      saveError = 'Microfoon stoppen mislukt: $e';
    }
    if (!mounted) return;
    if (widget.game) engine!.expire(double.infinity);
    final hits = widget.game ? engine!.hits : index;
    final total = widget.game ? exercise!.notes.length : max(attempts, index);
    final day = localDay(DateTime.now());
    final score = widget.game ? engine!.score : hits * 50;
    result = PracticeResult(
      id: id,
      exercise: '${widget.game ? 'Solo Hero' : 'Oefenen'} · ${exercise!.title}',
      day: day,
      score: score,
      hits: hits,
      total: total,
      perfects: widget.game ? engine!.perfects : 0,
      maxCombo: widget.game ? engine!.maxCombo : maxCalmCombo,
      seconds: watch.elapsed.inSeconds,
      xp: 0,
    );
    setState(() => finished = true);
    await _save();
  }

  Future<void> _save() async {
    try {
      result = await ref.read(databaseProvider).complete(result!);
      ref.invalidate(resultsProvider);
      if (mounted) {
        setState(() {
          saved = true;
          saveError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => saveError = 'Resultaat opslaan mislukt: $e');
    }
  }

  @override
  void dispose() {
    ticker?.cancel();
    audio.removeListener(_change);
    audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.game ? 'Solo Hero' : 'Rustig oefenen')),
      body: SafeArea(
        child: ref
            .watch(exercisesProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Oefening laden mislukt: $e')),
              data: (list) {
                exercise ??= list.firstWhere(
                  (e) => e.id == widget.exerciseId,
                  orElse: () => list.first,
                );
                engine ??= ScoreEngine(
                  exercise!,
                  latencySeconds:
                      ((ref.read(settingsProvider).asData?.value['latencyMs']
                                  as num?)
                              ?.toDouble() ??
                          0) /
                      1000,
                );
                highway ??= NoteHighway(engine!, () => elapsed);
                if (finished) {
                  final r = result!;
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Oefening afgerond',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${r.score} punten',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          Text(
                            '${r.hits} correct · ${r.total - r.hits} gemist / onjuist',
                          ),
                          Text(
                            '${r.total == 0 ? 0 : (r.hits / r.total * 100).round()}% nauwkeurigheid · combo ${r.maxCombo}',
                          ),
                          if (widget.game) Text('${r.perfects} perfecte noten'),
                          Text('+${r.xp} XP'),
                          const SizedBox(height: 24),
                          Text(
                            r.hits == 0
                                ? 'Geen correcte noten herkend. Controleer de microfoon en probeer eerst rustig losse snaren.'
                                : r.hits < r.total
                                ? 'Oefen deze noten eerst rustig en laat elke toon duidelijk klinken.'
                                : 'Mooi gespeeld. Probeer nu een volgende oefening.',
                          ),
                          const SizedBox(height: 16),
                          Text(saved ? 'Lokaal opgeslagen' : 'Opslaan…'),
                          if (saveError != null) Text(saveError!),
                          if (saveError != null)
                            TextButton(
                              onPressed: _save,
                              child: const Text('Probeer opslaan opnieuw'),
                            ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Terug naar overzicht'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final n =
                    exercise!.notes[index.clamp(0, exercise!.notes.length - 1)];
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              Text(
                                exercise!.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                widget.game
                                    ? '${exercise!.bpm} BPM • ${engine!.score} punten • ${engine!.combo} combo • ${engine!.multiplier}×'
                                    : '${min(index + 1, exercise!.notes.length)} / ${exercise!.notes.length} • Alleen toonhoogte, geen timingbeoordeling',
                              ),
                              LinearProgressIndicator(
                                value: widget.game
                                    ? (elapsed / exercise!.duration).clamp(0, 1)
                                    : index / exercise!.notes.length,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                audio.active
                                    ? '● Microfoon actief · lokaal'
                                    : 'Microfoon uit',
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: widget.game
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: GameWidget(game: highway!),
                                  ),
                                )
                              : Center(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        Text(
                                          noteName(n.midi),
                                          style: Theme.of(context)
                                              .textTheme
                                              .displayLarge
                                              ?.copyWith(fontSize: 80),
                                        ),
                                        Text(
                                          'Snaar ${n.string} · fret ${n.fret} (suggestie)',
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          audio.frame?.frequency == null
                                              ? 'Wacht op een duidelijke toon'
                                              : 'Gehoord: ${noteName(midiFor(audio.frame!.frequency!, (ref.read(settingsProvider).asData?.value['reference'] as num?)?.toDouble() ?? 440).round())}',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                feedback,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              if (audio.error != null) Text(audio.error!),
                              FilledButton.icon(
                                onPressed: audio.starting || finishing
                                    ? null
                                    : () async {
                                        if (audio.active) {
                                          await audio.stop();
                                          setState(
                                            () => feedback = 'Gepauzeerd. Je kunt verder spelen.',
                                          );
                                        } else {
                                          await _start();
                                        }
                                      },
                                icon: Icon(
                                  audio.active ? Icons.pause : Icons.mic,
                                ),
                                label: Text(
                                  audio.starting
                                      ? 'Starten…'
                                      : audio.active
                                      ? 'Pauzeren'
                                      : elapsed > 0
                                      ? 'Verder spelen'
                                      : 'Start met microfoon',
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Een aangehouden noot telt één keer. Sla elke noot opnieuw aan.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}
