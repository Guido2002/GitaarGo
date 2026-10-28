import '../update/update_controller.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/state.dart';
import '../../core/database/app_database.dart';
import '../../core/music/music.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../core/widgets/page_layout.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(resultsProvider);
    final chord = dailyChord(ref.watch(nowProvider));
    final settings = ref.watch(settingsProvider).asData?.value ?? {};
    return PageLayout(
      eyebrow: 'GitaarGo • Speel. Leer. Groei.',
      title: 'Jouw dagelijkse dosis gitaar.',
      children: [
        if (ref.watch(updateControllerProvider).release != null)
          InfoCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.system_update),
              title: Text(
                'Update ${ref.watch(updateControllerProvider).release!.version} beschikbaar',
              ),
              subtitle: const Text('Download en installeer via Profiel'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => context.go('/profiel'),
            ),
          ),
        results.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Voortgang laden mislukt: $e'),
          data: (r) {
            final xp = r.fold(0, (sum, item) => sum + item.xp);
            final today = r
                .where((s) => s.day == localDay(ref.watch(nowProvider)))
                .fold(0, (sum, s) => sum + s.hits);
            return Column(
              children: [
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${1 + xp ~/ 250}   •   $xp XP   •   ${practiceStreak(r, ref.watch(nowProvider))} dagen reeks',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: (xp % 250) / 250),
                      const SizedBox(height: 8),
                      Text('${250 - xp % 250} XP tot je volgende level'),
                    ],
                  ),
                ),
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DAGELIJKSE UITDAGING'),
                      const SizedBox(height: 8),
                      Text(
                        'Speel 10 correcte noten',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: (today / 10).clamp(0, 1)),
                      Text(
                        '${today.clamp(0, 10)} / 10 • 100 XP bij voltooiing',
                      ),
                      TextButton(
                        onPressed: () => context.push('/oefenen'),
                        child: const Text('Ga oefenen →'),
                      ),
                    ],
                  ),
                ),
                if (r.isNotEmpty)
                  ListTile(
                    title: const Text('Verder oefenen'),
                    subtitle: Text(r.first.exercise),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => context.go('/spelen'),
                  ),
              ],
            );
          },
        ),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AKKOORD VAN DE DAG',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                chord.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Center(
                child: ChordDiagram(
                  chord: chord,
                  leftHanded: settings['leftHanded'] == true,
                ),
              ),
              const Text(
                'Bekijk de vingerzetting en speel elke snaar rustig los. ○ = open · × = gedempt.',
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.go('/leren'),
                child: const Text('Ontdek de akkoorden'),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => context.go('/stemmen'),
          icon: const Icon(Icons.graphic_eq),
          label: const Text('Stem je gitaar'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/oefenen'),
          icon: const Icon(Icons.hearing),
          label: const Text('Oefen je eerste noten'),
        ),
      ],
    );
  }
}
