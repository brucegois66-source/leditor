import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'timeline_video_track.dart';

class EditorTimeline extends StatefulWidget {
  // Duração física do arquivo original. Necessária para restaurar a alça
  // direita depois de encurtar o clipe.
  final Duration sourceDuration;

  // Tempo e duração visíveis do projeto após o trim.
  final Duration duration;
  final Duration position;

  // Limites do trim no tempo do arquivo original.
  final Duration trimStart;
  final Duration trimEnd;

  final bool hasVideo;
  final List<dynamic> audioClips;
  final List<Uint8List> videoThumbnails;
  final bool isMuted;
  final VoidCallback onToggleMute;
  final VoidCallback onImportVideo;
  final ValueChanged<Duration>? onSeek;
  final ValueChanged<Duration> onTrimStartChanged;
  final ValueChanged<Duration> onTrimEndChanged;
  final VoidCallback onAddAudio;
  final VoidCallback onAddText;

  const EditorTimeline({
    super.key,
    required this.sourceDuration,
    required this.duration,
    required this.position,
    required this.trimStart,
    required this.trimEnd,
    required this.hasVideo,
    required this.audioClips,
    required this.videoThumbnails,
    required this.isMuted,
    required this.onToggleMute,
    required this.onImportVideo,
    required this.onSeek,
    required this.onTrimStartChanged,
    required this.onTrimEndChanged,
    required this.onAddAudio,
    required this.onAddText,
  });

  @override
  State<EditorTimeline> createState() => _EditorTimelineState();
}

class _EditorTimelineState extends State<EditorTimeline> {
  final ScrollController _scrollController = ScrollController();

  bool _isUserDragging = false;

  static const double _railWidth = 34;
  static const double _rulerHeight = 22;
  static const double _videoHeight = 76;
  static const double _audioHeight = 42;
  static const double _textHeight = 42;
  static const double _gap = 5;
  static const double _secondsVisible = 9;

  // A barra branca fica fixa em 43% da largura disponível da timeline.
  static const double _freezePointFactor = 0.43;

