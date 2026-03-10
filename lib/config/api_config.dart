/// API Configuration for SafeSphere Backend
class ApiConfig {
  // Base URL - Update this with your ngrok URL
  static const String baseUrl = 'https://27a3-2409-40c2-642e-ac78-d93e-ff98-3326-a29d.ngrok-free.app';
  
  // API Endpoints
  static const String registerUser = '/api/users/register';
  static const String getOrCreateUser = '/api/users/get-or-create'; // NEW: Get or create user by phone
  static const String addTrustedContact = '/api/users/trusted-contact';
  static const String getUser = '/api/users'; // + /{user_id}
  static const String startEmergency = '/api/emergency/start';
  static const String getCase = '/api/case'; // + /{case_id}
  static const String updateCaseStatus = '/api/emergency'; // + /{case_id}/status
  static const String uploadEvidence = '/api/evidence/upload';
  static const String getEvidence = '/api/evidence'; // + /{case_id}
  static const String generateFIR = '/api/fir/generate';
  static const String saveFIR = '/api/fir/save';
  static const String getFIR = '/api/fir'; // + /{case_id}
  
  // Request timeout
  static const Duration timeout = Duration(seconds: 30);
  
  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };
  
  static Map<String, String> get multipartHeaders => {
    'ngrok-skip-browser-warning': 'true',
  };
}
