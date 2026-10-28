// Deterministic vector artwork, rendered with Flutter itself. No runtime dependency.
// Run: flutter test tool/generate_icons.dart
// Then: python3 tool/package_ios_icons.py (Pillow, removes the PNG alpha channel).
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const background = 0xFF101116;
final shapes = <(int, List<List<num>>)>[
  (
    0xFF9370FF,
    [
      [0, 54, 23],
      [2, 72, 23, 84, 27, 83, 39],
      [2, 82, 54, 68, 76, 57, 85],
      [2, 55, 87, 53, 87, 51, 85],
      [2, 40, 76, 25, 54, 25, 39],
      [2, 24, 27, 36, 23, 54, 23],
      [3],
    ],
  ),
  // An asymmetric inset catches the light without a gradient.
  (
    0xFFB89DFF,
    [
      [0, 31, 37],
      [2, 32, 29, 43, 27, 57, 27],
      [2, 44, 29, 36, 33, 34, 41],
      [2, 33, 45, 34, 50, 35, 54],
      [2, 31, 48, 30, 41, 31, 37],
      [3],
    ],
  ),
  // Guitar silhouette, angled forward in the generated artwork.
  (
    0xFFFFFFFF,
    [
      [0, 50, 47],
      [1, 50, 38],
      [1, 48, 36],
      [1, 48, 29],
      [2, 51, 27, 57, 27, 60, 29],
      [1, 60, 36],
      [1, 58, 38],
      [1, 58, 47],
      [2, 64, 43, 70, 47, 68, 53],
      [2, 67, 57, 66, 57, 69, 62],
      [2, 75, 75, 33, 75, 39, 62],
      [2, 42, 57, 41, 57, 40, 53],
      [2, 38, 47, 44, 43, 50, 47],
      [3],
    ],
  ),
  (
    0xFF101116,
    [
      [0, 59, 56],
      [2, 59, 62.6, 49, 62.6, 49, 56],
      [2, 49, 49.4, 59, 49.4, 59, 56],
      [3],
    ],
  ),
  (
    0xFF36D6BC,
    [
      [0, 52.3, 52.6],
      [1, 57.4, 56],
      [1, 52.3, 59.4],
      [3],
    ],
  ),
  (
    0xFF101116,
    [
      [0, 48, 65],
      [1, 60, 65],
      [1, 60, 67],
      [1, 48, 67],
      [3],
    ],
  ),
  (
    0xFF9370FF,
    [
      [0, 52, 32],
      [1, 56, 32],
      [1, 56, 33.3],
      [1, 52, 33.3],
      [3],
    ],
  ),
];
String color(int c) =>
    '#${(c & 0xffffff).toRadixString(16).padLeft(6, '0').toUpperCase()}';
String pathData(List<List<num>> commands) => commands
    .map(
      (c) => '${['M', 'L', 'C', 'Z'][c.first.toInt()]}${c.skip(1).join(' ')}',
    )
    .join(' ');
ui.Path path(List<List<num>> commands) {
  final p = ui.Path();
  for (final c in commands) {
    final n = c.skip(1).map((n) => n.toDouble()).toList();
    switch (c.first.toInt()) {
      case 0:
        p.moveTo(n[0], n[1]);
      case 1:
        p.lineTo(n[0], n[1]);
      case 2:
        p.cubicTo(n[0], n[1], n[2], n[3], n[4], n[5]);
      case 3:
        p.close();
    }
  }
  return p;
}

bool isGuitar(int i) => i >= 2;
const rotation = .30;
Future<void> render(
  String destination,
  int size, {
  bool rounded = false,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.scale(size / 108);
  if (rounded) {
    canvas.clipRRect(
      ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(0, 0, 108, 108),
        const ui.Radius.circular(24),
      ),
    );
  }
  canvas.drawPaint(ui.Paint()..color = const ui.Color(background));
  for (var i = 0; i < shapes.length; i++) {
    canvas.save();
    if (isGuitar(i)) {
      canvas.translate(54, 52);
      canvas.rotate(rotation);
      canvas.translate(-54, -52);
    }
    canvas.drawPath(
      path(shapes[i].$2),
      ui.Paint()..color = ui.Color(shapes[i].$1),
    );
    canvas.restore();
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(destination);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(png!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Render and package launcher artwork', () async {
    await render('assets/branding/gitaargo-icon.png', 1024);
    final svg = StringBuffer(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108"><rect width="108" height="108" fill="${color(background)}"/>',
    );
    final android = StringBuffer(
      '<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">',
    );
    final mono = StringBuffer(
      '<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">',
    );
    for (var i = 0; i < shapes.length; i++) {
      final d = pathData(shapes[i].$2), fill = color(shapes[i].$1);
      if (isGuitar(i)) {
        svg.write(
          '<g transform="rotate(${rotation * 180 / 3.141592653589793} 54 52)">',
        );
        android.write(
          '<group android:pivotX="54" android:pivotY="52" android:rotation="${rotation * 180 / 3.141592653589793}">',
        );
      }
      svg.write('<path fill="$fill" d="$d"/>');
      android.write('<path android:fillColor="$fill" android:pathData="$d"/>');
      if (i == 0) {
        mono.write('<path android:fillColor="#FFFFFF" android:pathData="$d"/>');
      }
      if (isGuitar(i)) {
        svg.write('</g>');
        android.write('</group>');
      }
    }
    svg.write('</svg>');
    android.write('</vector>');
    mono.write('</vector>');
    await File('assets/branding/gitaargo-icon.svg')
        .writeAsString(svg.toString());
    final drawables = Directory('android/app/src/main/res/drawable');
    await drawables.create(recursive: true);
    await File('${drawables.path}/ic_launcher_foreground.xml')
        .writeAsString(android.toString());
    await File('${drawables.path}/ic_launcher_monochrome.xml')
        .writeAsString(mono.toString());
    for (final entry in {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    }.entries) {
      await render(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
        entry.value,
        rounded: true,
      );
    }
    final icons = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
    final data = jsonDecode(
      await File('${icons.path}/Contents.json').readAsString(),
    ) as Map<String, dynamic>;
    final sizes = <String, int>{};
    for (final icon in data['images'] as List) {
      final point = double.parse((icon['size'] as String).split('x').first);
      final scale = double.parse((icon['scale'] as String).replaceAll('x', ''));
      sizes[icon['filename'] as String] = (point * scale).round();
    }
    for (final icon in sizes.entries) {
      await render('${icons.path}/${icon.key}', icon.value);
    }
  });
}
