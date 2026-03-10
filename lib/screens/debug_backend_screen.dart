import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/backend/backend_integration_service.dart';
import '../services/backend/api_service.dart';
import '../config/api_config.dart';

/// Debug screen to test backend connection step by step
class DebugBackendScreen extends StatefulWidget {
  const DebugBackendScreen({super.key});

  @override
  State<DebugBackendScreen> createState() => _DebugBackendScreenState();
}

class _DebugBackendScreenState extends State<DebugBackendScreen> {
  final BackendIntegrationService _backendService = BackendIntegrationService();
  String _log = '';
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _log += '\n$message';
    });
    print(message);
  }

  Future<void> _checkUserRegistration() async {
    setState(() {
      _isLoading = true;
      _log = '';
    });

    _addLog('🔍 Checking user registration...');
    
    final userId = await _backendService.getUserId();
    
    if (userId != null) {
      _addLog('✅ User IS registered');
      _addLog('   User ID: $userId');
    } else {
      _addLog('❌ User NOT registered');
      _addLog('   You need to register first!');
    }

    // Check phone number in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber');
    _addLog('\n📱 Phone in SharedPreferences: ${phoneNumber ?? "NOT FOUND"}');

    setState(() => _isLoading = false);
  }

  Future<void> _registerUser() async {
    setState(() {
      _isLoading = true;
      _log = '';
    });

    _addLog('📝 Registering user with backend...');
    _addLog('   URL: ${ApiConfig.baseUrl}');
    _addLog('   Endpoint: ${ApiConfig.registerUser}');

    // Get phone from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber');

    if (phoneNumber == null) {
      _addLog('❌ No phone number in SharedPreferences');
      _addLog('   Please login with Firebase first');
      setState(() => _isLoading = false);
      return;
    }

    _addLog('   Phone: $phoneNumber');

    try {
      final userId = await _backendService.registerUser(
        name: 'Test User',
        phone: phoneNumber,
        email: 'test@example.com',
      );

      if (userId != null) {
        _addLog('✅ User registered successfully!');
        _addLog('   User ID: $userId');
        _addLog('   Saved to SharedPreferences');
      } else {
        _addLog('❌ Registration failed');
        _addLog('   Check backend logs');
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testEmergencyCase() async {
    setState(() {
      _isLoading = true;
      _log = '';
    });

    _addLog('🚨 Testing emergency case creation...');

    final userId = await _backendService.getUserId();
    if (userId == null) {
      _addLog('❌ User not registered');
      _addLog('   Register user first!');
      setState(() => _isLoading = false);
      return;
    }

    _addLog('✅ User ID found: $userId');
    _addLog('📤 Creating emergency case...');
    _addLog('   URL: ${ApiConfig.baseUrl}${ApiConfig.startEmergency}');

    try {
      final caseId = await _backendService.handleSOSTrigger(
        latitude: 19.9975,
        longitude: 73.7898,
      );

      if (caseId != null) {
        _addLog('✅ Emergency case created!');
        _addLog('   Case ID: $caseId');
        _addLog('   Saved to SharedPreferences');
      } else {
        _addLog('❌ Case creation failed');
        _addLog('   Check backend logs');
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testDirectAPI() async {
    setState(() {
      _isLoading = true;
      _log = '';
    });

    _addLog('🌐 Testing direct API connection...');
    _addLog('   URL: ${ApiConfig.baseUrl}');

    try {
      final apiService = ApiService();
      _addLog('📤 Sending GET request...');
      
      final response = await apiService.get('/');
      
      _addLog('✅ Backend is reachable!');
      _addLog('   Status: ${response.statusCode}');
    } catch (e) {
      _addLog('❌ Backend NOT reachable');
      _addLog('   Error: $e');
      _addLog('\n🔧 Troubleshooting:');
      _addLog('   1. Is Django running?');
      _addLog('   2. Is ngrok running?');
      _addLog('   3. Is URL correct in api_config.dart?');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Debug'),
        backgroundColor: Colors.red,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Config Info
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Configuration',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Base URL:\n${ApiConfig.baseUrl}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Test Buttons
                  ElevatedButton.icon(
                    onPressed: _testDirectAPI,
                    icon: const Icon(Icons.wifi),
                    label: const Text('1. Test Backend Connection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _checkUserRegistration,
                    icon: const Icon(Icons.person_search),
                    label: const Text('2. Check User Registration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _registerUser,
                    icon: const Icon(Icons.person_add),
                    label: const Text('3. Register User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _testEmergencyCase,
                    icon: const Icon(Icons.emergency),
                    label: const Text('4. Test Emergency Case'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Log Output
                  if (_log.isNotEmpty)
                    Card(
                      color: Colors.black87,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          _log,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
