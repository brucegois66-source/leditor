class EditorAudioClip {
  final String path;
  final String label;
  final Duration start;
  final Duration end;

  const EditorAudioClip({
    required this.path,
    required this.label,
    required this.start,
    required this.end,
  });

  Duration get duration => end - start;

  EditorAudioClip copyWith({
    String? path,
    String? label,
    Duration? start,
    Duration? end,
  }) {
    return EditorAudioClip(
      path: path ?? this.path,
      label: label ?? this.label,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}