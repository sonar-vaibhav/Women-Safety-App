import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'view_recordings_history.dart';
import '../../services/background/background_services.dart';
import '../../services/background/storage_service/local_storage_service.dart';
import '../../utils/constants/colors.dart';
import '../../utils/helpers/helper_functions.dart';

/// Dual Camera Recording Screen
/// 
/// Records video from BOTH front and back cameras simultaneously with audio.
/// All recordings are stored LOCALLY on the device only (no cloud upload).
/// Storage location: {app_documents}/recordings/videos/{phoneNumber}/{date}/
/// 
/// Features:
/// - Simultaneous front + back video recording with audio
/// - Side-by-side camera preview
/// - Real-time timer display
/// - Local storage as video pairs
/// - Organized by date for easy access

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  late CameraService _cameraService;
  late String _date;
  String? _uid;
  bool isRecording = false;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

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
      log('INITIALIZING DUAL CAMERA RECORD SCREEN');
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
      final result = await _cameraService.startDualVideoRecording();
      
      // Back camera is REQUIRED, front is optional
      if (result.error != null || result.backPath == null) {
        if (!mounted) return;
        final errorMsg = result.error ?? 'Failed to start back camera recording';
        log("✗ START RECORDING ERROR: $errorMsg");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording failed: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      log("═══════════════════════════════════════════════");
      log("✓ VIDEO RECORDING STARTED");
      log("Back camera: ${result.backPath} (required)");
      log("Front camera: ${result.frontPath != null ? "available" : "not available"}");
      log("Will save to: /recordings/videos/$_uid/$_date/");
      log("═══════════════════════════════════════════════");

      setState(() {
        isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Start timer to update UI
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration += const Duration(seconds: 1);
          });
        }
      });
    } catch (e) {
      log("✗ EXCEPTION in startRecording: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    log("═══════════════════════════════════════════════");
    log("STOPPING VIDEO RECORDING");
    
    _recordingTimer?.cancel();

    final result = await _cameraService.stopDualVideoRecording();

    // Back camera is REQUIRED
    if (result.error != null || result.back == null) {
      log("✗ STOP RECORDING ERROR: ${result.error}");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save recording: ${result.error ?? "Unknown error"}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      setState(() => isRecording = false);
      return;
    }

    final backFile = File(result.back!.path);
    final frontFile = result.front != null ? File(result.front!.path) : null;
    
    final backExists = await backFile.exists();
    final frontExists = frontFile != null ? await frontFile.exists() : false;
    
    log("✓ Video file verification:");
    log("  Back camera: ${backExists ? '✓ exists' : '✗ missing'}");
    log("  Front camera: ${frontExists ? '✓ exists' : '✗ not recorded'}");
    
    if (!backExists) {
      log("✗ ERROR: Back camera video file was not created!");
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

    // At least back camera succeeded
    if (backExists && backFile != null) {
      final backSize = await backFile.length();
      log("✓ Back video size: ${(backSize / 1024 / 1024).toStringAsFixed(2)} MB");
    }
    
    if (frontExists && frontFile != null) {
      final frontSize = await frontFile.length();
      log("✓ Front video size: ${(frontSize / 1024 / 1024).toStringAsFixed(2)} MB");
    }

    setState(() => isRecording = false);

    // Save to device storage (back is required, front is optional)
    log("Saving videos to device storage...");
    await _saveDualVideosLocally(
      context,
      backPath: result.back!.path,
      frontPath: result.front?.path, // Optional - null if not recorded
    );
    log("═══════════════════════════════════════════════");
  }

  Future<void> _saveDualVideosLocally(
    BuildContext context, {
    required String backPath,
    String? frontPath, // Optional - null if front camera not used
  }) async {
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

    if (backPath.isEmpty) {
      log('✗ ERROR: Back camera path is empty, cannot save recording');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No video files were recorded (back camera failed).'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    log('Saving videos:');
    log('  Back: $backPath');
    log('  Front: ${frontPath != null ? frontPath : "not recorded"}');

    log('Saving to device storage...');
    final saved = await LocalStorageService.saveDualVideos(
      frontPath,
      backPath,
      _uid!,
      _date,
    );

    if (!mounted) return;

    if (saved == null) {
      log('✗ ERROR: Failed to save videos to device');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save videos to device.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      log('✓ Dual videos successfully saved');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✓ Dual videos saved to device storage!'),
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
              'Dual Camera Recording',
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Record from both front AND back cameras simultaneously with audio.',
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
            
            // Dual Camera Preview (Side-by-side)
            if (_cameraService.isInitialized)
              Expanded(
                child: Stack(
                  children: [
                    // Side-by-side camera feeds
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Row(
                        children: [
                          // Front Camera (Left)
                          Expanded(
                            child: Stack(
                              children: [
                                CameraPreview(
                                  _cameraService.frontCameraController,
                                ),
                                // Front label
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'FRONT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Divider
                          Container(
                            width: 2,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          // Back Camera (Right)
                          Expanded(
                            child: Stack(
                              children: [
                                CameraPreview(
                                  _cameraService.backCameraController,
                                ),
                                // Back label
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'BACK',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
