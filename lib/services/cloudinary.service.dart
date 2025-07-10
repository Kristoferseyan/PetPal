import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  final String cloudinaryUrl = dotenv.env['CLOUDINARY_URL']!;
  
  Future<String> uploadImage(
    File image, {
    String preset = 'petsimages',
    String? folder,
  }) async {
    try {
      final uri = Uri.parse(cloudinaryUrl);
      final mimeType = lookupMimeType(image.path)!;
      
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = preset;

      if (folder != null && folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }
      
      final fileField = await http.MultipartFile.fromPath(
        'file',
        image.path,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(fileField);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to upload image: ${response.body}');
      }
      
      final decoded = jsonDecode(response.body);
      return decoded['secure_url'];
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  Future<String> uploadMedicalImage(File image) async {
    return uploadImage(
      image,
      preset: 'medical_records',
      folder: 'medical_records',
    );
  }
}