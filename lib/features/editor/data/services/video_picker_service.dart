import 'package:file_picker/file_picker.dart';

class VideoPickerService {
  const VideoPickerService();

  Future<PlatformFile?> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    return result.files.first;
  }
}