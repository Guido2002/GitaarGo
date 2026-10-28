class TargetNote {
  final int midi, string, fret;
  final double beat, duration;
  const TargetNote(
    this.midi,
    this.beat,
    this.string,
    this.fret, {
    this.duration = 1,
  });
  factory TargetNote.fromJson(Map<String, dynamic> j) => TargetNote(
    j['midiNote'] as int,
    (j['startBeat'] as num).toDouble(),
    j['suggestedString'] as int,
    j['suggestedFret'] as int,
    duration: (j['durationBeats'] as num).toDouble(),
  );
}

class Exercise {
  final String id, title;
  final int bpm;
  final List<TargetNote> notes;
  const Exercise(this.id, this.title, this.bpm, this.notes);
  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    j['id'] as String,
    j['title'] as String,
    j['bpm'] as int,
    (j['notes'] as List)
        .map((n) => TargetNote.fromJson(n as Map<String, dynamic>))
        .toList(),
  );
  double timeAt(TargetNote note) => 2 + note.beat * 60 / bpm;
  double get duration =>
      timeAt(notes.last) + notes.last.duration * 60 / bpm + .5;
}

enum Judgment { perfect, great, good, missed }

extension JudgmentLabel on Judgment {
  String get label => ['PERFECT!', 'GEWELDIG!', 'GOED!', 'GEMIST!'][index];
}

class ScoreEngine {
  final Exercise exercise;
  final double latencySeconds;
  final double perfectWindow, greatWindow, goodWindow;
  final Map<int, Judgment> judged = {};
  int score = 0, combo = 0, maxCombo = 0;
  ScoreEngine(
    this.exercise, {
    this.latencySeconds = 0,
    this.perfectWindow = .050,
    this.greatWindow = .100,
    this.goodWindow = .160,
  });
  int get multiplier => combo >= 50
      ? 4
      : combo >= 25
      ? 3
      : combo >= 10
      ? 2
      : 1;
  int get hits => judged.values.where((v) => v != Judgment.missed).length;
  int get perfects => judged.values.where((v) => v == Judgment.perfect).length;
  double get accuracy => judged.isEmpty ? 0 : hits / judged.length;
  Judgment? input(int midi, double time, double confidence) {
    if (confidence < .85) return null;
    final adjusted = time - latencySeconds;
    expire(adjusted);
    for (var i = 0; i < exercise.notes.length; i++) {
      if (judged.containsKey(i)) continue;
      final note = exercise.notes[i];
      final delta = (adjusted - exercise.timeAt(note)).abs();
      if (delta > goodWindow + 1e-9) continue;
      // Wrong notes do not consume a target; it will expire if not corrected.
      if (midi != note.midi) return null;
      final judgment = delta <= perfectWindow + 1e-9
          ? Judgment.perfect
          : delta <= greatWindow + 1e-9
          ? Judgment.great
          : Judgment.good;
      judged[i] = judgment;
      combo++;
      if (combo > maxCombo) maxCombo = combo;
      score += [100, 75, 50][judgment.index] * multiplier;
      return judgment;
    }
    return null;
  }

  void expire(double time) {
    for (var i = 0; i < exercise.notes.length; i++) {
      if (!judged.containsKey(i) &&
          time - exercise.timeAt(exercise.notes[i]) > goodWindow + 1e-9) {
        judged[i] = Judgment.missed;
        combo = 0;
      }
    }
  }
}
