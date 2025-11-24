import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'google_image_service.dart';

class ImageService {
  static const String _unsplashBaseUrl = 'https://api.unsplash.com/search/photos';
  static const String _pexelsBaseUrl = 'https://api.pexels.com/v1/search';
  
  static String? get _unsplashAccessKey => ApiConfig.unsplashApiKey;
  static String? get _pexelsApiKey => ApiConfig.pexelsApiKey;

  /// 씬별 이미지 검색 (개선된 버전)
  ///
  /// [location]: 씬 장소 (예: "롤러코스터", "푸드코트")
  /// [summary]: 씬 요약
  /// [tone]: 브이로그 톤 (예: "밝고 경쾌")
  /// [globalLocation]: 전체 촬영 장소 (예: "바르셀로나")
  /// [mood]: 분위기/감정 (예: "warm", "exciting")
  /// [activity]: 활동 내용
  /// [usedImageUrls]: 이미 사용된 이미지 URL 목록 (중복 방지용)
  static Future<String?> searchSceneImage({
    required String location,
    required String summary,
    required String tone,
    String? globalLocation,
    String mood = '',
    String activity = '',
    List<String> usedImageUrls = const [],
  }) async {
    try {
      print('[IMAGE_SERVICE] 씬 이미지 검색 시작: $location');

      // 1. Google Custom Search 시도 (가장 정확함, 맥락 포함)
      final googleImage = await GoogleImageService.searchSceneImage(
        sceneTitle: location,
        location: globalLocation ?? '',
        summary: summary,
        mood: mood.isNotEmpty ? mood : _extractMoodFromTone(tone),
        activity: activity,
        usedImageUrls: usedImageUrls,
      );

      if (googleImage != null) {
        print('[IMAGE_SERVICE] Google Custom Search 이미지 찾음');
        return googleImage;
      }

      print('[IMAGE_SERVICE] Google Custom Search 실패, Unsplash 시도');

      // 2. Unsplash API 시도
      final keywords = _generateImageKeywords(location, summary, tone);
      final unsplashUrl = await _searchUnsplash(keywords, orientation: 'landscape');
      if (unsplashUrl != null) {
        print('[IMAGE_SERVICE] Unsplash 이미지 찾음');
        return unsplashUrl;
      }

      // 3. Fallback: Pexels API
      print('[IMAGE_SERVICE] Unsplash 실패, Pexels 시도');
      final pexelsUrl = await _searchPexels(keywords, orientation: 'landscape');
      if (pexelsUrl != null) {
        print('[IMAGE_SERVICE] Pexels 이미지 찾음');
        return pexelsUrl;
      }

      print('[IMAGE_SERVICE] 이미지 검색 실패, 기본 이미지 사용');
      return _getPlaceholderImage();
    } catch (e) {
      print('[IMAGE_SERVICE] 씬 이미지 검색 오류: $e');
      return _getPlaceholderImage();
    }
  }

  /// 대표 썸네일 이미지 검색
  ///
  /// [title]: 브이로그 제목
  /// [keywords]: 브이로그 키워드 (예: ["테마파크", "친구", "놀이기구"])
  /// [tone]: 브이로그 톤
  static Future<String?> searchMainThumbnail({
    required String title,
    required List<String> keywords,
    required String tone,
  }) async {
    try {
      // 첫 번째 키워드를 메인 키워드로 사용 (필수 촬영 장소가 우선)
      final mainKeyword = keywords.isNotEmpty ? keywords[0] : _extractKeyword(title);

      print('[IMAGE_SERVICE] 대표 썸네일 검색 (필수 촬영 장소): $mainKeyword');

      // Featured 이미지 검색 (고품질)
      final unsplashUrl = await _searchUnsplash(
        mainKeyword,
        orientation: 'landscape',
        featured: true,
      );

      if (unsplashUrl != null) {
        print('[IMAGE_SERVICE] 대표 썸네일 찾음');
        return unsplashUrl;
      }

      // Fallback
      print('[IMAGE_SERVICE] 대표 썸네일 실패, Pexels 시도');
      final pexelsUrl = await _searchPexels(mainKeyword, orientation: 'landscape');
      return pexelsUrl ?? _getPlaceholderImage();
    } catch (e) {
      print('[IMAGE_SERVICE] 대표 썸네일 오류: $e');
      return _getPlaceholderImage();
    }
  }

