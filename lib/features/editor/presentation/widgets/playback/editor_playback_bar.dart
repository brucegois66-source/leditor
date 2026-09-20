import 'package:flutter/material.dart';

class EditorPlaybackBar extends StatelessWidget {
  final bool isReady;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback? onPrevious;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;

  const EditorPlaybackBar({
    super.key,
    required this.isReady,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
  });

  static const Color brand = Color(0xFF7B5CFF);
  static const Color dividerSoft = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;

    return Container(
      color: const Color(0xFF0E0E0E),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 88,
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${_format(position)} / ${_format(duration)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ControlButton(
                      icon: Icons.skip_previous_rounded,
                      onTap: isReady ? onPrevious : null,
                    ),
                    const SizedBox(width: 10),
                    _ControlButton(
                      icon: isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      onTap: isReady ? onPlayPause : null,
                      primary: true,
                    ),
                    const SizedBox(width: 10),
                    _ControlButton(
                      icon: Icons.skip_next_rounded,
                      onTap: isReady ? onNext : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 88),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 66,
              height: 3,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0).toDouble(),
                backgroundColor: dividerSoft,
                valueColor: const AlwaysStoppedAnimation<Color>(brand),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _format(Duration value) {
    final milliseconds = value.inMilliseconds;
    final minutes = (milliseconds ~/ 60000).toString().padLeft(2, '0');
    final seconds = ((milliseconds % 60000) ~/ 1000).toString().padLeft(2, '0');
    final tenths = ((milliseconds % 1000) ~/ 100).toString();
    return '$minutes:$seconds.$tenths';
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            icon,
            color: Colors.white,
            size: primary ? 30 : 24,
          ),
        ),
      ),
    );
  }
}