import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../../domain/models/editor_audio_clip.dart';
import '../../domain/models/editor_text_clip.dart';

class EditorController extends ChangeNotifier {
  VideoPlayerController? _videoController;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = false;
  String? _error;
  int _selectedTool = 0;
  EditorTextClip? _editingTextClip;
  EditorTextClip? _draftTextClip;

  final List<EditorAudioClip> _audioClips = [];
  final List<EditorTextClip> _textClips = [];

  VideoPlayerController? get videoController => _videoController;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedTool => _selectedTool;
  bool get isReady => _videoController?.value.isInitialized ?? false;
  bool get isPlaying => _videoController?.value.isPlaying ?? false;
  EditorTextClip? get editingTextClip => _editingTextClip;
  EditorTextClip? get draftTextClip => _draftTextClip;
  List<EditorAudioClip> get audioClips => List.unmodifiable(_audioClips);
  List<EditorTextClip> get textClips => List.unmodifiable(_textClips);

  Future<void> loadVideo(String path) async {
    _setLoading(true);
    _error = null;
    _clearTextDraft();

    try {
      final nextController = VideoPlayerController.file(File(path));
      await nextController.initialize();

      _videoController?.removeListener(_videoListener);
      await _videoController?.dispose();

      _videoController = nextController;
      _videoController!.addListener(_videoListener);
      _duration = _videoController!.value.duration;
      _position = Duration.zero;
      _audioClips.clear();
      _textClips.clear();
    } catch (error) {
      _error = 'Erro ao abrir vídeo: $error';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> playPause() async {
    final video = _videoController;
    if (video == null || !video.value.isInitialized) return;

    if (video.value.isPlaying) {
      await video.pause();
    } else {
      await video.play();
    }
    notifyListeners();
  }

  Future<void> seekRelative(int seconds) async {
    final video = _videoController;
    if (video == null || !video.value.isInitialized) return;

    final requested = video.value.position + Duration(seconds: seconds);
    final position = requested < Duration.zero
        ? Duration.zero
        : requested > _duration
            ? _duration
            : requested;

    await video.seekTo(position);
  }

  Future<void> seekTo(Duration value) async {
    final video = _videoController;
    if (video == null || !video.value.isInitialized) return;
    await video.seekTo(value);
  }

  void selectTool(int index) {
    _selectedTool = index;
    notifyListeners();
  }

  void addAudioClip(EditorAudioClip clip) {
    _audioClips.add(clip);
    notifyListeners();
  }

  void clearAudioClips() {
    _audioClips.clear();
    notifyListeners();
  }

  void addTextClip(EditorTextClip clip) {
    _textClips.add(clip);
    notifyListeners();
  }

  void updateTextClip(EditorTextClip clip) {
    final index = _textClips.indexWhere((item) => item.id == clip.id);
    if (index == -1) return;
    _textClips[index] = clip;
    notifyListeners();
  }

  void clearTextClips() {
    _textClips.clear();
    notifyListeners();
  }

  void startNewText() {
    if (!isReady) return;

    final start = _position;
    final requestedEnd = start + const Duration(seconds: 3);
    final end = requestedEnd > _duration ? _duration : requestedEnd;

    _videoController?.pause();
    _editingTextClip = null;
    _draftTextClip = EditorTextClip(
      id: 'draft_${DateTime.now().microsecondsSinceEpoch}',
      start: start,
      end: end <= start ? start + const Duration(seconds: 1) : end,
      label: '',
      x: 0.14,
      y: 0.38,
      width: 0.72,
      height: 0.20,
      rotation: 0.0,
    );
    notifyListeners();
  }

  void startEditingText(EditorTextClip clip) {
    _videoController?.pause();
    _editingTextClip = clip;
    _draftTextClip = clip;
    notifyListeners();
  }

  void updateDraftText(EditorTextClip clip) {
    _draftTextClip = clip;
    notifyListeners();
  }

  void cancelTextEditing() {
    _clearTextDraft();
    notifyListeners();
  }

  void confirmTextEditing(String text) {
    final draft = _draftTextClip;
    if (draft == null || text.trim().isEmpty) return;

    final saved = draft.copyWith(label: text.trim());
    if (_editingTextClip == null) {
      _textClips.add(saved);
    } else {
      updateTextClip(saved);
    }

    _clearTextDraft();
    notifyListeners();
  }

  void _videoListener() {
    final video = _videoController;
    if (video == null || !video.value.isInitialized) return;

    _position = video.value.position;
    _duration = video.value.duration;
    notifyListeners();
  }

  void _clearTextDraft() {
    _editingTextClip = null;
    _draftTextClip = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }
}