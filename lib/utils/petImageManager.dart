import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class PetImageManager {
  Future<void> pickAndSaveImage(String petName, String petBreed) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      Directory docDir = await getApplicationDocumentsDirectory();
      String docPath = docDir.path;

      DateTime now = DateTime.now();
      String timestamp = now.toIso8601String();
      String fileName = '$timestamp${pickedFile.name}';
      File imageFile = File(pickedFile.path);

      String filePath = '$docPath/$fileName';
      imageFile.copySync(filePath);

      Map<String, dynamic> metadata = {
        'filePath': filePath,
        'timestamp': timestamp,
      };
      String metadataFilePath = '$docPath/$fileName.metadata';
      File(metadataFilePath).writeAsStringSync(jsonEncode(metadata));

    } else {
    }
  }
}
