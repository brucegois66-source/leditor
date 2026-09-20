import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'trim_handles.dart';

class TimelineVideoTrack extends StatefulWidget {
  final double timelineWidth;
  final double pixelsPerSecond;
  final double height;

  // Duração exibida: trimEnd - trimStart.
  final Duration projectDuration;

  // Limites atuais do trecho mantido no arquivo original.
  final Duration sourceTrimStart;
  final Duration sourceTrimEnd;

  // Duração física original do arquivo. É o limite máximo para restaurar
  // conteúdo com a alça direita.
  final Duration sourceDuration;

  final bool hasVideo;
  final List<Uint8List> thumbnails;
  final ValueChanged<Duration>? onSeekProjectTime;
  final VoidCallback? onImport;
  final ValueChanged<Duration> onTrimStartCommitted;
  final ValueChanged<Duration> onTrimEndCommitted;

  const TimelineVideoTrack({
    super.key,
    required this.timelineWidth,
    required this.pixelsPerSecond,
    required this.height,
    required this.projectDuration,
    required this.sourceTrimStart,
    required this.sourceTrimEnd,
    required this.sourceDuration,
    required this.hasVideo,
    required this.thumbnails,
    required this.onSeekProjectTime,
    required this.onImport,
    required this.onTrimStartCommitted,
    required this.onTrimEndCommitted,
  });

  @override
  State<TimelineVideoTrack> createState() => _TimelineVideoTrackState();
}

class _TimelineVideoTrackState extends State<TimelineVideoTrack> {
  static const Duration _minimumDuration = Duration(milliseconds: 500);

  // Os valores de rascunho são tempos do arquivo original. Assim a alça
  // direita consegue voltar até sourceDuration, mesmo após um corte anterior.
  late Duration _draftSourceStart;
  late Duration _draftSourceEnd;
  TrimHandleSide? _activeHandle;

  bool get _isTrimming => _activeHandle != null;

  Duration get _draftProjectDuration {
    final value = _draftSourceEnd - _draftSourceStart;
    return value < _minimumDuration ? _minimumDuration : value;
  }

  double get _clipWidth {
    final raw = _draftProjectDuration.inMilliseconds /
        1000.0 *
        widget.pixelsPerSecond;

    return raw.clamp(1.0, widget.timelineWidth).toDouble();
  }

  // Ao mover a alça esquerda, o deslocamento é temporário. Ao soltar, o
  // EditorPage confirma o novo trim e o auto-ripple recoloca o clipe em x = 0.
  double get _clipLeftDuringDrag {
    if (_activeHandle != TrimHandleSide.start) return 0.0;

    final removedFromStart = _draftSourceStart - widget.sourceTrimStart;
    final raw = removedFromStart.inMilliseconds /
        1000.0 *
        widget.pixelsPerSecond;

    return raw.clamp(0.0, widget.timelineWidth - _clipWidth).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _syncDraftFromWidget();
  }

