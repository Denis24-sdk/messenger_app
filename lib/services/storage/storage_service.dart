import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:messenger_flutter/config.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();

  final String _vercelServerUrl = 'https://cloudinary-delete-proxy.vercel.app';
  final String _cloudinaryUploadUrl = 'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';

  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      print("Image pick error: $e");
      return null;
    }
  }

  Future<File> _compressImage(File original, {int maxSize = 1600, int quality = 35}) async {
    try {
      final bytes = await original.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Image decoding failed');

      final ratio = image.width / image.height;
      int newWidth, newHeight;

      if (image.width > image.height) {
        newWidth = min(image.width, maxSize);
        newHeight = (newWidth / ratio).round();
      } else {
        newHeight = min(image.height, maxSize);
        newWidth = (newHeight * ratio).round();
      }

      final resized = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.average,
      );

      final compressedBytes = img.encodeJpg(resized, quality: quality);
      final tempFile = File('${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressedBytes);
      print("Image compressed and saved to: ${tempFile.path}");
      return tempFile;
    } catch (e) {
      print("Image compression error: $e");
      return original;
    }
  }

  Future<Map<String, dynamic>?> uploadFile(File file) async {
    try {
      print("Starting file upload: ${file.path}");
      final compressedFile = await _compressImage(file);

      final request = http.MultipartRequest('POST', Uri.parse(_cloudinaryUploadUrl));

      request.fields['upload_preset'] = cloudinaryUploadPreset;

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        compressedFile.path,
      ));

      print("Sending upload request to Cloudinary...");
      final response = await request.send().timeout(const Duration(seconds: 60));
      print("Received response from Cloudinary. Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseData = jsonDecode(responseBody);
        print("File uploaded successfully: ${responseData['secure_url']}");
        return {
          'url': responseData['secure_url'],
          'fileId': responseData['public_id'],
        };
      } else {
        final errorBody = await response.stream.bytesToString();
        print("Cloudinary Upload Error: ${response.statusCode}, $errorBody");
        return null;
      }
    } catch (e) {
      print("Upload Exception: $e");
      return null;
    }
  }

  Future<bool> deleteFile(String fileId) async {
    if (delete_secret_key.isEmpty) {
      print('Error: DELETE_SECRET_KEY is not set. Use --dart-define=DELETE_SECRET_KEY=your_secret when running/building.');
      return false;
    }

    try {
      print("Starting file deletion with fileId: $fileId");
      final url = Uri.parse('$_vercelServerUrl/api/delete-image');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $delete_secret_key',
        },
        body: jsonEncode({'publicId': fileId}),
      ).timeout(const Duration(seconds: 30));

      print("Received response from Vercel. Status: ${response.statusCode}");
      final int statusCode = response.statusCode;
      final String responseBodyString = response.body;
      dynamic responseBody;
      try {
        responseBody = jsonDecode(responseBodyString);
      } catch (e) {
        print("Error parsing JSON response: $e. Response: $responseBodyString");
        responseBody = {'message': 'Invalid response format'};
      }

      if (statusCode == 200 && responseBody is Map && responseBody['success'] == true) {
        print('File deleted successfully via Vercel: ${responseBody['message']}');
        return true;
      } else if (statusCode == 401) {
        print('Delete Auth Error: ${responseBody['message']}');
        return false;
      } else if (statusCode == 404) {
        print('File not found in Cloudinary for deletion: ${responseBody['message']}');
        return true;
      } else if (statusCode == 400) {
        print('Bad Request for deletion: ${responseBody['message']}');
        return false;
      } else {
        print('Vercel Delete Error: $statusCode, Response: $responseBodyString');
        return false;
      }
    } catch (e) {
      print('Delete Request Error: $e');
      return false;
    }
  }

  Future<String?> uploadAndGetUrl() async {
    try {
      final image = await pickImage();
      if (image == null) {
        print("No image selected");
        return null;
      }

      final uploadResult = await uploadFile(image);
      if (uploadResult == null) {
        print("Upload failed");
        return null;
      }

      print("Upload successful. URL: ${uploadResult['url']}");
      return uploadResult['url'];
    } catch (e) {
      print('Upload Process Error: $e');
      return null;
    }
  }
}