  @override
  void didUpdateWidget(covariant EditorTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.position != widget.position ||
        oldWidget.duration != widget.duration ||
        oldWidget.trimStart != widget.trimStart ||
        oldWidget.trimEnd != widget.trimEnd ||
        oldWidget.sourceDuration != widget.sourceDuration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncScrollWithVideo();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _projectDurationSeconds() {
    return widget.duration.inMilliseconds / 1000.0;
  }

  double _timelineSeconds() {
    final duration = _projectDurationSeconds();
    return duration > _secondsVisible ? duration : _secondsVisible;
  }

  double _pixelsPerSecond(double viewportWidth) {
    return viewportWidth / _secondsVisible;
  }

  double _timelineWidth(double viewportWidth) {
    return _timelineSeconds() * _pixelsPerSecond(viewportWidth);
  }

  double _projectPositionSeconds() {
    return widget.position.inMilliseconds / 1000.0;
  }

  void _syncScrollWithVideo() {
    if (_isUserDragging ||
        !_scrollController.hasClients ||
        widget.duration <= Duration.zero) {
      return;
    }

    final metrics = _scrollController.position;
    if (!metrics.hasViewportDimension) return;

    final viewportWidth = metrics.viewportDimension;
    final pixelsPerSecond = _pixelsPerSecond(viewportWidth);
    final fixedPlayheadX = viewportWidth * _freezePointFactor;
    final leadingSpace = fixedPlayheadX;

    final contentX = leadingSpace +
        _projectPositionSeconds() * pixelsPerSecond;
    final desiredScroll = contentX - fixedPlayheadX;
    final targetScroll = desiredScroll <= 0
        ? 0.0
        : desiredScroll.clamp(0.0, metrics.maxScrollExtent);

    if ((metrics.pixels - targetScroll).abs() > 0.5) {
      _scrollController.jumpTo(targetScroll);
    }
  }

  void _seekProjectFromScroll(double viewportWidth) {
    if (widget.onSeek == null || widget.duration <= Duration.zero) return;

    final pixelsPerSecond = _pixelsPerSecond(viewportWidth);
    final fixedPlayheadX = viewportWidth * _freezePointFactor;
    final leadingSpace = fixedPlayheadX;
    final scrollOffset = _scrollController.hasClients
        ? _scrollController.position.pixels
        : 0.0;

    final projectSeconds = ((scrollOffset + fixedPlayheadX - leadingSpace) /
            pixelsPerSecond)
        .clamp(0.0, _projectDurationSeconds());

    widget.onSeek!(
      Duration(milliseconds: (projectSeconds * 1000).round()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: _railWidth, child: _buildRail()),
          Expanded(child: _buildTimeline()),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final pixelsPerSecond = _pixelsPerSecond(viewportWidth);
        final timelineWidth = _timelineWidth(viewportWidth);
        final fixedPlayheadX = viewportWidth * _freezePointFactor;

        // Em 00:00, o começo do clipe/alça esquerda fica sob o playhead.
        final leadingSpace = fixedPlayheadX;

        // No fim, ainda existe espaço para o último frame chegar ao playhead.
        final trailingSpace = viewportWidth - fixedPlayheadX;
        final totalWidth = leadingSpace + timelineWidth + trailingSpace;

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification &&
                notification.dragDetails != null) {
              _isUserDragging = true;
            }

            if (notification is ScrollEndNotification && _isUserDragging) {
              _isUserDragging = false;
              _seekProjectFromScroll(viewportWidth);
            }

            return false;
          },
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: SizedBox(
                  width: totalWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: leadingSpace),
                      SizedBox(
                        width: timelineWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildRuler(
                              width: timelineWidth,
                              pixelsPerSecond: pixelsPerSecond,
                            ),
                            TimelineVideoTrack(
                              timelineWidth: timelineWidth,
                              pixelsPerSecond: pixelsPerSecond,
                              height: _videoHeight,

                              // Duração visual atual do projeto.
                              projectDuration: widget.duration,

                              // Limites atuais no arquivo original.
                              sourceTrimStart: widget.trimStart,
                              sourceTrimEnd: widget.trimEnd,

                              // Duração original: permite a alça direita
                              // restaurar material removido até o final real.
                              sourceDuration: widget.sourceDuration,
                              hasVideo: widget.hasVideo,
                              thumbnails: widget.videoThumbnails,
                              onSeekProjectTime: widget.onSeek,
                              onImport: widget.onImportVideo,
                              onTrimStartCommitted:
                                  widget.onTrimStartChanged,
                              onTrimEndCommitted: widget.onTrimEndChanged,
                            ),
                            const SizedBox(height: _gap),
                            _buildTrack(
                              width: timelineWidth,
                              height: _audioHeight,
                              label: 'Adicionar Música',
                              onTap: widget.onAddAudio,
                            ),
                            const SizedBox(height: _gap),
                            _buildTrack(
                              width: timelineWidth,
                              height: _textHeight,
                              label: 'Adicionar texto',
                              onTap: widget.onAddText,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: trailingSpace),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: fixedPlayheadX,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(width: 2, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRail() {
    return Container(
      color: const Color(0xFF080B0F),
      child: Column(
        children: [
          const SizedBox(height: _rulerHeight),
          SizedBox(
            height: _videoHeight,
            child: Center(
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.hasVideo ? widget.onToggleMute : null,
                icon: Icon(
                  widget.isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: _gap),
          const SizedBox(
            height: _audioHeight,
            child: Center(
              child: Icon(Icons.music_note, color: Colors.white70, size: 19),
            ),
          ),
          const SizedBox(height: _gap),
          const SizedBox(
            height: _textHeight,
            child: Center(
              child: Text(
                'Tᵀ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuler({
    required double width,
    required double pixelsPerSecond,
  }) {
    return SizedBox(
      width: width,
      height: _rulerHeight,
      child: CustomPaint(
        painter: _RulerPainter(
          duration: widget.duration,
          pixelsPerSecond: pixelsPerSecond,
          minimumSeconds: _secondsVisible,
        ),
      ),
    );
  }

  Widget _buildTrack({
    required double width,
    required double height,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: const Color(0xFF252A30),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(Icons.add, color: Colors.white70, size: 21),
              const SizedBox(width: 9),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final Duration duration;
  final double pixelsPerSecond;
  final double minimumSeconds;

  const _RulerPainter({
    required this.duration,
    required this.pixelsPerSecond,
    required this.minimumSeconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = const Color(0xFF53606D)
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final durationSeconds = duration.inMilliseconds / 1000.0;
    final endSeconds = durationSeconds > minimumSeconds
        ? durationSeconds
        : minimumSeconds;

    for (double second = 0; second <= endSeconds; second += 3) {
      final x = second * pixelsPerSecond;
      canvas.drawLine(Offset(x, 13), Offset(x, size.height), tickPaint);

      textPainter.text = TextSpan(
        text: _format(Duration(milliseconds: (second * 1000).round())),
        style: const TextStyle(color: Color(0xFF7A858F), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, 0));
    }
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) {
    return oldDelegate.duration != duration ||
        oldDelegate.pixelsPerSecond != pixelsPerSecond ||
        oldDelegate.minimumSeconds != minimumSeconds;
  }
}