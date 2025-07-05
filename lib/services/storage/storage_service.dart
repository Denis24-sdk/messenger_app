import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:messenger_flutter/config.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();

  final String _uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';

  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch(e) {
      print("Ошибка при выборе изображения: $e");
    }
    return null;
  }

  Future<Map<String, String>?> uploadFile(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      request.fields['upload_preset'] = cloudinaryUploadPreset;

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send().timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        var responseData = jsonDecode(await response.stream.bytesToString());
        print("Успешный ответ от Cloudinary: $responseData");
        return {
          'url': responseData['secure_url'],
          'fileId': responseData['public_id'],
        };
      } else {
        print("Ошибка загрузки на Cloudinary. Статус код: ${response.statusCode}");
        print("Тело ответа: ${await response.stream.bytesToString()}");
        return null;
      }
    } catch (e) {
      print("Исключение при загрузке на Cloudinary: $e");
      return null;
    }
  }


  // Имитируем успешное удаление (временно)
  Future<bool> deleteFile(String fileId) async {
    print("Удаление на Cloudinary требует аутентифицированного API");
    return true;
  }
}