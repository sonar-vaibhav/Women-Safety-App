import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../services/panic_video_service.dart';
import '../services/backend/backend_integration_service.dart';
import '../utils/logging/logger.dart';

/// Test screen for panic video recording feature
class TestPanicVideoScreen extends StatefulWidget {
  const TestPanicVideoScreen({super.key});

  @override
  State<TestPanicVideoScreen> createState() => _TestPanicVideoScreenState();
}

class _TestPanicVideoScreenState extends State<TestPanicVideoScreen> {
  final PanicVideoService _videoService = PanicVideoService();
  final BackendIntegrationService _backendService = BackendIntegrationService();
  
  bool _isRecording = false;
  String? _caseId;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadIds();
  }

  Future<void> _loadIds() async {
    final userId = await _backendService.getUserId();
    final caseId = await _backendService.getCaseId();
    
    setState(() {
      _userId = userId;
      _caseId = caseId;
    });

    logger.i('User ID: $_userId');
    logger.i('Case ID: $_caseId');
  }

  Future<void> _testCreateCase() async {
    try {
      _showToast('Creating emergency case...', type: ToastificationType.info);
      
      final caseId = await _backendService.handleSOSTrigger(
        latitude: 28.6139, // Example: New Delhi
        longitude: 77.2090,
      );

      if (caseId != null) {
        setState(() => _caseId = caseId);
        _showToast('Case created: $caseId', type: ToastificationType.success);
        logger.i('✅ Case created: $caseId');
      } else {
        _showToast('Failed to create case', type: ToastificationType.error);
        logger.e('❌ Failed to create case');
      }
    } catch (e) {
      _showToast('Error: $e', type: ToastificationType.error);
      logger.e('❌ Error: $e');
    }
  }

  Future<void> _testStartRecording() async {
    try {
      if (_caseId == null) {
        _showToast('Create a case first!', type: ToastificationType.warning);
        return;
      }

      setState(() => _isRecording = true);
      _showToast('Starting 30-second recording...', type: ToastificationType.info);

      final videoPath = await _videoService.startPanicRecording();

      if (videoPath != null) {
        _showToast('Recording started!', type: ToastificationType.success);
        logger.i('✅ Recording started: $videoPath');
        
        // Wait for recording to complete (30 seconds)
        await Future.delayed(const Duration(seconds: 31));
        
        setState(() => _isRecording = false);
        _showToast('Recording completed and uploaded!', type: ToastificationType.success);
      } else {
        setState(() => _isRecording = false);
        _showToast('Failed to start recording', type: ToastificationType.error);
      }
    } catch (e) {
      setState(() => _isRecording = false);
      _showToast('Error: $e', type: ToastificationType.error);
      logger.e('❌ Error: $e');
    }
  }

  Future<void> _testCancelRecording() async {
    await _videoService.cancelRecording();
    setState(() => _isRecording = false);
    _showToast('Recording cancelled', type: ToastificationType.info);
  }

  void _showToast(String message, {ToastificationType type = ToastificationType.info}) {
    toastification.show(
      context: context,
      title: Text(message),
      type: type,
      autoCloseDuration: const Duration(seconds: 3),
      style: ToastificationStyle.fillColored,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Panic Video Recording'),
        backgroundColor: const Color(0xFFD20452),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusRow('User ID', _userId ?? 'Not loaded'),
                    const SizedBox(height: 8),
                    _buildStatusRow('Case ID', _caseId ?? 'No active case'),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      'Recording',
                      _isRecording ? '🔴 Recording...' : '⚪ Not recording',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Instructions
            const Card(
              color: Color(0xFFFFF3E0),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Test Instructions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Create an emergency case first'),
                    Text('2. Start 30-second recording'),
                    Text('3. Video will auto-upload after 30 seconds'),
                    Text('4. Check logs for details'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            ElevatedButton.icon(
              onPressed: _caseId == null ? _testCreateCase : null,
              icon: const Icon(Icons.emergency),
              label: const Text('1. Create Emergency Case'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD20452),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: !_isRecording && _caseId != null ? _testStartRecording : null,
              icon: const Icon(Icons.videocam),
              label: const Text('2. Start 30-Second Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),

            if (_isRecording)
              ElevatedButton.icon(
                onPressed: _testCancelRecording,
                icon: const Icon(Icons.stop),
                label: const Text('Cancel Recording'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

            const Spacer(),

            // Info
            const Card(
              color: Color(0xFFE3F2FD),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(height: 8),
                    Text(
                      'Recording uses FRONT CAMERA only',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Video is saved locally and uploaded to backend',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: value.contains('Not') || value.contains('No') 
                  ? Colors.grey 
                  : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
