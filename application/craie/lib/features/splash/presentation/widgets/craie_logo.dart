import 'package:flutter/material.dart';

/// Three slanted rounded strokes.
class CraieLogo extends StatelessWidget {
  const CraieLogo({super.key});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(72, 76), painter: _LogoPainter());
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF2F2F2)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    const strokes = [
      [Offset(6, 40), Offset(31, 8)],
      [Offset(15, 62), Offset(43, 30)],
      [Offset(39, 66), Offset(66, 34)],
    ];
    for (final s in strokes) {
      canvas.drawLine(s[0], s[1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
