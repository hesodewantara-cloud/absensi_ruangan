import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 720,
        maxHeight: 1280,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      throw Exception('Gagal mengambil foto: $e');
    }
  }

  Future<String> uploadImage(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      await Supabase.instance.client.storage
          .from('attendance_photos')
          .upload(fileName, file);

      return Supabase.instance.client.storage
          .from('attendance_photos')
          .getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Gagal mengupload foto: $e');
    }
  }

  String generateFileName(String userId) {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'attendance_${userId}_$timestamp.jpg';
  }
}