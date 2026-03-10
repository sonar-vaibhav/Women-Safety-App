import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safeguardher_flutter_app/screens/onboarding_screen/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen/home_screen.dart';
import 'screens/splash_screen/splash_screen.dart';
// Background service disabled - using foreground shake detection in HomeScreen
// import 'services/background/shake_service/shake_background_service.dart';

class SafeGuardHer extends ConsumerWidget {
  const SafeGuardHer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref)
  {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot)
      {
        if (snapshot.connectionState == ConnectionState.waiting)
        {
          return const SplashScreen();
        }
        else if (snapshot.hasError)
        {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        else if (snapshot.hasData)
        {
          final prefs = snapshot.data!;
          final phoneNumber = prefs.getString('phoneNumber');

          // Background service disabled - shake detection works in HomeScreen
          // if (phoneNumber != null) {
          //   ShakeBackgroundService.startService();
          // }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SafeGuardHer',
            theme: ThemeData(
              fontFamily: 'Poppins',
            ),
            home: phoneNumber != null ? const HomeScreen() : OnboardingScreen(),
          );
        }
        else
        {
          return const Center(child: Text('Unexpected error occurred.'));
        }
      },
    );
  }
}
