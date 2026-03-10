import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'view_recordings_history.dart';
import '../../services/background/background_services.dart';
import '../../services/background/storage_service/local_storage_service.dart';
import '../../utils/constants/colors.dart';
import '../../utils/helpers/helper_functions.dart';

/// Video Recording Screen with Camera and Microphone
/// 
/// Records video with audio from both front and back cameras.
/// All recordings are stored LOCALLY on the device only (no cloud upload).
/// Storage location: {app_documents}/recordings/videos/{phoneNumber}/{date}/
/// 
/// Features:
/// - Video recording with audio
/// - Front and back camera switching during recording
/// - Real-time timer display
/// - Local playback without network dependency
/// - Organized by date for easy access

class VideoRecordScreen extends StatefulWidget {
  const VideoRecordScreen({super.key});

  @override
  State<VideoRecordScreen> createState() => _VideoRecordScreenState();
}

class _VideoRecordScreenState extends State<VideoRecordScreen> {
  late CameraService _cameraService;
  late String _date;
  String? _uid;
  bool isRecording = false;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  Timer? _cameraSwitchTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _uid = prefs.getString('phoneNumber');
      _date = AppHelperFunctions.extractTodayDate();

      log('═══════════════════════════════════════════════');
      log('INITIALIZING VIDEO RECORD SCREEN');
      log('User ID (Phone): $_uid');
      log('Date: $_date');
      log('Storage location: /recordings/videos/$_uid/$_date/');
      log('═══════════════════════════════════════════════');

      await PermissionService.requestCameraPermission();
      await PermissionService.requestAudioPermission();
      
      _cameraService = CameraService();
      await _cameraService.initializeCameras();
      setState(() {});
    } catch (e) {
      log('✗ ERROR during initialization: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Initialization error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startRecording() async {
    if (_uid == null) {
      log("✗ ERROR: UID is null, cannot start recording");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID not found. Please restart the app.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      final videoPath = await _cameraService.startVideoRecording();
      
      if (videoPath == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start video recording.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      log("═══════════════════════════════════════════════");
      log("✓ VIDEO RECORDING STARTED WITH AUDIO");
      log("Temp file: $videoPath");
      log("Will save to: /recordings/videos/$_uid/$_date/");
      log("═══════════════════════════════════════════════");

      setState(() {
        isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Start timer to update UI
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });

      // Auto-switch camera every 8 seconds
      _cameraSwitchTimer = Timer.periodic(const Duration(seconds: 8), (timer) async {
        if (isRecording && mounted) {
          log('Switching camera...');
          await _cameraService.toggleCamera();
        }
      });
    } catch (e) {
      log("✗ ERROR starting video recording: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start recording: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    log("═══════════════════════════════════════════════");
    log("STOPPING VIDEO RECORDING");
    
    _recordingTimer?.cancel();
    _cameraSwitchTimer?.cancel();

    final XFile? videoFile = await _cameraService.stopVideoRecording();

    if (videoFile == null) {
      log("✗ ERROR: Failed to stop video recording");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to stop recording.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      setState(() => isRecording = false);
      return;
    }

    final file = File(videoFile.path);
    final exists = await file.exists();
    log("✓ Video file exists at ${videoFile.path}: $exists");
    
    if (!exists) {
      log("✗ ERROR: Recording file was not created!");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✗ Recording failed - file was not created.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      setState(() => isRecording = false);
      return;
    }

    final fileSize = await file.length();
    log("✓ Video file size: $fileSize bytes");

    setState(() => isRecording = false);

    // Save to device storage
    log("Attempting to save video to device storage...");
    await _saveVideoLocally(context, videoFile.path);
    log("═══════════════════════════════════════════════");
  }

  Future<void> _saveVideoLocally(BuildContext context, String videoPath) async {
    if (_uid == null) {
      log('✗ ERROR: UID is null, cannot save recording');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save recording: user ID not found.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (videoPath.isEmpty) {
      log('✗ ERROR: Video path is empty, nothing to save');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No video file was recorded.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    log('Saving video to device storage...');
    final saved = await LocalStorageService.saveVideo(videoPath, _uid!, _date);

    if (!mounted) return;

    if (saved == null) {
      log('✗ ERROR: Failed to save video to device');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save video to device.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      log('✓ Video successfully saved to: $saved');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✓ Video saved to device storage!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 10,
          margin: const EdgeInsets.fromLTRB(12.0, 60.0, 12.0, 200.0),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _cameraSwitchTimer?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(13.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Video Recording',
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Record video with camera and microphone to document unsafe situations.',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'Poppins',
                color: Colors.grey,
              ),
            ),
            const Divider(color: Color(0xFFEDEDED)),
            const SizedBox(height: 13),
            
            // View History Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: SvgPicture.asset(
                  'assets/icons/anonymous_recording_icon.svg',
                  width: 30,
                  height: 30,
                ),
                title: const Text(
                  'View Recordings',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Tap to see history'),
                onTap: () {
                  if (isRecording) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Stop recording first'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewRecordingsHistory(
                        userID: _uid,
                      ),
                    ),
                  );
                },
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF263238),
                  size: 15,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Camera Preview
            if (_cameraService.isInitialized)
              Expanded(
                child: Stack(
                  children: [
                    // Camera feed
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CameraPreview(_cameraService.cameraController),
                    ),
                    
                    // Recording indicator and timer
                    if (isRecording)
                      Positioned(
                        top: 15,
                        right: 15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 8,
                                height: 8,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDuration(_recordingDuration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Camera toggle button
                    Positioned(
                      bottom: 15,
                      left: 15,
                      child: FloatingActionButton.small(
                        heroTag: 'toggle_camera',
                        onPressed: isRecording ? () async {
                          await _cameraService.toggleCamera();
                          setState(() {});
                        } : null,
                        backgroundColor: Colors.black.withOpacity(0.6),
                        child: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Record/Stop Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (!isRecording) {
                    await _startRecording();
                  } else {
                    await _stopRecording();
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(0.5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRecording ? Icons.stop : Icons.fiber_manual_record,
                    color: isRecording ? Colors.black : Colors.red,
                    size: 24,
                  ),
                ),
                label: Text(
                  isRecording ? 'Stop Recording' : 'Start Recording',
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 20,
                  ),
                  backgroundColor: const Color(0xFF272727),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
