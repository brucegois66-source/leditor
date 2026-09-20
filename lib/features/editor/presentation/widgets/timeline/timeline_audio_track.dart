import 'package:flutter/material.dart';

import '../../../domain/models/editor_audio_clip.dart';

class TimelineAudioTrack extends StatelessWidget {
  final Duration duration;
  final List<EditorAudioClip> clips;
  final ValueChanged<EditorAudioClip>? onTapClip;

  const TimelineAudioTrack({
    super.key,
    required this.duration,
    required this.clips,
    this.onTapClip,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          const SizedBox(
            width: 48,
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white54,
              size: 18,
            ),
          ),
          Expanded(
            child: clips.isEmpty
                ? _emptyTrack()
                : Row(
                    children: clips.map((clip) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onTapClip?.call(clip),
                          child: Container(
                            height: 34,
                            margin: const EdgeInsets.only(right: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: const Color(0xFF226B55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              clip.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyTrack() {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF292929)),
      ),
    );
  }
}