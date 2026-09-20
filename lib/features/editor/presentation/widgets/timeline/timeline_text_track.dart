import 'package:flutter/material.dart';

class TimelineTextTrack extends StatelessWidget {
  final Duration duration;

  const TimelineTextTrack({
    super.key,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final width = duration.inMilliseconds > 0
        ? (duration.inMilliseconds / 1000).clamp(80.0, 1000.0).toDouble()
        : 80.0;

    return SizedBox(
      height: 44,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: width,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Texto',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}