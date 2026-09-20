class EditorTextClip {
  final String id;
  final Duration start;
  final Duration end;
  final String label;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  const EditorTextClip({
    required this.id,
    required this.start,
    required this.end,
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
  });

  EditorTextClip copyWith({
    String? id,
    Duration? start,
    Duration? end,
    String? label,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
  }) {
    return EditorTextClip(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      label: label ?? this.label,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
    );
  }
}