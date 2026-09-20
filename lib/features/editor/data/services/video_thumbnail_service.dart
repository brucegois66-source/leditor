import 'dart:typed_data';

import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailService {
  Future<List<Uint8List>> generateThumbnails({
    required String videoPath,
    required Duration duration,
    int count = 12,
  }) async {
    if (duration <= Duration.zero) {
      return <Uint8List>[];
    }

    final totalMs = duration.inMilliseconds;
    final safeCount = count < 1 ? 1 : count;
    final thumbnails = <Uint8List>[];

    for (var index = 0; index < safeCount; index++) {
      final timeMs = safeCount == 1
          ? 0
          : ((totalMs * index) / (safeCount - 1)).round();

      final data = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: timeMs,
        maxWidth: 140,
        quality: 70,
      );

      if (data != null) {
        thumbnails.add(data);
      }
    }

    return thumbnails;
  }
}