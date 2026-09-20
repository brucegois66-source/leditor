import 'package:image_picker/image_picker.dart';

class VideoGalleryService {
  final ImagePicker _picker;

  VideoGalleryService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  Future<XFile?> pickVideoFromGallery() {
    return _picker.pickVideo(
      source: ImageSource.gallery,
    );
  }
}