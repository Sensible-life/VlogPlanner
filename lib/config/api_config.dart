import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String? _apiKey;
  static String? _googleMapsApiKey;
  static String? _googleCustomSearchApiKey;
  static String? _googleCustomSearchEngineId;
  static String? _unsplashApiKey;
  static String? _pexelsApiKey;
  static String? _openWeatherApiKey;
  static String? _naverClientId;
  static String? _naverClientSecret;
  
  // API 키 초기화
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: "assets/.env");
      _apiKey = dotenv.env['OPENAI_API_KEY'];
      _googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      _googleCustomSearchApiKey = dotenv.env['GOOGLE_CUSTOM_SEARCH_API_KEY'];
      _googleCustomSearchEngineId = dotenv.env['GOOGLE_CUSTOM_SEARCH_ENGINE_ID'];
      _unsplashApiKey = dotenv.env['UNSPLASH_API_KEY'];
      _pexelsApiKey = dotenv.env['PEXELS_API_KEY'];
      _openWeatherApiKey = dotenv.env['OPENWEATHER_API_KEY'];
      _naverClientId = dotenv.env['NAVER_CLIENT_ID'];
      _naverClientSecret = dotenv.env['NAVER_CLIENT_SECRET'];
    } catch (e) {
      // .env 파일이 없으면 기본 API 키 사용
    }
  }
  
  // API 키 가져오기
  static String? get apiKey => _apiKey;
  static String? get googleMapsApiKey => _googleMapsApiKey;
  static String? get googleCustomSearchApiKey => _googleCustomSearchApiKey;
  static String? get googleCustomSearchEngineId => _googleCustomSearchEngineId;
  static String? get unsplashApiKey => _unsplashApiKey;
  static String? get pexelsApiKey => _pexelsApiKey;
  static String? get openWeatherApiKey => _openWeatherApiKey;
  static String? get naverClientId => _naverClientId;
  static String? get naverClientSecret => _naverClientSecret;
  
  // API 키가 설정되어 있는지 확인
  static bool get isApiKeySet => _apiKey != null && _apiKey!.isNotEmpty && _apiKey!.startsWith('sk-');
  static bool get isGoogleMapsApiKeySet => _googleMapsApiKey != null && _googleMapsApiKey!.isNotEmpty;
  static bool get isGoogleCustomSearchApiKeySet => _googleCustomSearchApiKey != null && _googleCustomSearchApiKey!.isNotEmpty && _googleCustomSearchEngineId != null && _googleCustomSearchEngineId!.isNotEmpty;
  static bool get isUnsplashApiKeySet => _unsplashApiKey != null && _unsplashApiKey!.isNotEmpty;
  static bool get isPexelsApiKeySet => _pexelsApiKey != null && _pexelsApiKey!.isNotEmpty;
  static bool get isOpenWeatherApiKeySet => _openWeatherApiKey != null && _openWeatherApiKey!.isNotEmpty;
  static bool get isNaverApiKeySet => _naverClientId != null && _naverClientId!.isNotEmpty && _naverClientSecret != null && _naverClientSecret!.isNotEmpty;
  
  // API 키 설정 (런타임에 변경 가능)
  static void setApiKey(String key) {
    _apiKey = key;
  }
  
  // API 키 제거
  static void clearApiKey() {
    _apiKey = null;
  }
}
