import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Service for uploading profile pictures and other user media to Firebase Storage.
/// Note: Recordings are stored locally on device using LocalStorageService.
class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload user profile image to Firebase Storage
  static Future<void> uploadImage(String filePath, String storagePath) async {
    try {
      final storageRef = _storage.ref().child(storagePath);
      final uploadTask = await storageRef.putFile(File(filePath));
      final imageUrl = await uploadTask.ref.getDownloadURL();
      if (kDebugMode) {
        print('Image uploaded to Firebase Storage: $imageUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image to Firebase Storage: $e');
      }
      rethrow;
    }
  }
}