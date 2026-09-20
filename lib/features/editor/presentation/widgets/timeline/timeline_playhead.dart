import 'package:flutter/material.dart';

class TimelinePlayhead extends StatelessWidget {
  final double width;
  final double left;

  const TimelinePlayhead({
    super.key,
    required this.width,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      child: Container(
        width: width,
        color: Colors.white,
      ),
    );
  }
}