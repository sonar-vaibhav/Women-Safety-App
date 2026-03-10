    import 'package:flutter/material.dart';
    import 'package:toastification/toastification.dart';
    import '../services/backend/backend_test_helper.dart';
    import '../services/backend/backend_integration_service.dart';
    import '../services/backend/user_service.dart';
    import 'test_panic_video_screen.dart';

    /// Test screen for backend integration
    /// Add this to your app to test backend without shake detection
    class BackendTestScreen extends StatefulWidget {
    const BackendTestScreen({super.key});

    @override
    State<BackendTestScreen> createState() => _BackendTestScreenState();
    }

    class _BackendTestScreenState extends State<BackendTestScreen> {
    final BackendTestHelper _tester = BackendTestHelper();
    final BackendIntegrationService _service = BackendIntegrationService();
    final BackendUserService _userService = BackendUserService();
    
    bool _isLoading = false;
    String? _userId;
    String? _caseId;

    @override
    void initState() {
        super.initState();
        _loadStatus();
    }

    Future<void> _loadStatus() async {
        final userId = await _service.getUserId();
        final caseId = await _service.getCaseId();
        setState(() {
        _userId = userId;
        _caseId = caseId;
        });
    }

    Future<void> _testUserRegistration() async {
        setState(() => _isLoading = true);
        
        final userId = await _tester.testUserRegistration(
        name: 'Test User',
        phone: '+1234567890',
        email: 'test@example.com',
        );

        setState(() => _isLoading = false);

        if (mounted) {
        if (userId != null) {
            _showToast('User registered: $userId', ToastificationType.success);
            await _loadStatus();
        } else {
            _showToast('User registration failed', ToastificationType.error);
        }
        }
    }

    Future<void> _testAutoRegistration() async {
        setState(() => _isLoading = true);
        
        final userId = await _service.autoRegisterCurrentUser();

        setState(() => _isLoading = false);

        if (mounted) {
        if (userId != null) {
            _showToast('Auto-registered: $userId', ToastificationType.success);
            await _loadStatus();
        } else {
            _showToast('Already registered or no user logged in', ToastificationType.info);
            await _loadStatus();
        }
        }
    }

    Future<void> _checkRegistrationStatus() async {
        await _userService.checkRegistrationStatus();
        _showToast('Check debug logs for status', ToastificationType.info);
    }

    Future<void> _clearBackendUserId() async {
        await _userService.clearUserId();
        await _loadStatus();
        _showToast('Backend User ID cleared', ToastificationType.success);
    }

    Future<void> _testEmergencyCreation() async {
        if (_userId == null) {
        _showToast('Register user first', ToastificationType.warning);
        return;
        }

        setState(() => _isLoading = true);
        
        final caseId = await _tester.testEmergencyCreation();

        setState(() => _isLoading = false);

        if (mounted) {
        if (caseId != null) {
            _showToast('Emergency case created: $caseId', ToastificationType.success);
            await _loadStatus();
        } else {
            _showToast('Emergency creation failed', ToastificationType.error);
        }
        }
    }

    Future<void> _testCloseCase() async {
        if (_caseId == null) {
        _showToast('No active case', ToastificationType.warning);
        return;
        }

        setState(() => _isLoading = true);
        
        final success = await _service.closeEmergency();

        setState(() => _isLoading = false);

        if (mounted) {
        if (success) {
            _showToast('Case closed successfully', ToastificationType.success);
            await _loadStatus();
        } else {
            _showToast('Failed to close case', ToastificationType.error);
        }
        }
    }

    void _showToast(String message, ToastificationType type) {
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
            title: const Text('Backend Integration Test'),
            backgroundColor: Colors.purple,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // Status Card
                    Card(
                        color: Colors.purple.shade50,
                        child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            const Text(
                                'Current Status',
                                style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                ),
                            ),
                            const SizedBox(height: 12),
                            _buildStatusRow(
                                'User ID',
                                _userId ?? 'Not registered',
                                _userId != null,
                            ),
                            const SizedBox(height: 8),
                            _buildStatusRow(
                                'Active Case ID',
                                _caseId ?? 'No active case',
                                _caseId != null,
                            ),
                            ],
                        ),
                        ),
                    ),
                    const SizedBox(height: 24),

                    // Instructions
                    const Text(
                        'Test Steps:',
                        style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        '0. Auto-register current logged-in user\n'
                        '1. Register test user with backend\n'
                        '2. Create emergency case\n'
                        '3. (Optional) Upload evidence\n'
                        '4. Close emergency case',
                        style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // Test Buttons
                    ElevatedButton.icon(
                        onPressed: _userId == null ? _testAutoRegistration : null,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Auto-Register Current User'),
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        disabledBackgroundColor: Colors.grey,
                        ),
                    ),
                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                        onPressed: _userId == null ? _testUserRegistration : null,
                        icon: const Icon(Icons.person_add),
                        label: const Text('1. Register Test User'),
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        disabledBackgroundColor: Colors.grey,
                        ),
                    ),
                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                        onPressed: _userId != null && _caseId == null
                            ? _testEmergencyCreation
                            : null,
                        icon: const Icon(Icons.emergency),
                        label: const Text('2. Create Emergency Case'),
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        disabledBackgroundColor: Colors.grey,
                        ),
                    ),
                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                        onPressed: _caseId != null ? _testCloseCase : null,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('3. Close Emergency Case'),
                        style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        disabledBackgroundColor: Colors.grey,
                        ),
                    ),
                    const SizedBox(height: 24),

                    // Panic Video Test Button
                    ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TestPanicVideoScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.videocam),
                        label: const Text('🎥 Test Panic Video Recording'),
                        style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        ),
                    ),
                    const SizedBox(height: 24),

                    // Refresh Button
                    OutlinedButton.icon(
                        onPressed: _loadStatus,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Status'),
                    ),
                    const SizedBox(height: 12),

                    // Debug Buttons
                    OutlinedButton.icon(
                        onPressed: _checkRegistrationStatus,
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Check Registration Status'),
                        style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        ),
                    ),
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                        onPressed: _clearBackendUserId,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear Backend User ID'),
                        style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        ),
                    ),
                    const SizedBox(height: 24),

                    // Info Card
                    Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Row(
                                children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                const Text(
                                    'Note',
                                    style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    ),
                                ),
                                ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                                'This screen tests the backend API integration. '
                                'Make sure your backend server is running and the '
                                'ngrok URL is updated in api_config.dart',
                                style: TextStyle(fontSize: 12),
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

    Widget _buildStatusRow(String label, String value, bool isActive) {
        return Row(
        children: [
            Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? Colors.green : Colors.grey,
            size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                    label,
                    style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    ),
                ),
                Text(
                    value,
                    style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    ),
                ),
                ],
            ),
            ),
        ],
        );
    }
    }
