# Backend Integration Guide

## Overview
This guide shows how to integrate the SafeSphere backend with your Flutter app.

## Setup

### 1. Update Base URL
Edit `lib/config/api_config.dart` and update the `baseUrl` with your current ngrok URL:

```dart
static const String baseUrl = 'https://your-ngrok-url.ngrok-free.app';
```

### 2. User Registration Flow

After Firebase authentication, register the user with the backend:

```dart
import 'package:safeguardher_flutter_app/services/backend/backend_integration_service.dart';

final backendService = BackendIntegrationService();

// After Firebase sign-in
final userId = await backendService.registerUser(
  name: 'John Doe',
  phone: '+1234567890',
  email: 'john@example.com',
  deviceId: 'optional-device-id',
);

if (userId != null) {
  print('User registered with backend: $userId');
}
```

### 3. Integration with Shake Service

Modify your `shake_background_service.dart` to create emergency cases:

```dart
import 'package:safeguardher_flutter_app/services/backend/backend_integration_service.dart';

// In your _triggerSOS method:
Future<void> _triggerSOS(ServiceInstance service) async {
  final backendService = BackendIntegrationService();
  
  // Get current location
  final position = await Geolocator.getCurrentPosition();
  
  // Create emergency case
  final caseId = await backendService.handleSOSTrigger(
    latitude: position.latitude,
    longitude: position.longitude,
  );
  
  if (caseId != null) {
    logger.i('✅ Emergency case created: $caseId');
    
    // Start recording (your existing code)
    await _startRecording();
    
    // ... rest of your SOS logic
  } else {
    logger.e('❌ Failed to create emergency case');
  }
}
```

### 4. Upload Evidence After Recording

After recording completes, upload the files:

```dart
// After recording stops
Future<void> _uploadRecordings(String videoPath, String audioPath) async {
  final backendService = BackendIntegrationService();
  final position = await Geolocator.getCurrentPosition();
  
  final success = await backendService.uploadRecordedEvidence(
    videoPath: videoPath,
    audioPath: audioPath,
    latitude: position.latitude,
    longitude: position.longitude,
  );
  
  if (success) {
    logger.i('✅ Evidence uploaded successfully');
  } else {
    logger.e('❌ Evidence upload failed');
  }
}
```

### 5. Close Emergency Case

When the emergency is resolved:

```dart
final backendService = BackendIntegrationService();

// Mark as resolved
await backendService.resolveEmergency();

// Or close completely
await backendService.closeEmergency();
```

## Complete SOS Flow Example

```dart
Future<void> handleCompleteSOSFlow() async {
  final backendService = BackendIntegrationService();
  
  try {
    // 1. Get location
    final position = await Geolocator.getCurrentPosition();
    
    // 2. Create emergency case
    final caseId = await backendService.handleSOSTrigger(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    
    if (caseId == null) {
      throw Exception('Failed to create emergency case');
    }
    
    // 3. Start recording
    await cameraService.startRecording();
    
    // 4. Wait for recording duration (e.g., 30 seconds)
    await Future.delayed(Duration(seconds: 30));
    
    // 5. Stop recording
    final videoPath = await cameraService.stopRecording();
    final audioPath = await audioRecorder.stopRecording();
    
    // 6. Upload evidence
    final uploaded = await backendService.uploadRecordedEvidence(
      videoPath: videoPath,
      audioPath: audioPath,
      latitude: position.latitude,
      longitude: position.longitude,
    );
    
    if (uploaded) {
      print('✅ Complete SOS flow successful');
    }
    
  } catch (e) {
    print('❌ Error in SOS flow: $e');
  }
}
```

## Error Handling

All services include error handling and return `null` or `false` on failure. Always check return values:

```dart
final caseId = await backendService.handleSOSTrigger(...);
if (caseId == null) {
  // Show error toast
  Toastification.show(
    context: context,
    title: Text('Failed to create emergency case'),
    type: ToastificationType.error,
  );
  return;
}
```

## Testing

### Test User Registration
```dart
final userId = await backendService.registerUser(
  name: 'Test User',
  phone: '+1234567890',
  email: 'test@example.com',
);
print('User ID: $userId');
```

### Test Emergency Creation
```dart
final caseId = await backendService.handleSOSTrigger(
  latitude: 19.9975,
  longitude: 73.7898,
);
print('Case ID: $caseId');
```

### Test Evidence Upload
```dart
final success = await backendService.uploadRecordedEvidence(
  videoPath: '/path/to/video.mp4',
  audioPath: '/path/to/audio.m4a',
  latitude: 19.9975,
  longitude: 73.7898,
);
print('Upload success: $success');
```

## Debugging

Enable debug logs by checking the console output. All services use `debugPrint` for logging:

- 🚨 Emergency operations
- 📤 Upload operations
- ✅ Success messages
- ❌ Error messages
- 💾 Storage operations

## Notes

1. User must be registered with backend before creating emergency cases
2. Emergency case must be created before uploading evidence
3. Files are validated before upload to ensure they exist
4. Upload progress is tracked and logged
5. All IDs (user_id, case_id) are stored in SharedPreferences for persistence
