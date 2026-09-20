import 'package:flutter/material.dart';

enum TrimHandleSide { start, end }

class TrimHandles extends StatelessWidget {
  final double width;
  final double height;
  final ValueChanged<double> onStartDrag;
  final ValueChanged<double> onEndDrag;
  final ValueChanged<TrimHandleSide>? onDragStarted;
  final VoidCallback? onDragEnded;

  const TrimHandles({
    super.key,
    required this.width,
    required this.height,
    required this.onStartDrag,
    required this.onEndDrag,
    this.onDragStarted,
    this.onDragEnded,
  });

  static const double _hitWidth = 52;
  static const double _visualWidth = 16;

  @override
  Widget build(BuildContext context) {
    if (width <= 0 || height <= 0) return const SizedBox.shrink();

    final handleWidth = _hitWidth.clamp(0.0, width).toDouble();
    final endHandleLeft = (width - handleWidth).clamp(0.0, width).toDouble();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: 0,
          width: handleWidth,
          height: height,
          child: _TrimHandle(
            side: TrimHandleSide.start,
            onDragStarted: onDragStarted,
            onDragUpdate: (details) => onStartDrag(details.delta.dx),
            onDragEnded: onDragEnded,
          ),
        ),
        Positioned(
          left: endHandleLeft,
          top: 0,
          width: handleWidth,
          height: height,
          child: _TrimHandle(
            side: TrimHandleSide.end,
            onDragStarted: onDragStarted,
            onDragUpdate: (details) => onEndDrag(details.delta.dx),
            onDragEnded: onDragEnded,
          ),
        ),
      ],
    );
  }
}

class _TrimHandle extends StatelessWidget {
  final TrimHandleSide side;
  final ValueChanged<TrimHandleSide>? onDragStarted;
  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback? onDragEnded;

  const _TrimHandle({
    required this.side,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnded,
  });

  @override
  Widget build(BuildContext context) {
    final isStart = side == TrimHandleSide.start;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => onDragStarted?.call(side),
      onHorizontalDragUpdate: onDragUpdate,
      onHorizontalDragEnd: (_) => onDragEnded?.call(),
      onHorizontalDragCancel: () => onDragEnded?.call(),
      child: Align(
        alignment: isStart ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          width: TrimHandles._visualWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF4B8CFF),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isStart ? 7 : 2),
              bottomLeft: Radius.circular(isStart ? 7 : 2),
              topRight: Radius.circular(isStart ? 2 : 7),
              bottomRight: Radius.circular(isStart ? 2 : 7),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 3,
                offset: Offset(1, 0),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 3,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}