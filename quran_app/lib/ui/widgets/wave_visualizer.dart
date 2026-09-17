import 'dart:math';
import 'package:flutter/material.dart';

/// Lightweight animated "wave" shown while audio plays.
/// Pure-Canvas, no extra dependency (avoids waveform extraction cost).
class WaveVisualizer extends StatefulWidget {
  final bool playing;
  const WaveVisualizer({super.key, required this.playing});

  @override
  State<WaveVisualizer> createState() => _WaveState();
}

class _WaveState extends State<WaveVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    if (!widget.playing) _c.stop();
  }

  @override
  void didUpdateWidget(covariant WaveVisualizer old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.playing && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 56,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _WavePainter(_c.value, color, widget.playing),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double t;
  final Color color;
  final bool playing;
  _WavePainter(this.t, this.color, this.playing);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const bars = 28;
    for (var i = 0; i < bars; i++) {
      final p = i / bars;
      final amp = playing
          ? (sin((p * 6.28 * 2) + t * 6.28) * 0.5 + 0.5) * size.height * 0.42 + 4
          : 4.0;
      final x = p * size.width;
      canvas.drawLine(Offset(x, size.height / 2 - amp),
          Offset(x, size.height / 2 + amp), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.t != t;
}
