import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/audio/audio_input_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});
final settingsProvider = FutureProvider<Map<String, dynamic>>(
  (ref) => ref.watch(databaseProvider).settings(),
);
final resultsProvider = FutureProvider<List<PracticeResult>>(
  (ref) => ref.watch(databaseProvider).results(),
);
Future<void> updateSetting(WidgetRef ref, String key, Object value) async {
  await ref.read(databaseProvider).setting(key, value);
  ref.invalidate(settingsProvider);
}

final nowProvider = Provider<DateTime>((ref) {
  final timer = Timer(const Duration(minutes: 1), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return DateTime.now();
});

final audioInputProvider = Provider<AudioInputService>((ref) {
  final audio = AudioInputService();
  ref.onDispose(() => unawaited(audio.dispose()));
  return audio;
});
