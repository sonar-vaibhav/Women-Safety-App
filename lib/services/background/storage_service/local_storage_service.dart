import 'dart:developer';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Service for saving and listing recordings locally on the device.
/// Replaces Firebase Storage to avoid billing requirements.
class LocalStorageService {
  // ── Path helpers ───────────────────────────────────────────────────────────

  static Future<Directory> _getAudioDir(String uid, String date) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/recordings/audios/$uid/$date');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<Directory> _getImageDir(String uid, String date) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/recordings/images/$uid/$date');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ── Audio ──────────────────────────────────────────────────────────────────

  /// Copies [sourceFilePath] (temp recorder path) into the local recordings
  /// folder and returns the saved file path.
  static Future<String?> saveAudio(
      String sourceFilePath, String uid, String date) async {
    try {
      log('Starting audio save: source=$sourceFilePath, uid=$uid, date=$date');
      
      // Verify source file exists
      final src = File(sourceFilePath);
      final srcExists = await src.exists();
      if (!srcExists) {
        log('ERROR: Source audio file does not exist: $sourceFilePath');
        return null;
      }
      final srcSize = await src.length();
      log('Source file size: $srcSize bytes');
      
      // Get destination directory
      final dir = await _getAudioDir(uid, date);
      log('Destination directory: ${dir.path}');
      
      // Create destination path with timestamp
      final destPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      // Copy file to destination
      final destFile = await src.copy(destPath);
      final destExists = await destFile.exists();
      
      if (!destExists) {
        log('ERROR: Failed to copy audio file to destination');
        return null;
      }
      
      final destSize = await destFile.length();
      log('✓ Audio saved successfully');
      log('  Destination: $destPath');
      log('  Size: $destSize bytes');
      
      return destPath;
    } catch (e) {
      log('✗ ERROR saving audio locally: $e');
      return null;
    }
  }

  /// Returns the list of local audio file paths for [uid] on [date].
  static Future<List<String>> listAudios(String uid, String date) async {
    try {
      final dir = await _getAudioDir(uid, date);
      return dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.m4a'))
          .map((f) => f.path)
          .toList()
        ..sort();
    } catch (e) {
      log('Error listing audios: $e');
      return [];
    }
  }

  // ── Images ─────────────────────────────────────────────────────────────────

  /// Copies [sourceFilePath] (camera capture path) into the local recordings
  /// folder and returns the saved file path.
  static Future<String?> saveImage(
      String sourceFilePath, String uid, String date) async {
    try {
      log('Starting image save: source=$sourceFilePath, uid=$uid, date=$date');
      
      // Verify source file exists
      final src = File(sourceFilePath);
      final srcExists = await src.exists();
      if (!srcExists) {
        log('ERROR: Source image file does not exist: $sourceFilePath');
        return null;
      }
      final srcSize = await src.length();
      log('Source image size: $srcSize bytes');
      
      // Get destination directory
      final dir = await _getImageDir(uid, date);
      log('Destination directory: ${dir.path}');
      
      // Create destination path with timestamp
      final destPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Copy file to destination
      final destFile = await src.copy(destPath);
      final destExists = await destFile.exists();
      
      if (!destExists) {
        log('ERROR: Failed to copy image file to destination');
        return null;
      }
      
      final destSize = await destFile.length();
      log('✓ Image saved successfully');
      log('  Destination: $destPath');
      log('  Size: $destSize bytes');
      
      return destPath;
    } catch (e) {
      log('✗ ERROR saving image locally: $e');
      return null;
    }
  }

  /// Returns a list of [LocalImageData] for [uid] on [date].
  static Future<List<LocalImageData>> listImages(
      String uid, String date) async {
    try {
      final dir = await _getImageDir(uid, date);
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      return files.map((f) {
        // Extract time from millisecond timestamp in filename
        final name = f.uri.pathSegments.last.replaceAll('.jpg', '');
        final ts = int.tryParse(name);
        final time = ts != null
            ? _formatTime(DateTime.fromMillisecondsSinceEpoch(ts))
            : name;
        return LocalImageData(f.path, time);
      }).toList();
    } catch (e) {
      log('Error listing images: $e');
      return [];
    }
  }

  // ── Videos ────────────────────────────────────────────────────────────────

  static Future<Directory> _getVideoDir(String uid, String date) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/recordings/videos/$uid/$date');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Saves dual videos (front and back) as a recorded pair
  static Future<DualVideoData?> saveDualVideos(
    String? frontVideoPath,
    String backVideoPath,
    String uid,
    String date,
  ) async {
    try {
      log('Starting video save: uid=$uid, date=$date');

      // Back camera is REQUIRED
      final backFile = File(backVideoPath);
      if (!await backFile.exists()) {
        log('✗ ERROR: Back camera video file does not exist at: $backVideoPath');
        return null;
      }

      // Front camera is OPTIONAL
      File? frontFile;
      bool frontExists = false;
      if (frontVideoPath != null && frontVideoPath.isNotEmpty) {
        frontFile = File(frontVideoPath);
        frontExists = await frontFile.exists();
        if (!frontExists) {
          log('⚠ Front camera file missing at: $frontVideoPath (will save back only)');
        }
      } else {
        log('⚠ Front camera recording was not available (using back only)');
      }

      // Get destination directory
      final dir = await _getVideoDir(uid, date);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Save back video (REQUIRED)
      log('Saving BACK video...');
      final backDestPath = '${dir.path}/${timestamp}_back.mp4';
      final savedBack = await backFile.copy(backDestPath);

      if (!await savedBack.exists()) {
        log('✗ ERROR: Failed to save back video');
        return null;
      }
      final backSize = await savedBack.length();
      log('✓ Back video saved: $backDestPath (${(backSize / 1024 / 1024).toStringAsFixed(2)} MB)');

      // Save front video (OPTIONAL)
      String? frontDestPath;
      int frontSize = 0;
      if (frontFile != null && frontExists) {
        log('Saving FRONT video...');
        frontDestPath = '${dir.path}/${timestamp}_front.mp4';
        try {
          final savedFront = await frontFile.copy(frontDestPath);
          if (await savedFront.exists()) {
            frontSize = await savedFront.length();
            log('✓ Front video saved: $frontDestPath (${(frontSize / 1024 / 1024).toStringAsFixed(2)} MB)');
          } else {
            log('⚠ Front video file creation failed');
            frontDestPath = null;
          }
        } catch (e) {
          log('⚠ ERROR saving front video: $e');
          frontDestPath = null;
        }
      }

      log('═══════════════════════════════════════════════');
      log('✓ VIDEOS SAVED SUCCESSFULLY');
      log('  Back: ✓ (${(backSize / 1024 / 1024).toStringAsFixed(2)} MB)');
      log('  Front: ${frontDestPath != null ? '✓' : '✗ (not available)'}');
      log('═══════════════════════════════════════════════');

      return DualVideoData(
        timestamp: timestamp,
        frontPath: frontDestPath,
        backPath: backDestPath,
        frontSize: frontSize,
        backSize: backSize,
      );
    } catch (e) {
      log('✗ ERROR saving dual videos: $e');
      return null;
    }
  }

  /// Returns a list of [DualVideoData] for [uid] on [date]
  static Future<List<DualVideoData>> listDualVideos(
    String uid,
    String date,
  ) async {
    try {
      final dir = await _getVideoDir(uid, date);
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp4'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      // Group videos by timestamp (pair front and back)
      final videoMap = <int, DualVideoData>{};

      for (final file in files) {
        final name = file.uri.pathSegments.last; // e.g., "1234567890_front.mp4"
        final parts = name.replaceAll('.mp4', '').split('_');

        if (parts.length >= 2) {
          final timestamp = int.tryParse(parts[0]);
          final isFront = name.contains('_front');

          if (timestamp != null) {
            if (!videoMap.containsKey(timestamp)) {
              videoMap[timestamp] = DualVideoData(
                timestamp: timestamp,
                frontPath: null,
                backPath: null,
              );
            }

            if (isFront) {
              videoMap[timestamp] = DualVideoData(
                timestamp: timestamp,
                frontPath: file.path,
                backPath: videoMap[timestamp]?.backPath,
                frontSize: videoMap[timestamp]?.frontSize ?? 0,
                backSize: videoMap[timestamp]?.backSize ?? 0,
              );
            } else {
              videoMap[timestamp] = DualVideoData(
                timestamp: timestamp,
                frontPath: videoMap[timestamp]?.frontPath,
                backPath: file.path,
                frontSize: videoMap[timestamp]?.frontSize ?? 0,
                backSize: videoMap[timestamp]?.backSize ?? 0,
              );
            }
          }
        }
      }

      // Filter out incomplete pairs and sort by timestamp (newest first)
      return videoMap.values
          .where((v) => v.frontPath != null && v.backPath != null)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      log('Error listing dual videos: $e');
      return [];
    }
  }

  /// Saves single video (legacy method for backward compatibility)
  static Future<String?> saveVideo(
    String sourceFilePath,
    String uid,
    String date,
  ) async {
    try {
      log('Starting video save: source=$sourceFilePath, uid=$uid, date=$date');

      final src = File(sourceFilePath);
      final srcExists = await src.exists();
      if (!srcExists) {
        log('ERROR: Source video file does not exist: $sourceFilePath');
        return null;
      }

      final dir = await _getVideoDir(uid, date);
      final destPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';

      final destFile = await src.copy(destPath);
      final destExists = await destFile.exists();

      if (!destExists) {
        log('ERROR: Failed to copy video file to destination');
        return null;
      }

      final destSize = await destFile.length();
      log('✓ Video saved successfully');
      log('  Destination: $destPath');
      log('  Size: $destSize bytes');

      return destPath;
    } catch (e) {
      log('✗ ERROR saving video locally: $e');
      return null;
    }
  }

  /// Returns the list of local video file paths for [uid] on [date] (legacy)
  static Future<List<LocalVideoData>> listVideos(String uid, String date) async {
    try {
      final dir = await _getVideoDir(uid, date);
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp4'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      return files.map((f) {
        final name = f.uri.pathSegments.last.replaceAll('.mp4', '');
        final ts = int.tryParse(name);
        final time = ts != null
            ? _formatTime(DateTime.fromMillisecondsSinceEpoch(ts))
            : name;
        return LocalVideoData(f.path, time);
      }).toList();
    } catch (e) {
      log('Error listing videos: $e');
      return [];
    }
  }

  // ── Date folders ───────────────────────────────────────────────────────────

  /// Returns sorted list of date folder names that contain audio recordings.
  static Future<List<String>> listAudioDateFolders(String uid) async {
    return _listDateFolders('audios', uid);
  }

  /// Returns sorted list of date folder names that contain image recordings.
  static Future<List<String>> listImageDateFolders(String uid) async {
    return _listDateFolders('images', uid);
  }

  /// Returns sorted list of date folder names that contain video recordings.
  static Future<List<String>> listVideoDateFolders(String uid) async {
    return _listDateFolders('videos', uid);
  }

  static Future<List<String>> _listDateFolders(
      String type, String uid) async {
    try {
      final root = await getApplicationDocumentsDirectory();
      final userDir = Directory('${root.path}/recordings/$type/$uid');
      if (!await userDir.exists()) return [];
      return userDir
          .listSync()
          .whereType<Directory>()
          .map((d) => d.uri.pathSegments
              .where((s) => s.isNotEmpty)
              .last)
          .toList()
        ..sort((a, b) => b.compareTo(a)); // newest first
    } catch (e) {
      log('Error listing date folders: $e');
      return [];
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

/// Holds a local image file path and a display time string.
class LocalImageData {
  final String filePath;
  final String time;

  LocalImageData(this.filePath, this.time);
}

/// Holds a local video file path and a display time string.
class LocalVideoData {
  final String filePath;
  final String time;

  LocalVideoData(this.filePath, this.time);
}

/// Holds dual video recording data (front and back cameras)
class DualVideoData {
  final int timestamp;
  final String? frontPath;
  final String? backPath;
  final int frontSize;
  final int backSize;

  DualVideoData({
    required this.timestamp,
    required this.frontPath,
    required this.backPath,
    this.frontSize = 0,
    this.backSize = 0,
  });

  String get time {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get totalSize {
    final total = frontSize + backSize;
    if (total >= 1024 * 1024) {
      return '${(total / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (total >= 1024) {
      return '${(total / 1024).toStringAsFixed(1)} KB';
    } else {
      return '$total B';
    }
  }
}
