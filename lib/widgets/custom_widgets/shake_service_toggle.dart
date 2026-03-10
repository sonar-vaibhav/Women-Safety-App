import 'package:flutter/material.dart';
import '../../services/background/background_services.dart';
import '../../utils/logging/logger.dart';

class ShakeServiceToggle extends StatefulWidget {
  const ShakeServiceToggle({super.key});

  @override
  State<ShakeServiceToggle> createState() => _ShakeServiceToggleState();
}

class _ShakeServiceToggleState extends State<ShakeServiceToggle> {
  bool _isServiceRunning = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
  }

  Future<void> _checkServiceStatus() async {
    try {
      final isRunning = await ShakeBackgroundService.isServiceRunning();
      setState(() {
        _isServiceRunning = isRunning;
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Error checking service status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleService(bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (value) {
        await ShakeBackgroundService.startService();
        logger.i('Shake service started by user');
        _showSnackBar('Background protection enabled', Colors.green);
      } else {
        await ShakeBackgroundService.stopService();
        logger.i('Shake service stopped by user');
        _showSnackBar('Background protection disabled', Colors.orange);
      }

      setState(() {
        _isServiceRunning = value;
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Error toggling service: $e');
      _showSnackBar('Error: ${e.toString()}', Colors.red);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isServiceRunning 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isServiceRunning ? Icons.shield : Icons.shield_outlined,
                    color: _isServiceRunning ? Colors.green : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Background Protection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isServiceRunning 
                            ? 'Active - Shake 3 times for SOS'
                            : 'Disabled',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isServiceRunning ? Colors.green : Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: _isServiceRunning,
                    onChanged: _toggleService,
                    activeColor: Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Works even when app is closed or phone is locked. A notification will show when active.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[900],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
