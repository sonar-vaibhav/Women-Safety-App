import 'package:envied/envied.dart';
part 'env.g.dart';

@Envied()
abstract class Env {
  @EnviedField(varName: 'GOOGLE_MAPS_API_KEY', defaultValue: '', obfuscate: true)
  static String googleMapsAPI = _Env.googleMapsAPI;
  
  @EnviedField(varName: 'OPEN_ROUTE_SERVICE_API_KEY', defaultValue: '', obfuscate: true)
  static String openRouteServiceAPI = _Env.openRouteServiceAPI;
  
  @EnviedField(varName: 'FIREBASE_ANDROID_API_KEY', defaultValue: '', obfuscate: true)
  static String firebaseAndroidApiKey = _Env.firebaseAndroidApiKey;
  
  @EnviedField(varName: 'FIREBASE_IOS_API_KEY', defaultValue: '', obfuscate: true)
  static String firebaseIosApiKey = _Env.firebaseIosApiKey;
}
