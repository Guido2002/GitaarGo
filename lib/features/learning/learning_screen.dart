import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/state.dart';
import '../../core/music/music.dart';
import '../../core/scoring/score_engine.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../core/widgets/page_layout.dart';

final exercisesProvider = FutureProvider<List<Exercise>>(
  (ref) async => (jsonDecode(
    await rootBundle.loadString('assets/exercises/library.json'),
  ) as List).map((j) => Exercise.fromJson(j)).toList(),
);

class LearningScreen extends ConsumerWidget {
  const LearningScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PageLayout(
    eyebrow: 'Kleine stappen, meer muziek',
    title: 'Bouw je basis.',
    children: [
      InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Je eerste noot',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Speel de lage E-snaar zonder een fret in te drukken. Laat de andere snaren stil. De microfoon controleert de toonhoogte; de afgebeelde snaar is een vingerzettingsadvies.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/oefenen'),
              child: const Text('Start nootoefening'),
            ),
          ],
        ),
      ),
      InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A mineur pentatonisch',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text('A · C · D · E · G. Vijf noten voor je eerste solo.'),
            TextButton(
              onPressed: () => context.push('/oefenen?id=pentatonic'),
              child: const Text('Oefen de toonladder →'),
            ),
          ],
        ),
      ),
      Text(
        'Akkoordbibliotheek',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 16),
      const Text(
        'Diagramstudie: herkenning van volledig aangeslagen akkoorden is nog niet beschikbaar. Er worden hiervoor geen scores toegekend.',
      ),
      const SizedBox(height: 16),
      ...chords.map(
        (chord) => InfoCard(
          child: Column(
            children: [
              Text(chord.name, style: Theme.of(context).textTheme.titleLarge),
              ChordDiagram(
                chord: chord,
                leftHanded:
                    ref.watch(settingsProvider).asData?.value['leftHanded'] ==
                    true,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class PlayLibraryScreen extends ConsumerWidget {
  const PlayLibraryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PageLayout(
    eyebrow: 'Jouw gitaar is de controller',
    title: 'Solo Hero',
    children: [
      const InfoCard(
        child: Text(
          'Volg de noten naar de hitlijn. Speel de juiste toon op tijd. De microfoon meet toonhoogte en timing; snaar en fret zijn suggesties. Iedere oefening is origineel en vrij te gebruiken.',
        ),
      ),
      ref
          .watch(exercisesProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Oefeningen laden mislukt: $e'),
            data: (exercises) => Column(
              children: exercises
                  .map(
                    (e) => InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text('${e.bpm} BPM • ${e.notes.length} noten'),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () =>
                                context.push('/oefenen?id=${e.id}&game=1'),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Speel Solo Hero'),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.push('/oefenen?id=${e.id}'),
                            child: const Text('Rustig oefenen'),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
    ],
  );
}
