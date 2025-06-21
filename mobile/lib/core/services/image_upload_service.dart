import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';

class ImageUploadService {
  final CloudinaryPublic _cloudinary;

  ImageUploadService({required String cloudName, required String uploadPreset})
      : _cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);

  Future<String> uploadImage(File imageFile) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }
}
