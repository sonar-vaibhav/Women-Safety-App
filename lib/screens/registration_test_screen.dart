import 'package:flutter/material.dart';
import '../services/backend/user_service.dart';

/// Test screen to verify registration API
class RegistrationTestScreen extends StatefulWidget {
  const RegistrationTestScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationTestScreen> createState() => _RegistrationTestScreenState();
}

class _RegistrationTestScreenState extends State<RegistrationTestScreen> {
  final _userService = BackendUserService();
  String _result = 'Tap button to test registration';
  bool _isLoading = false;

  Future<void> _testRegistration() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing registration...';
    });

    try {
      // Test data matching your example format
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testData = {
        'name': 'Anita Sharma 123',
        'phone': '9999912345',
        'email': 'anita.23sharma@test.com',
        'device_id': 'android-safesphere-$timestamp',
      };

      debugPrint('🧪 Testing registration with data:');
      debugPrint('   Name: ${testData['name']}');
      debugPrint('   Phone: ${testData['phone']}');
      debugPrint('   Email: ${testData['email']}');
      debugPrint('   Device ID: ${testData['device_id']}');

      final user = await _userService.registerUser(
        name: testData['name']!,
        phone: testData['phone']!,
        email: testData['email']!,
        deviceId: testData['device_id']!,
      );

      if (user != null) {
        setState(() {
          _result = '✅ SUCCESS!\n\n'
              'User ID: ${user.id}\n'
              'Name: ${user.name}\n'
              'Phone: ${user.phone}\n'
              'Email: ${user.email}\n'
              'Device ID: ${user.deviceId}';
        });
      } else {
        setState(() {
          _result = '❌ FAILED\n\nRegistration returned null.\nCheck console logs for details.';
        });
      }
    } catch (e) {
      setState(() {
        _result = '❌ ERROR\n\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Test'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Backend Registration Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This will test the /api/users/register endpoint',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _testRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Test Registration',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Check console logs for detailed request/response data',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
