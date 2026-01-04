import 'dart:math' as math;

import 'package:flutter/material.dart';

class CyberBackground extends StatefulWidget {
  const CyberBackground({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  State<CyberBackground> createState() => _CyberBackgroundState();
}

class _CyberBackgroundState extends State<CyberBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final shift = (t * 2 - 1) * 0.35;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1, -1),
              end: Alignment(1, 1),
              colors: [
                scheme.surface,
                Color.alphaBlend(
                    scheme.primary.withValues(alpha: 0.18), scheme.surface),
                Color.alphaBlend(
                    scheme.secondary.withValues(alpha: 0.14), scheme.surface),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: _GridGlowPainter(
              primary: scheme.primary,
              secondary: scheme.secondary,
              phase: t,
              shift: shift,
            ),
            child: SafeArea(
              child: Padding(
                padding: widget.padding,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridGlowPainter extends CustomPainter {
  _GridGlowPainter({
    required this.primary,
    required this.secondary,
    required this.phase,
    required this.shift,
  });

  final Color primary;
  final Color secondary;
  final double phase;
  final double shift;

  @override
  void paint(Canvas canvas, Size size) {
    final glow1 = Paint()
      ..color = primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final glow2 = Paint()
      ..color = secondary.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final cell = math.max(22.0, math.min(size.shortestSide / 14, 44.0));

    final xOff = shift * cell;
    final yOff = math.sin(phase * math.pi * 2) * (cell * 0.25);

    for (double x = -cell + xOff; x < size.width + cell; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), glow1);
    }

    for (double y = -cell + yOff; y < size.height + cell; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), glow2);
    }

    final blob = Paint()
      ..shader = RadialGradient(
        colors: [
          primary.withValues(alpha: 0.18),
          primary.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.8, size.height * 0.2),
          radius: size.shortestSide * 0.55,
        ),
      );

    canvas.drawRect(Offset.zero & size, blob);
  }

  @override
  bool shouldRepaint(covariant _GridGlowPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.shift != shift;
  }
}