  /// Unsplash API 검색
  static Future<String?> _searchUnsplash(
    String query, {
    String orientation = 'landscape',
    bool featured = false,
  }) async {
    try {
      // API 키가 설정되지 않은 경우
      if (_unsplashAccessKey == null) {
        print('[IMAGE_SERVICE] Unsplash API 키 미설정');
        return null;
      }

      final uri = Uri.parse(_unsplashBaseUrl).replace(queryParameters: {
        'query': query,
        'per_page': '1',
        'orientation': orientation,
        if (featured) 'featured': 'true',
      });

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Client-ID $_unsplashAccessKey!'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>;

        if (results.isNotEmpty) {
          return results[0]['urls']['regular'] as String;
        }
      } else {
        print('[IMAGE_SERVICE] Unsplash API 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('[IMAGE_SERVICE] Unsplash 검색 예외: $e');
    }

    return null;
  }

  /// Pexels API 검색
  static Future<String?> _searchPexels(
    String query, {
    String orientation = 'landscape',
  }) async {
    try {
      // API 키가 설정되지 않은 경우
      if (_pexelsApiKey == null) {
        print('[IMAGE_SERVICE] Pexels API 키 미설정');
        return null;
      }

      final uri = Uri.parse(_pexelsBaseUrl).replace(queryParameters: {
        'query': query,
        'per_page': '1',
        'orientation': orientation,
      });

      final response = await http.get(
        uri,
        headers: {'Authorization': _pexelsApiKey!},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final photos = data['photos'] as List<dynamic>;

        if (photos.isNotEmpty) {
          return photos[0]['src']['large'] as String;
        }
      } else {
        print('[IMAGE_SERVICE] Pexels API 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('[IMAGE_SERVICE] Pexels 검색 예외: $e');
    }

    return null;
  }

  /// 검색 키워드 생성 (간단한 매핑)
  static String _generateImageKeywords(String location, String summary, String tone) {
    // 장소 기반 영어 키워드 매핑
    final locationMap = {
      '롤러코스터': 'roller coaster',
      '회전목마': 'carousel',
      '관람차': 'ferris wheel',
      '푸드코트': 'food court',
      '동물원': 'zoo animals',
      '게이트': 'theme park entrance',
      '입구': 'entrance gate',
      '출구': 'exit',
      '벤치': 'park bench',
      '포토존': 'photo spot',
      '테마파크': 'theme park',
      '놀이공원': 'amusement park',
      '카페': 'cafe',
      '식당': 'restaurant',
      '해변': 'beach',
      '산': 'mountain',
      '공원': 'park',
    };

    // 장소를 영어로 변환
    String keyword = location;
    locationMap.forEach((kr, en) {
      if (location.contains(kr)) {
        keyword = en;
      }
    });

    return keyword;
  }

  /// Tone에서 분위기/감정 추출
  static String _extractMoodFromTone(String tone) {
    // Tone 예: "밝고 경쾌한" → "bright and cheerful"
    // 간단한 매핑
    final toneLower = tone.toLowerCase();
    
    if (toneLower.contains('밝') || toneLower.contains('bright')) {
      return 'bright';
    } else if (toneLower.contains('따뜻') || toneLower.contains('warm')) {
      return 'warm';
    } else if (toneLower.contains('평온') || toneLower.contains('calm')) {
      return 'calm';
    } else if (toneLower.contains('흥미') || toneLower.contains('exciting')) {
      return 'exciting';
    } else if (toneLower.contains('편안') || toneLower.contains('relaxing')) {
      return 'relaxing';
    }
    
    return 'pleasant';
  }

  /// 제목에서 키워드 추출
  static String _extractKeyword(String title) {
    // 제목에서 주요 단어 추출 (간단한 로직)
    final keywords = ['테마파크', '여행', '먹방', '카페', '공원', '해변'];

    for (final keyword in keywords) {
      if (title.contains(keyword)) {
        final locationMap = {
          '테마파크': 'theme park',
          '여행': 'travel',
          '먹방': 'food',
          '카페': 'cafe',
          '공원': 'park',
          '해변': 'beach',
        };
        return locationMap[keyword] ?? 'vlog';
      }
    }

    return 'vlog scene';
  }

  /// 기본 플레이스홀더 이미지 (API 실패 시)
  static String _getPlaceholderImage() {
    // Unsplash의 무료 플레이스홀더 이미지
    return 'https://images.unsplash.com/photo-1594818379496-da1e345b0ded?w=800';
  }
}
