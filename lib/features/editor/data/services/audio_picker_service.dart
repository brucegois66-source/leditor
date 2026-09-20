import 'package:file_picker/file_picker.dart';

class AudioPickerService {
  const AudioPickerService();

  Future<PlatformFile?> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    return result.files.first;
  }
}