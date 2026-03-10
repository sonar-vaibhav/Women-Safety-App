import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

/// Simple screen to test ngrok API connection
class SimpleApiTest extends StatefulWidget {
  const SimpleApiTest({super.key});

  @override
  State<SimpleApiTest> createState() => _SimpleApiTestState();
}

class _SimpleApiTestState extends State<SimpleApiTest> {
  String _result = '';
  bool _isLoading = false;

  Future<void> _testAPI() async {
    setState(() {
      _isLoading = true;
      _result = 'Sending test request...\n';
    });

    try {
      final dio = Dio();
      
      // Add ngrok header
      dio.options.headers['ngrok-skip-browser-warning'] = 'true';
      
      final url = '${ApiConfig.baseUrl}/api/users/register';
      
      setState(() {
        _result += 'URL: $url\n\n';
        _result += 'Sending POST request...\n';
      });

      // Send a simple test request
      final response = await dio.post(
        url,
        data: {
          'name': 'Test User',
          'phone': '+1234567890',
          'email': 'test@example.com',
        },
      );

      setState(() {
        _result += '\n✅ SUCCESS!\n\n';
        _result += 'Status Code: ${response.statusCode}\n';
        _result += 'Response:\n${response.data}\n';
      });

      print('✅ API Test Success: ${response.statusCode}');
      print('Response: ${response.data}');

    } catch (e) {
      setState(() {
        _result += '\n❌ ERROR!\n\n';
        _result += 'Error: $e\n';
      });

      print('❌ API Test Failed: $e');

      if (e is DioException) {
        setState(() {
          _result += '\nDetails:\n';
          _result += 'Type: ${e.type}\n';
          _result += 'Message: ${e.message}\n';
          if (e.response != null) {
            _result += 'Status: ${e.response?.statusCode}\n';
            _result += 'Data: ${e.response?.data}\n';
          }
        });
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backend URL:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      ApiConfig.baseUrl,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testAPI,
              icon: const Icon(Icons.send),
              label: const Text('Send Test Request to Backend'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_result.isNotEmpty)
              Expanded(
                child: Card(
                  color: Colors.black87,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      _result,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
