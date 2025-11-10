import 'package:http/http.dart' as http;
import 'dart:convert';

class GooglePlacesService {
  static const String _apiKey = 'YOUR_GOOGLE_PLACES_API_KEY';  // TODO: 실제 키로 교체
  static const String _placesUrl = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json';
  static const String _geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  /// 장소 이름으로부터 실제 좌표 검색
  ///
  /// [locationName]: 검색할 장소 이름 (예: "오월드", "롯데월드")
  /// 반환: (위도, 경도) 또는 null
  static Future<({double latitude, double longitude})?> searchLocationCoordinates(
    String locationName,
  ) async {
    try {
      if (_apiKey == 'YOUR_GOOGLE_PLACES_API_KEY') {
        print('[GOOGLE_PLACES] API 키 미설정, 기본값 반환');
        // 기본값 반환
        return _getDefaultCoordinates(locationName);
      }

      print('[GOOGLE_PLACES] 좌표 검색: $locationName');

      final uri = Uri.parse(_placesUrl).replace(queryParameters: {
        'input': locationName,
        'inputtype': 'textquery',
        'fields': 'geometry',
        'key': _apiKey,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List<dynamic>?;

        if (candidates != null && candidates.isNotEmpty) {
          final location = candidates[0]['geometry']['location'];
          final lat = (location['lat'] as num?)?.toDouble() ?? 0.0;
          final lng = (location['lng'] as num?)?.toDouble() ?? 0.0;

          print('[GOOGLE_PLACES] 좌표 찾음: ($lat, $lng)');
          return (latitude: lat, longitude: lng);
        }
      }

      print('[GOOGLE_PLACES] 검색 결과 없음, 기본값 사용');
      return _getDefaultCoordinates(locationName);
    } catch (e) {
      print('[GOOGLE_PLACES] 좌표 검색 오류: $e');
      return _getDefaultCoordinates(locationName);
    }
  }

  /// 기본 좌표 반환 (임시)
  static ({double latitude, double longitude}) _getDefaultCoordinates(String locationName) {
    final defaultLocations = {
      '오월드': (latitude: 36.8109, longitude: 127.1498),
      '에버랜드': (latitude: 37.2940, longitude: 127.2020),
      '롯데월드': (latitude: 37.5111, longitude: 127.0980),
    };

    for (final entry in defaultLocations.entries) {
      if (locationName.contains(entry.key)) {
        return entry.value;
      }
    }

    // 기본값 (서울 시청)
    return (latitude: 37.5665, longitude: 126.9780);
  }

  /// 여러 장소의 좌표를 한번에 검색
  static Future<List<({double latitude, double longitude})?>> searchMultipleCoordinates(
    List<String> locationNames,
  ) async {
    final futures = locationNames.map((name) => searchLocationCoordinates(name));
    return await Future.wait(futures);
  }
}

