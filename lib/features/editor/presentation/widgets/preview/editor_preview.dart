import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class EditorPreview extends StatelessWidget {
  final VideoPlayerController? controller;
  final Widget? overlay;
  final bool isLoading;
  final VoidCallback? onImport;

  const EditorPreview({
    super.key,
    required this.controller,
    required this.overlay,
    required this.isLoading,
    required this.onImport,
  });

  static const Color brand = Color(0xFF7B5CFF);

  @override
  Widget build(BuildContext context) {
    final video = controller;
    final initialized = video != null && video.value.isInitialized;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final width = (maxHeight * 9 / 16).clamp(1.0, maxWidth);
        final height = width * 16 / 9;

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _buildContent(
                video: video,
                initialized: initialized,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent({
    required VideoPlayerController? video,
    required bool initialized,
  }) {
    if (isLoading) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(
            color: brand,
            strokeWidth: 2.2,
          ),
        ),
      );
    }

    if (video == null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: InkWell(
            onTap: onImport,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Toque em Importar para escolher um vídeo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (!initialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(
            color: brand,
            strokeWidth: 2.2,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        ColoredBox(
          color: Colors.black,
          child: Center(
            child: AspectRatio(
              aspectRatio: video.value.aspectRatio,
              child: VideoPlayer(video),
            ),
          ),
        ),
        if (overlay != null) overlay!,
      ],
    );
  }
}