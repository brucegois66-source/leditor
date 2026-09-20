import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class EditorPlayerControls extends StatelessWidget {
  final VideoPlayerController? controller;

  // Valores que aparecem na interface após o trim.
  // Não use controller.value.duration para o contador total.
  final Duration projectPosition;
  final Duration projectDuration;

  // O EditorPage faz a conversão:
  // sourceTime = trimStart + projectTime.
  final ValueChanged<Duration> onSeekProjectTime;

  final VoidCallback onFullscreen;

  const EditorPlayerControls({
    super.key,
    required this.controller,
    required this.projectPosition,
    required this.projectDuration,
    required this.onSeekProjectTime,
    required this.onFullscreen,
  });

  static const Duration _seekStep = Duration(seconds: 5);

  bool get _isReady {
    return controller != null && controller!.value.isInitialized;
  }

  bool get _isPlaying {
    return controller?.value.isPlaying ?? false;
  }

  Future<void> _togglePlayPause() async {
    final player = controller;

    if (player == null || !player.value.isInitialized) {
      return;
    }

    if (player.value.isPlaying) {
      await player.pause();
    } else {
      // Se estiver no final do projeto e o usuário apertar play,
      // volta ao início do trecho selecionado antes de reproduzir.
      if (projectPosition >= projectDuration &&
          projectDuration > Duration.zero) {
        onSeekProjectTime(Duration.zero);
      }

      await player.play();
    }
  }

  void _seekBy(Duration delta) {
    if (!_isReady || projectDuration <= Duration.zero) {
      return;
    }

    var target = projectPosition + delta;

    if (target < Duration.zero) {
      target = Duration.zero;
    }

    if (target > projectDuration) {
      target = projectDuration;
    }

    onSeekProjectTime(target);
  }

  String _formatTime(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
    double iconSize = 22,
    Color color = Colors.white,
  }) {
    return IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: 42,
        height: 42,
      ),
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: iconSize,
        color: onPressed == null ? Colors.white24 : color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canControl = _isReady && projectDuration > Duration.zero;

    return Container(
      height: 48,
      color: const Color(0xFF101014),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tempo atual e tempo total sempre refletem o projeto após o trim.
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 88,
              child: Text(
                '${_formatTime(projectPosition)} / '
                '${_formatTime(projectDuration)}',
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),

          // Grupo central: voltar, play/pause e avançar.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildControlButton(
                icon: Icons.replay_5,
                tooltip: 'Voltar 5 segundos',
                onPressed: canControl
                    ? () => _seekBy(-_seekStep)
                    : null,
              ),
              _buildControlButton(
                icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                tooltip: _isPlaying ? 'Pausar' : 'Reproduzir',
                iconSize: 29,
                onPressed: canControl ? _togglePlayPause : null,
              ),
              _buildControlButton(
                icon: Icons.forward_5,
                tooltip: 'Avançar 5 segundos',
                onPressed: canControl
                    ? () => _seekBy(_seekStep)
                    : null,
              ),
            ],
          ),

          Align(
            alignment: Alignment.centerRight,
            child: _buildControlButton(
              icon: Icons.fullscreen,
              tooltip: 'Tela cheia',
              iconSize: 23,
              onPressed: _isReady ? onFullscreen : null,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}