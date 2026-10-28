import '../update/update_panel.dart';

import 'dart:convert';

import 'package:package_info_plus/package_info_plus.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state.dart';
import '../../core/database/app_database.dart';
import '../../core/music/music.dart';
import '../../core/widgets/page_layout.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider).asData?.value ?? {};
    Future<void> save(String key, Object value) async {
      try {
        await updateSetting(ref, key, value);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Instelling opslaan mislukt: $e')),
          );
        }
      }
    }

    return PageLayout(
      eyebrow: 'Elke noot telt',
      title: 'Jouw groei.',
      children: [
        const UpdatePanel(),
        ref
            .watch(resultsProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Statistieken laden mislukt: $e'),
              data: (r) {
                final hits = r.fold(0, (v, r) => v + r.hits),
                    total = r.fold(0, (v, r) => v + r.total),
                    seconds = r.fold(0, (v, r) => v + r.seconds),
                    xp = r.fold(0, (v, r) => v + r.xp);
                final maxCombo = r.fold(
                  0,
                  (v, r) => r.maxCombo > v ? r.maxCombo : v,
                );
                final days = r
                    .where((r) => r.hits > 0)
                    .map((r) => r.day)
                    .toSet()
                    .length;
                final now = ref.watch(nowProvider);
                final week = List.generate(7, (i) {
                  final d = DateTime(now.year, now.month, now.day - 6 + i);
                  return r
                      .where((r) => r.day == localDay(d))
                      .fold(0, (v, r) => v + r.xp);
                });
                final maxXp = week.fold(1, (v, x) => x > v ? x : v);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level ${1 + xp ~/ 250} · $xp XP',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${seconds ~/ 60} minuten • $days oefendagen • ${practiceStreak(r, now)} dagen reeks',
                          ),
                          Text(
                            '$hits correcte noten • hoogste combo $maxCombo',
                          ),
                          Text(
                            'Nauwkeurigheid: ${total == 0 ? 'Nog geen resultaten' : '${(100 * hits / total).round()}%'}',
                          ),
                          const SizedBox(height: 24),
                          const Text('XP in de afgelopen 7 dagen'),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 110,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(
                                7,
                                (i) => Expanded(
                                  child: Tooltip(
                                    message:
                                        '${localDay(DateTime(now.year, now.month, now.day - 6 + i))}: ${week[i]} XP',
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text('${week[i]}'),
                                        Container(
                                          height: week[i] / maxXp * 65 + 2,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          [
                                            'ma',
                                            'di',
                                            'wo',
                                            'do',
                                            'vr',
                                            'za',
                                            'zo',
                                          ][DateTime(
                                                now.year,
                                                now.month,
                                                now.day - 6 + i,
                                              ).weekday -
                                              1],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mijlpalen',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text('${hits > 0 ? '✓' : '○'} Eerste correcte noot'),
                          Text(
                            '${r.any((r) => r.exercise.startsWith('Solo Hero') && r.hits > 0) ? '✓' : '○'} Eerste solo',
                          ),
                          Text('${hits >= 100 ? '✓' : '○'} 100 correcte noten'),
                          Text(
                            '${practiceStreak(r, now) >= 5 ? '✓' : '○'} Vijf dagen oefenen',
                          ),
                        ],
                      ),
                    ),
                    if (r.isEmpty)
                      const InfoCard(
                        child: Text(
                          'Je begint met een schone lei. Na je eerste oefening verschijnt je voortgang hier.',
                        ),
                      ),
                    ...r
                        .take(5)
                        .map(
                          (r) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(r.exercise),
                            subtitle: Text(
                              '${r.day} · ${r.hits}/${r.total} correct',
                            ),
                            trailing: Text('${r.score} pt'),
                          ),
                        ),
                  ],
                );
              },
            ),
        const SizedBox(height: 24),
        Text('Instellingen', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        InfoCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Donkere weergave'),
                value: s['theme'] != 'light',
                onChanged: (v) => save('theme', v ? 'dark' : 'light'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Linkshandige diagrammen'),
                value: s['leftHanded'] == true,
                onChanged: (v) => save('leftHanded', v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Haptische feedback'),
                value: s['haptics'] != false,
                onChanged: (v) => save('haptics', v),
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: s['tuning'] as String? ?? 'Standaard',
                decoration: const InputDecoration(
                  labelText: 'Standaardstemming',
                ),
                items: tunings.keys
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) save('tuning', v);
                },
              ),
              const SizedBox(height: 20),
              Text(
                'A4-referentie: ${(s['reference'] as num? ?? 440).round()} Hz',
              ),
              Slider(
                value: (s['reference'] as num? ?? 440).toDouble(),
                min: 430,
                max: 450,
                divisions: 20,
                label: '${s['reference'] ?? 440} Hz',
                onChanged: (v) => save('reference', v),
              ),
              Text(
                'Ruisdrempel: ${((s['gate'] as num? ?? .008) * 100).toStringAsFixed(1)}%',
              ),
              Slider(
                value: (s['gate'] as num? ?? .008).toDouble(),
                min: .002,
                max: .03,
                divisions: 28,
                onChanged: (v) => save('gate', v),
              ),
              Text(
                'Geschatte timingcompensatie: ${(s['latencyMs'] as num? ?? 0).round()} ms',
              ),
              Slider(
                value: (s['latencyMs'] as num? ?? 0).toDouble(),
                min: -200,
                max: 400,
                divisions: 60,
                onChanged: (v) => save('latencyMs', v),
              ),
              const Text(
                'Positief = de noot wordt later ontvangen dan gespeeld. Stel dit af door op de hitlijn te spelen. Dit is een handmatige schatting; hardwarelatency wordt nog niet gemeten.',
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            try {
              final db = ref.read(databaseProvider);
              final data = {
                'version': 1,
                'settings': await db.settings(),
                'sessions': (await db.results())
                    .map((r) => r.toJson())
                    .toList(),
              };
              await Clipboard.setData(
                ClipboardData(
                  text: const JsonEncoder.withIndent('  ').convert(data),
                ),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'JSON-export naar klembord gekopieerd. Plak deze in een bestand om te bewaren.',
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Export mislukt: $e')));
              }
            }
          },
          icon: const Icon(Icons.copy),
          label: const Text('Exporteer gegevens als JSON'),
        ),
        TextButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Oefenstatistieken wissen?'),
                content: const Text(
                  'Alle sessies, XP en voortgang worden van deze telefoon verwijderd.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuleren'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Wissen'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              try {
                await ref.read(databaseProvider).clearResults();
                ref.invalidate(resultsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Wissen mislukt: $e')));
                }
              }
            }
          },
          child: const Text('Wis oefenstatistieken'),
        ),
        TextButton(
          onPressed: () async {
            final info = await PackageInfo.fromPlatform();
            if (context.mounted) {
              showLicensePage(
                context: context,
                applicationName: 'GitaarGo',
                applicationVersion: info.version,
              );
            }
          },
          child: const Text('Open-sourcelicenties'),
        ),
        const InfoCard(
          child: Text(
            'Privacy\n\nGitaarGo analyseert microfoonaudio lokaal. Audio wordt niet opgeslagen of verstuurd. Updatecontroles maken verbinding met GitHub en delen geen oefengegevens. Oefenresultaten en instellingen blijven op dit apparaat. De microfoon stopt als je het scherm verlaat of de app naar de achtergrond gaat. Geen account, advertenties of analytics.',
          ),
        ),
      ],
    );
  }
}
