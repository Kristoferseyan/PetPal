import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ImageExpiryManager {
  Future<void> deleteExpiredImages() async {
    Directory docDir = await getApplicationDocumentsDirectory();
    String docPath = docDir.path;

    List<FileSystemEntity> files = Directory(docPath).listSync();
    DateTime now = DateTime.now();
    Duration expirationDuration = Duration(days: 90);

    for (var file in files) {
      if (file.path.endsWith('.metadata')) {
        String metadataContent = await File(file.path).readAsString();
        Map<String, dynamic> metadata = jsonDecode(metadataContent);
        String filePath = metadata['filePath'];
        String timestampString = metadata['timestamp'];

        DateTime timestamp = DateTime.parse(timestampString);
        Duration fileAge = now.difference(timestamp);

        if (fileAge > expirationDuration) {
          File(filePath).deleteSync();
          file.deleteSync();

        }
      }
    }
  }
}
