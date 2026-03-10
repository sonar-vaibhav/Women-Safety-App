import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Screen to update ngrok URL without rebuilding app
class UpdateNgrokUrlScreen extends StatefulWidget {
  const UpdateNgrokUrlScreen({Key? key}) : super(key: key);

  @override
  State<UpdateNgrokUrlScreen> createState() => _UpdateNgrokUrlScreenState();
}

class _UpdateNgrokUrlScreenState extends State<UpdateNgrokUrlScreen> {
  final _urlController = TextEditingController();
  String _currentUrl = 'https://ba8d-2409-40c2-501c-8096-5ceb-6398-3d34-37cd.ngrok-free.app';
  String _message = '';

  @override
  void initState() {
    super.initState();
    _urlController.text = _currentUrl;
  }

  void _updateUrl() {
    final newUrl = _urlController.text.trim();
    
    if (newUrl.isEmpty) {
      setState(() {
        _message = '❌ URL cannot be empty';
      });
      return;
    }

    if (!newUrl.startsWith('https://')) {
      setState(() {
        _message = '❌ URL must start with https://';
      });
      return;
    }

    if (!newUrl.contains('ngrok')) {
      setState(() {
        _message = '⚠️ Warning: This doesn\'t look like an ngrok URL';
      });
    }

    setState(() {
      _currentUrl = newUrl;
      _message = '✅ URL updated!\n\nNOTE: You need to update lib/config/api_config.dart\nand restart the app for changes to take effect.';
    });
  }

  void _copyInstructions() {
    final instructions = '''
// Update this file: lib/config/api_config.dart

class ApiConfig {
  static const String baseUrl = '$_currentUrl';
  
  // ... rest of the file stays the same
}

Then restart the app: flutter run
''';
    
    Clipboard.setData(ClipboardData(text: instructions));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Instructions copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update ngrok URL'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '⚠️ ngrok URL Expired',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your ngrok tunnel is offline. Follow these steps:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildStep(
              '1',
              'Restart ngrok on your backend server',
              'ngrok http 8000',
              true,
            ),
            const SizedBox(height: 16),
            _buildStep(
              '2',
              'Copy the new ngrok URL',
              'Example: https://xxxx-xxxx.ngrok-free.app',
              false,
            ),
            const SizedBox(height: 16),
            _buildStep(
              '3',
              'Paste the new URL below',
              '',
              false,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'New ngrok URL',
                hintText: 'https://xxxx-xxxx.ngrok-free.app',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _urlController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Update URL',
                style: TextStyle(fontSize: 18),
              ),
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _message.contains('✅')
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _message.contains('✅')
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.contains('✅')
                        ? Colors.green.shade900
                        : Colors.orange.shade900,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildStep(
              '4',
              'Update the code file',
              'Tap button below to copy instructions',
              false,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _copyInstructions,
              icon: const Icon(Icons.copy),
              label: const Text('Copy Update Instructions'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current URL in code:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'https://ba8d-2409-40c2-501c-8096-5ceb-6398-3d34-37cd.ngrok-free.app',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'File to update:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'lib/config/api_config.dart',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.blue,
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

  Widget _buildStep(String number, String title, String subtitle, bool isCommand) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCommand ? Colors.black87 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: isCommand ? 'monospace' : null,
                        fontSize: 12,
                        color: isCommand ? Colors.greenAccent : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
