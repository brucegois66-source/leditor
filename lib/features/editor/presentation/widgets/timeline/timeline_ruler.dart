import 'package:flutter/material.dart';

class TimelineRuler extends StatelessWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration>? onSeek;

  const TimelineRuler({
    super.key,
    required this.duration,
    required this.position,
    this.onSeek,
  });

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            if (onSeek == null || duration <= Duration.zero) return;

            final ratio =
                (details.localPosition.dx / width).clamp(0.0, 1.0);
            onSeek!(duration * ratio);
          },
          child: CustomPaint(
            painter: _RulerPainter(
              duration: duration,
              position: position,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  _format(position),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RulerPainter extends CustomPainter {
  final Duration duration;
  final Duration position;

  const _RulerPainter({
    required this.duration,
    required this.position,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF53606B)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const steps = 5;
    final total = duration.inMilliseconds.toDouble();

    for (var index = 0; index <= steps; index++) {
      final x = size.width * index / steps;
      canvas.drawLine(
        Offset(x, size.height - 8),
        Offset(x, size.height),
        linePaint,
      );

      if (total > 0) {
        final value = duration * (index / steps);
        textPainter.text = TextSpan(
          text: _format(value),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, 2),
        );
      }
    }
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) {
    return oldDelegate.duration != duration ||
        oldDelegate.position != position;
  }
}