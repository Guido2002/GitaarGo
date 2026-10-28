import 'package:flutter/material.dart';

import '../music/music.dart';

class ChordDiagram extends StatelessWidget {
  final GuitarChord chord;
  final bool leftHanded;
  const ChordDiagram({required this.chord, this.leftHanded = false, super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${chord.name}. Van lage E naar hoge e: ${chord.frets.map((f) => f < 0
            ? 'gedempt'
            : f == 0
            ? 'open'
            : 'fret $f').join(', ')}',
    child: SizedBox(
      height: 200,
      width: 200,
      child: CustomPaint(
        painter: _ChordPainter(
          chord,
          leftHanded,
          Theme.of(context).colorScheme,
        ),
      ),
    ),
  );
}

class _ChordPainter extends CustomPainter {
  final GuitarChord chord;
  final bool left;
  final ColorScheme colors;
  _ChordPainter(this.chord, this.left, this.colors);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    double x(int i) => w * .15 + (left ? 5 - i : i) * w * .14;
    final top = h * .22, step = h * .16;
    final line = Paint()
      ..color = colors.onSurface.withValues(alpha: .4)
      ..strokeWidth = 1;
    for (var i = 0; i < 6; i++) {
      canvas.drawLine(Offset(x(i), top), Offset(x(i), top + 4 * step), line);
    }
    for (var f = 0; f <= 4; f++) {
      line.strokeWidth = f == 0 ? 4 : 1;
      canvas.drawLine(
        Offset(w * .15, top + f * step),
        Offset(w * .85, top + f * step),
        line,
      );
    }
    if (chord.barre > 0) {
      canvas.drawLine(
        Offset(x(0), top + (chord.barre - .5) * step),
        Offset(x(5), top + (chord.barre - .5) * step),
        Paint()
          ..color = colors.primary
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var i = 0; i < 6; i++) {
      final f = chord.frets[i];
      if (f > 0) {
        canvas.drawCircle(
          Offset(x(i), top + (f - .5) * step),
          11,
          Paint()..color = colors.primary,
        );
      }
      if (f <= 0) {
        final center = Offset(x(i), top - 18);
        final mark = Paint()
          ..color = colors.onSurface
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke;
        if (f == 0) {
          canvas.drawCircle(center, 5, mark);
        } else {
          canvas.drawLine(
            center + const Offset(-4, -4),
            center + const Offset(4, 4),
            mark,
          );
          canvas.drawLine(
            center + const Offset(-4, 4),
            center + const Offset(4, -4),
            mark,
          );
        }
        continue;
      }
      final text = TextPainter(
        text: TextSpan(
          text: f < 0
              ? '×'
              : f == 0
              ? '○'
              : '${chord.fingers[i]}',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: f <= 0 ? 20 : 12,
            color: f <= 0 ? colors.onSurface : colors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        Offset(
          x(i) - text.width / 2,
          (f <= 0 ? top - 29 : top + (f - .5) * step - text.height / 2),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChordPainter old) =>
      old.chord != chord || old.left != left || old.colors != colors;
}
