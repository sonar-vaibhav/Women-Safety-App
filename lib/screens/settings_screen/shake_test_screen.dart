import 'package:flutter/material.dart';
import 'package:shake_detector/shake_detector.dart';
import '../../services/background/background_services.dart';
import '../../utils/logging/logger.dart';

/// Test screen to verify shake detection is working
/// Add this to your settings menu for easy testing
class ShakeTestScreen extends StatefulWidget {
  const ShakeTestScreen({super.key});

  @override
  State<ShakeTestScreen> createState() => _ShakeTestScreenState();
}

class _ShakeTestScreenState extends State<ShakeTestScreen> {
  int _shakeCount = 0;
  bool _isServiceRunning = false;
  bool _isListening = false;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
  }

  Future<void> _checkServiceStatus() async {
    final isRunning = await ShakeBackgroundService.isServiceRunning();
    setState(() {
      _isServiceRunning = isRunning;
    });
    _addLog('Service status: ${isRunning ? "Running ✅" : "Stopped ❌"}');
  }

  void _startListening() {
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _shakeCount = 0;
    });

    _addLog('Started listening for shakes...');

    ShakeDetector.autoStart(
      onShake: () {
        setState(() {
          _shakeCount++;
        });
        _addLog('Shake detected! Count: $_shakeCount');

        if (_shakeCount >= 3) {
          _addLog('🚨 3 shakes detected! This would trigger SOS in production.');
          _showSuccessDialog();
        }
      },
      shakeThresholdGravity: 2.7,
    );
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
      _shakeCount = 0;
    });
    _addLog('Stopped listening');
    ShakeDetector.stopListening();
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toString().substring(11, 19)} - $message');
      if (_logs.length > 20) {
        _logs.removeLast();
      }
    });
    logger.d(message);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Success!'),
        content: const Text(
          'Shake detection is working correctly!\n\n'
          'In production, this would trigger an SOS alert to your emergency contacts.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _stopListening();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_isListening) {
      ShakeDetector.stopListening();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shake Detection Test'),
        backgroundColor: const Color(0xFFD20452),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Service Status Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isServiceRunning ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isServiceRunning ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isServiceRunning ? Icons.check_circle : Icons.error,
                    color: _isServiceRunning ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Background Service',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isServiceRunning ? Colors.green[900] : Colors.red[900],
                          ),
                        ),
                        Text(
                          _isServiceRunning ? 'Running' : 'Not Running',
                          style: TextStyle(
                            fontSize: 14,
                            color: _isServiceRunning ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _checkServiceStatus,
                  ),
                ],
              ),
            ),

            // Shake Counter
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD20452),
                    const Color(0xFFEC4A46),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Shake Count',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_shakeCount / 3',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isListening
                        ? 'Shake your phone!'
                        : 'Press Start to begin',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Control Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isListening ? null : _startListening,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Test'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isListening ? _stopListening : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Test'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Press Start, then shake your phone 3 times quickly',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Logs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Activity Log',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _logs.clear();
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'No activity yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              _logs[index],
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
