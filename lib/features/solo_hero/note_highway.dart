import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/scoring/score_engine.dart';

class NoteHighway extends FlameGame {
  final ScoreEngine score;
  final double Function() timeline;
  NoteHighway(this.score, this.timeline);
  @override
  Future<void> onLoad() async {
    pauseEngine();
  }

  @override
  Color backgroundColor() => const Color(0xFF14151D);
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x, h = size.y, hit = h * .8;
    final line = Paint()
      ..color = const Color(0xFF414354)
      ..strokeWidth = 1;
    for (var i = 0; i < 6; i++) {
      final x = (i + .5) * w / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, h), line);
      _text(canvas, '${i + 1}', Offset(x - 5, h - 24), const Color(0xFFA3A6B5));
    }
    canvas.drawLine(
      Offset(0, hit),
      Offset(w, hit),
      Paint()
        ..color = const Color(0xFF36D6BC)
        ..strokeWidth = 3,
    );
    final now = timeline();
    for (var i = 0; i < score.exercise.notes.length; i++) {
      if (score.judged.containsKey(i)) continue;
      final n = score.exercise.notes[i];
      final delta = score.exercise.timeAt(n) - now;
      final y = hit - delta * (hit / 3);
      if (y < -24 || y > h) continue;
      final x = (n.string - .5) * w / 6;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: w / 6 - 12, height: 36),
          const Radius.circular(12),
        ),
        Paint()..color = const Color(0xFF9370FF),
      );
      _text(canvas, '${n.fret}', Offset(x - 5, y - 10), Colors.white);
    }
  }

  void _text(Canvas canvas, String text, Offset at, Color color) {
    final p = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(canvas, at);
  }
}
