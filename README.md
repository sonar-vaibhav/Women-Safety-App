# SafeGuardHer - Women Safety App

A Flutter-based mobile application designed to enhance women's safety through real-time tracking, emergency alerts, and community support features.

## Features

- **Real-time Location Tracking**: Track your location and share it with trusted contacts
- **SOS/Panic Button**: Quick emergency alert system
- **Anonymous Recording**: Discreet recording feature for safety
- **Route Navigation**: Safe route planning with OpenRouteService integration
- **Community Reports**: Report and view safety incidents in your area
- **Firebase Integration**: Secure authentication and real-time data sync
- **Multi-platform Support**: Available for both Android and iOS

## Prerequisites

Before you begin, ensure you have the following installed:
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Firebase CLI
- Git

## Getting Started

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd safeguardher_flutter_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Environment Configuration

Create a `.env` file in the root directory by copying the example:

```bash
cp .env.example .env
```

Edit the `.env` file and add your API keys:

```env
GOOGLE_MAPS_API_KEY=your_actual_google_maps_api_key
OPEN_ROUTE_SERVICE_API_KEY=your_actual_openroute_service_api_key
FIREBASE_ANDROID_API_KEY=your_actual_firebase_android_api_key
FIREBASE_IOS_API_KEY=your_actual_firebase_ios_api_key
```

### 4. Generate Environment Files

Run the following command to generate the environment configuration:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Firebase Setup

#### Android
1. Download `google-services.json` from your Firebase Console
2. Place it in `android/app/`

#### iOS
1. Download `GoogleService-Info.plist` from your Firebase Console
2. Place it in `ios/Runner/`

### 6. Run the App

```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For a specific device
flutter devices
flutter run -d <device-id>
```

## API Keys Required

### Google Maps API
- Get your API key from [Google Cloud Console](https://console.cloud.google.com/)
- Enable Maps SDK for Android and iOS
- Enable Directions API and Places API

### OpenRouteService API
- Sign up at [OpenRouteService](https://openrouteservice.org/)
- Generate an API key from your dashboard

### Firebase
- Create a project in [Firebase Console](https://console.firebase.google.com/)
- Enable Authentication, Firestore, and Storage
- Download configuration files for Android and iOS

## Project Structure

```
lib/
├── env/                    # Environment configuration
├── screens/               # UI screens
│   ├── tracking_screen/   # Location tracking features
│   └── ...
├── firebase_options.dart  # Firebase configuration
└── main.dart             # App entry point

assets/
├── fonts/                # Custom fonts (Poppins)
├── icons/                # App icons
├── illustrations/        # Onboarding and UI illustrations
├── logos/                # App logos
└── placeholders/         # Placeholder images
```

## Building for Production

### Android

```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

## Security Notes

- Never commit `.env` file or API keys to version control
- Keep `google-services.json` and `GoogleService-Info.plist` private
- Regenerate API keys if accidentally exposed
- Use Firebase Security Rules to protect your database

## Troubleshooting

### Environment Variables Not Loading
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Firebase Configuration Issues
- Ensure package name matches in Firebase Console and `android/app/build.gradle`
- Verify bundle ID matches in Firebase Console and Xcode project

### Map Not Displaying
- Check if Google Maps API key is correctly set in `.env`
- Verify API key has proper permissions in Google Cloud Console

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue in the GitHub repository or contact the development team.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- OpenRouteService for routing capabilities
- Google Maps for mapping services
