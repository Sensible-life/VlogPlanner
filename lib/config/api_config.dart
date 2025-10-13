import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String? _apiKey;
  static String? _googleMapsApiKey;
  
  // API 키 초기화
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: "assets/.env");
      _apiKey = dotenv.env['OPENAI_API_KEY'];
      _googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    } catch (e) {
      // .env 파일이 없으면 기본 API 키 사용
    }
  }
  
  // API 키 가져오기
  static String? get apiKey => _apiKey;
  
  // 구글 지도 API 키 가져오기
  static String? get googleMapsApiKey => _googleMapsApiKey;
  
  // API 키가 설정되어 있는지 확인
  static bool get isApiKeySet => _apiKey != null && _apiKey!.isNotEmpty && _apiKey!.startsWith('sk-');
  
  // 구글 지도 API 키가 설정되어 있는지 확인
  static bool get isGoogleMapsApiKeySet => _googleMapsApiKey != null && _googleMapsApiKey!.isNotEmpty;
  
  // API 키 설정 (런타임에 변경 가능)
  static void setApiKey(String key) {
    _apiKey = key;
  }
  
  // API 키 제거
  static void clearApiKey() {
    _apiKey = null;
  }
}
