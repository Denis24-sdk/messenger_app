import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:messenger_flutter/config.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class StorageService {
  final ImagePicker _picker = ImagePicker();
  final String _replitServerUrl = 'https://6d5b6b86-0b93-4c2e-ac16-833bf4c89bfb-00-2nfhcy2sokeht.janeway.replit.dev';
  final String _uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';

  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print("Ошибка при выборе изображения: $e");
    }
    return null;
  }

  Future<File> _compressImage(File original, {int maxSize = 1600, int quality = 35}) async {
    try {
      // Декодируем оригинальное изображение
      final bytes = await original.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) throw Exception('Не удалось декодировать изображение');

      // Рассчитываем новые размеры
      final width = image.width;
      final height = image.height;
      final ratio = width / height;

      int newWidth, newHeight;
      if (width > height) {
        newWidth = min(width, maxSize);
        newHeight = (newWidth / ratio).round();
      } else {
        newHeight = min(height, maxSize);
        newWidth = (newHeight * ratio).round();
      }

      img.Image resized = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.average,
      );

      // Конвертируем и сжимаем
      List<int> compressedBytes = img.encodeJpg(resized, quality: quality);

      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressedBytes);

      return tempFile;
    } catch (e) {
      print("Ошибка сжатия изображения: $e");
      return original;
    }
  }

  Future<Map<String, String>?> uploadFile(File file) async {
    try {
      final compressedFile = await _compressImage(file);

      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = cloudinaryUploadPreset;

      request.files.add(await http.MultipartFile.fromPath(
          'file',
          compressedFile.path
      ));

      var response = await request.send().timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        var responseData = jsonDecode(await response.stream.bytesToString());
        return {
          'url': responseData['secure_url'],
          'fileId': responseData['public_id'],
        };
      } else {
        print("Ошибка загрузки. Статус: ${response.statusCode}, Тело: ${await response.stream.bytesToString()}");
        return null;
      }
    } catch (e) {
      print("Исключение при загрузке: $e");
      return null;
    }
  }

  /// Удаляет файл из Cloudinary через Replit
  Future<bool> deleteFile(String fileId) async {
    try {
      final response = await http.post(
        Uri.parse('$_replitServerUrl/delete-image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'publicId': fileId}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        print('Файл успешно удален через Replit');
        return true;
      } else {
        print('Ошибка от сервера Replit: ${response.statusCode}, ${response.body}');
        return false;
      }
    } catch (e) {
      print('Ошибка при обращении к серверу Replit: $e');
      return false;
    }
  }
}