  @override
  void didUpdateWidget(covariant TimelineVideoTrack oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isTrimming &&
        (oldWidget.sourceTrimStart != widget.sourceTrimStart ||
            oldWidget.sourceTrimEnd != widget.sourceTrimEnd ||
            oldWidget.sourceDuration != widget.sourceDuration)) {
      _syncDraftFromWidget();
    }
  }

  void _syncDraftFromWidget() {
    _draftSourceStart = widget.sourceTrimStart;
    _draftSourceEnd = widget.sourceTrimEnd;
  }

  void _onDragStarted(TrimHandleSide side) {
    setState(() {
      _activeHandle = side;
    });
  }

  void _onStartDrag(double deltaPixels) {
    if (widget.pixelsPerSecond <= 0) return;

    final delta = Duration(
      milliseconds: (deltaPixels / widget.pixelsPerSecond * 1000).round(),
    );
    final maximumStart = _draftSourceEnd - _minimumDuration;
    final candidate = _draftSourceStart + delta;

    final safeStart = candidate < Duration.zero
        ? Duration.zero
        : candidate > maximumStart
            ? maximumStart
            : candidate;

    if (safeStart == _draftSourceStart) return;

    setState(() {
      _draftSourceStart = safeStart;
    });
  }

  void _onEndDrag(double deltaPixels) {
    if (widget.pixelsPerSecond <= 0) return;

    final delta = Duration(
      milliseconds: (deltaPixels / widget.pixelsPerSecond * 1000).round(),
    );
    final minimumEnd = _draftSourceStart + _minimumDuration;
    final candidate = _draftSourceEnd + delta;

    // Aqui está o ponto central: o máximo é sourceDuration, e não a duração
    // atual do projeto. Delta positivo restaura o trecho removido à direita.
    final safeEnd = candidate < minimumEnd
        ? minimumEnd
        : candidate > widget.sourceDuration
            ? widget.sourceDuration
            : candidate;

    if (safeEnd == _draftSourceEnd) return;

    setState(() {
      _draftSourceEnd = safeEnd;
    });
  }

  void _onDragEnded() {
    final side = _activeHandle;
    if (side == null) return;

    final sourceStart = _draftSourceStart;
    final sourceEnd = _draftSourceEnd;

    setState(() {
      _activeHandle = null;
    });

    if (side == TrimHandleSide.start) {
      widget.onTrimStartCommitted(sourceStart);
    } else {
      widget.onTrimEndCommitted(sourceEnd);
    }
  }

  void _seekFromClip(Offset localPosition) {
    if (!widget.hasVideo) {
      widget.onImport?.call();
      return;
    }

    final onSeek = widget.onSeekProjectTime;
    if (onSeek == null || _clipWidth <= 0) return;

    final fraction = (localPosition.dx / _clipWidth).clamp(0.0, 1.0);
    final projectMilliseconds =
        (_draftProjectDuration.inMilliseconds * fraction).round();

    onSeek(Duration(milliseconds: projectMilliseconds));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasVideo || widget.sourceDuration <= Duration.zero) {
      return SizedBox(
        width: widget.timelineWidth,
        height: widget.height,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onImport,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF151A20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF315D92),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Importar vídeo',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.timelineWidth,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: _clipLeftDuringDrag,
            top: 0,
            width: _clipWidth,
            height: widget.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                if (!_isTrimming) _seekFromClip(details.localPosition);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF151A20),
                        border: Border.all(
                          color: const Color(0xFF4B8CFF),
                          width: _isTrimming ? 2 : 1,
                        ),
                      ),
                      child: _buildThumbnails(),
                    ),
                  ),
                  TrimHandles(
                    width: _clipWidth,
                    height: widget.height,
                    onStartDrag: _onStartDrag,
                    onEndDrag: _onEndDrag,
                    onDragStarted: _onDragStarted,
                    onDragEnded: _onDragEnded,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 5,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x99000000),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDuration(_draftProjectDuration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnails() {
    if (widget.thumbnails.isEmpty) {
      return const Center(
        child: Text(
          'Gerando prévias...',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }

    final total = widget.thumbnails.length;
    final sourceMilliseconds = widget.sourceDuration.inMilliseconds;

    final startRatio = sourceMilliseconds <= 0
        ? 0.0
        : _draftSourceStart.inMilliseconds / sourceMilliseconds;
    final endRatio = sourceMilliseconds <= 0
        ? 1.0
        : _draftSourceEnd.inMilliseconds / sourceMilliseconds;

    final firstIndex = (startRatio * total).floor().clamp(0, total - 1);
    final lastIndex = (endRatio * total).ceil().clamp(firstIndex + 1, total);
    final visibleThumbnails = widget.thumbnails.sublist(firstIndex, lastIndex);

    return Row(
      children: visibleThumbnails
          .map(
            (thumbnail) => Expanded(
              child: Image.memory(
                thumbnail,
                height: widget.height,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  return const ColoredBox(color: Color(0xFF151A20));
                },
              ),
            ),
          )
          .toList(),
    );
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    final tenths = (value.inMilliseconds.remainder(1000) / 100).floor();
    return '$minutes:$seconds.$tenths';
  }
}