import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  
  static String? get _apiKey => ApiConfig.openWeatherApiKey;

  /// 촬영 장소의 현재 날씨 정보
  ///
  /// [location]: 장소 이름 (예: "Seoul", "Daejeon")
  /// 반환: 날씨 정보 맵 또는 null
  static Future<Map<String, dynamic>?> getWeatherInfo(String location) async {
    try {
      // API 키가 설정되지 않은 경우
      if (_apiKey == null) {
        print('[WEATHER_SERVICE] OpenWeather API 키 미설정');
        return _getMockWeatherData();
      }

      // location 정제 (공백이나 특수문자 제거, 첫 번째 단어만 사용)
      final cleanLocation = _cleanLocationName(location);
      print('[WEATHER_SERVICE] 날씨 정보 조회: $location → $cleanLocation');

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': cleanLocation,
        'appid': _apiKey,
        'units': 'metric',  // 섭씨 온도
        'lang': 'kr',       // 한국어 설명
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final weatherInfo = {
          'temperature': data['main']['temp'].round(),  // 온도
          'description': data['weather'][0]['description'],  // 날씨 설명
          'humidity': data['main']['humidity'],  // 습도
          'windSpeed': data['wind']['speed'],  // 풍속
          'icon': data['weather'][0]['icon'],  // 날씨 아이콘 코드
          'recommendation': _generateRecommendation(
            temperature: data['main']['temp'],
            description: data['weather'][0]['main'],
            windSpeed: data['wind']['speed'],
          ),
        };

        print('[WEATHER_SERVICE] 날씨 정보 조회 완료: ${weatherInfo['temperature']}°C, ${weatherInfo['description']}');
        return weatherInfo;
      } else {
        print('[WEATHER_SERVICE] API 오류: ${response.statusCode}');
        return _getMockWeatherData();
      }
    } catch (e) {
      print('[WEATHER_SERVICE] 날씨 조회 예외: $e');
      return _getMockWeatherData();
    }
  }

  /// GPS 좌표 기반 날씨 정보
  static Future<Map<String, dynamic>?> getWeatherByCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      if (_apiKey == 'YOUR_OPENWEATHER_API_KEY') {
        print('[WEATHER_SERVICE] OpenWeather API 키 미설정');
        return _getMockWeatherData();
      }

      print('[WEATHER_SERVICE] 날씨 정보 조회 (좌표): ($latitude, $longitude)');

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'appid': _apiKey,
        'units': 'metric',
        'lang': 'kr',
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final weatherInfo = {
          'temperature': data['main']['temp'].round(),
          'description': data['weather'][0]['description'],
          'humidity': data['main']['humidity'],
          'windSpeed': data['wind']['speed'],
          'icon': data['weather'][0]['icon'],
          'recommendation': _generateRecommendation(
            temperature: data['main']['temp'],
            description: data['weather'][0]['main'],
            windSpeed: data['wind']['speed'],
          ),
        };

        print('[WEATHER_SERVICE] 날씨 정보 조회 완료');
        return weatherInfo;
      } else {
        print('[WEATHER_SERVICE] API 오류: ${response.statusCode}');
        return _getMockWeatherData();
      }
    } catch (e) {
      print('[WEATHER_SERVICE] 날씨 조회 예외: $e');
      return _getMockWeatherData();
    }
  }

  /// 날씨 기반 촬영 추천사항 생성
  static String _generateRecommendation({
    required double temperature,
    required String description,
    required double windSpeed,
  }) {
    final recommendations = <String>[];

    // 온도 기반
    if (temperature > 30) {
      recommendations.add('매우 더운 날씨입니다. 충분한 수분 섭취와 휴식이 필요합니다.');
    } else if (temperature > 25) {
      recommendations.add('따뜻한 날씨입니다. 햇빛 차단을 위한 모자나 선크림을 준비하세요.');
    } else if (temperature < 5) {
      recommendations.add('매우 추운 날씨입니다. 보온 장비와 배터리 예비분을 준비하세요.');
    } else if (temperature < 10) {
      recommendations.add('쌀쌀한 날씨입니다. 따뜻한 옷을 챙기세요.');
    } else {
      recommendations.add('촬영하기 좋은 날씨입니다.');
    }

    // 날씨 상태 기반
    if (description.toLowerCase().contains('rain')) {
      recommendations.add('비가 예상됩니다. 방수 장비와 우산을 준비하세요.');
    } else if (description.toLowerCase().contains('cloud')) {
      recommendations.add('구름이 있어 부드러운 조명 효과를 기대할 수 있습니다.');
    } else if (description.toLowerCase().contains('clear')) {
      recommendations.add('맑은 날씨로 야외 촬영에 최적입니다.');
    }

    // 바람 기반
    if (windSpeed > 10) {
      recommendations.add('바람이 강합니다. 마이크 윈드스크린과 삼각대를 사용하세요.');
    } else if (windSpeed > 5) {
      recommendations.add('바람이 있습니다. 오디오 녹음 시 주의하세요.');
    }

    return recommendations.join(' ');
  }

  /// 날씨 아이콘 URL 생성
  static String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  /// Mock 데이터 (API 키 없을 때)
  static Map<String, dynamic> _getMockWeatherData() {
    return {
      'temperature': 22,
      'description': '맑음',
      'humidity': 60,
      'windSpeed': 3.5,
      'icon': '01d',
      'recommendation': '촬영하기 좋은 날씨입니다. 햇빛이 강할 수 있으니 ND 필터를 고려하세요.',
    };
  }

  /// 장소 이름 정제 (OpenWeather API용)
  static String _cleanLocationName(String location) {
    // 공백으로 분리하여 첫 번째 단어만 사용
    final parts = location.trim().split(' ');
    if (parts.isEmpty) return 'Seoul';
    
    final cityName = parts[0];
    
    // 한국 도시명을 영어로 변환 (주요 도시)
    final koreanCityMap = {
      '서울': 'Seoul',
      '부산': 'Busan',
      '대구': 'Daegu',
      '인천': 'Incheon',
      '광주': 'Gwangju',
      '대전': 'Daejeon',
      '울산': 'Ulsan',
      '수원': 'Suwon',
      '성남': 'Seongnam',
      '고양': 'Goyang',
      '용인': 'Yongin',
      '부천': 'Bucheon',
    };
    
    if (koreanCityMap.containsKey(cityName)) {
      return koreanCityMap[cityName]!;
    }
    
    // 이미 영어라면 그대로 반환
    return cityName;
  }
}
