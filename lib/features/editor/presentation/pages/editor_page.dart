import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import 'package:leditor/features/editor/data/services/video_gallery_service.dart';
import 'package:leditor/features/editor/data/services/video_thumbnail_service.dart';
import 'package:leditor/features/editor/presentation/controllers/editor_controller.dart';
import 'package:leditor/features/editor/presentation/widgets/player/editor_player_controls.dart';
import 'package:leditor/features/editor/presentation/widgets/preview/editor_preview.dart';
import 'package:leditor/features/editor/presentation/widgets/timeline/editor_timeline.dart';
import 'package:leditor/features/editor/presentation/widgets/toolbar/editor_toolbar.dart';
import 'package:leditor/features/editor/presentation/widgets/top_bar/editor_top_bar.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  static const Duration _minimumTrimDuration = Duration(milliseconds: 500);

  late final EditorController controller;
  final VideoGalleryService _galleryService = VideoGalleryService();
  final VideoThumbnailService _thumbnailService = VideoThumbnailService();

  VideoPlayerController? _videoController;
  XFile? _selectedVideo;
  List<Uint8List> _videoThumbnails = const <Uint8List>[];

  // Valores no tempo físico do arquivo original.
  Duration _sourcePosition = Duration.zero;
  Duration _sourceDuration = Duration.zero;

  // Limites do trecho mantido, também no tempo do arquivo original.
  Duration _trimStart = Duration.zero;
  Duration _trimEnd = Duration.zero;

  bool _isLoading = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    controller = EditorController();
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoProgress);
    _videoController?.dispose();
    controller.dispose();
    super.dispose();
  }

  // Duração visual do projeto após o trim.
  Duration get _projectDuration {
    final value = _trimEnd - _trimStart;
    return value > Duration.zero ? value : Duration.zero;
  }

  // Posição visual: relativa ao início do trecho que sobrou.
  Duration get _projectPosition {
    final value = _sourcePosition - _trimStart;

    if (value < Duration.zero) return Duration.zero;
    if (value > _projectDuration) return _projectDuration;

    return value;
  }

  Future<void> _importVideo() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    VideoPlayerController? nextController;

    try {
      final video = await _galleryService.pickVideoFromGallery();
      if (video == null) return;

      nextController = VideoPlayerController.file(File(video.path));
      await nextController.initialize();

      final sourceDuration = nextController.value.duration;
      final thumbnails = await _thumbnailService.generateThumbnails(
        videoPath: video.path,
        duration: sourceDuration,
        count: 12,
      );

      final oldController = _videoController;
      oldController?.removeListener(_onVideoProgress);
      await oldController?.dispose();

      if (!mounted) {
        await nextController.dispose();
        nextController = null;
        return;
      }

      nextController.addListener(_onVideoProgress);

      setState(() {
        _videoController = nextController;
        _selectedVideo = video;
        _videoThumbnails = thumbnails;
        _sourceDuration = sourceDuration;
        _sourcePosition = Duration.zero;
        _trimStart = Duration.zero;
        _trimEnd = sourceDuration;
        _isMuted = false;
      });

      nextController = null;
    } catch (error) {
      await nextController?.dispose();

      if (mounted) {
        _showMessage('Erro ao importar vídeo: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onVideoProgress() {
    final player = _videoController;
    if (!mounted || player == null || !player.value.isInitialized) return;

    final nextPosition = player.value.position;
    final nextDuration = player.value.duration;

    // Garante que o preview nunca toque conteúdo que foi removido.
    if (_trimEnd > Duration.zero && nextPosition >= _trimEnd) {
      player.pause();
      player.seekTo(_trimEnd);

      setState(() {
        _sourcePosition = _trimEnd;
        _sourceDuration = nextDuration;
      });
      return;
    }

    if (nextPosition < _trimStart) {
      player.seekTo(_trimStart);

      setState(() {
        _sourcePosition = _trimStart;
        _sourceDuration = nextDuration;
      });
      return;
    }

    if (nextPosition == _sourcePosition && nextDuration == _sourceDuration) {
      return;
    }

    setState(() {
      _sourcePosition = nextPosition;
      _sourceDuration = nextDuration;
    });
  }

  // Recebe tempo da timeline em relação ao projeto e converte ao vídeo fonte.
  Future<void> _seekProjectTime(Duration projectTime) async {
    final player = _videoController;
    if (player == null || !player.value.isInitialized) return;

    var safeProjectTime = projectTime;
    if (safeProjectTime < Duration.zero) safeProjectTime = Duration.zero;
    if (safeProjectTime > _projectDuration) {
      safeProjectTime = _projectDuration;
    }

    final sourceTime = _trimStart + safeProjectTime;
    await player.seekTo(sourceTime);

    if (!mounted) return;

    setState(() {
      _sourcePosition = sourceTime;
      _sourceDuration = player.value.duration;
    });
  }

  Future<void> _changeTrimStart(Duration nextStart) async {
    if (_sourceDuration <= Duration.zero) return;

    final maximumStart = _trimEnd - _minimumTrimDuration;
    final safeStart = nextStart < Duration.zero
        ? Duration.zero
        : nextStart > maximumStart
            ? maximumStart
            : nextStart;

    if (safeStart == _trimStart) return;

    setState(() {
      _trimStart = safeStart;
    });

    final player = _videoController;
    if (player == null || !player.value.isInitialized) return;

    // Auto-ripple: o novo início do trecho fica em 00:00 na interface.
    await player.pause();
    await player.seekTo(safeStart);

    if (!mounted) return;

    setState(() {
      _sourcePosition = safeStart;
      _sourceDuration = player.value.duration;
    });
  }

  Future<void> _changeTrimEnd(Duration nextEnd) async {
    if (_sourceDuration <= Duration.zero) return;

    final minimumEnd = _trimStart + _minimumTrimDuration;
    final safeEnd = nextEnd < minimumEnd
        ? minimumEnd
        : nextEnd > _sourceDuration
            ? _sourceDuration
            : nextEnd;

    if (safeEnd == _trimEnd) return;

    setState(() {
      _trimEnd = safeEnd;
    });

    final player = _videoController;
    if (player == null || !player.value.isInitialized) return;

    // Se o playhead estava depois do novo final, estaciona no final novo.
    if (_sourcePosition >= safeEnd) {
      await player.pause();
      await player.seekTo(safeEnd);

      if (!mounted) return;

      setState(() {
        _sourcePosition = safeEnd;
        _sourceDuration = player.value.duration;
      });
    }
  }

  Future<void> _pickAudio() async {
    _showMessage('Importação de áudio será implementada em seguida.');
  }

  Future<void> _exportVideo() async {
    final video = _selectedVideo;

    if (video == null) {
      _showMessage('Importe um vídeo antes de exportar.');
      return;
    }

    _showMessage(
      'Trim selecionado: ${_formatTime(_trimStart)} até '
      '${_formatTime(_trimEnd)}. A renderização será o próximo passo.',
    );

    try {
      await Share.shareXFiles(
        [XFile(video.path)],
        text: 'Vídeo exportado pelo Leditor',
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Erro ao exportar vídeo: $error');
      }
    }
  }

  Future<void> _toggleMute() async {
    final player = _videoController;
    if (player == null || !player.value.isInitialized) return;

    final nextMuted = !_isMuted;
    await player.setVolume(nextMuted ? 0.0 : 1.0);

    if (!mounted) return;

    setState(() {
      _isMuted = nextMuted;
    });
  }

  String _formatTime(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = _videoController;
    final hasVideo = player?.value.isInitialized ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF101014),
      appBar: EditorTopBar(
        onImport: _importVideo,
        onExport: _exportVideo,
        isLoading: _isLoading,
        canExport: _selectedVideo != null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: EditorPreview(
                controller: player,
                overlay: const SizedBox.shrink(),
                isLoading: _isLoading,
                onImport: _importVideo,
              ),
            ),
            EditorPlayerControls(
              controller: player,
              projectPosition: _projectPosition,
              projectDuration: _projectDuration,
              onSeekProjectTime: _seekProjectTime,
              onFullscreen: () {
                _showMessage('Tela cheia será adicionada em seguida.');
              },
            ),
            EditorTimeline(
              sourceDuration: _sourceDuration,
              duration: _projectDuration,
              position: _projectPosition,
              trimStart: _trimStart,
              trimEnd: _trimEnd,
              hasVideo: hasVideo,
              audioClips: controller.audioClips,
              videoThumbnails: _videoThumbnails,
              isMuted: _isMuted,
              onToggleMute: _toggleMute,
              onImportVideo: _importVideo,
              onSeek: _seekProjectTime,
              onTrimStartChanged: _changeTrimStart,
              onTrimEndChanged: _changeTrimEnd,
              onAddAudio: _pickAudio,
              onAddText: () {
                _showMessage('Adicionar texto será implementado em seguida.');
              },
            ),
            const EditorToolbar(selectedIndex: 0),
          ],
        ),
      ),
    );
  }
}