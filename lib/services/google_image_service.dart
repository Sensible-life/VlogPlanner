import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class GoogleImageService {
  // Google Custom Search API
  static String? get _apiKey => ApiConfig.googleCustomSearchApiKey;
  static String? get _searchEngineId => ApiConfig.googleCustomSearchEngineId;
  static const String _baseUrl = 'https://www.googleapis.com/customsearch/v1';

  /// 씬 정보를 기반으로 실제 장소 이미지 검색 (개선된 버전)
  ///
  /// [sceneTitle]: 씬 제목 (예: "사그라다 파밀리아 감상")
  /// [location]: 촬영 장소 (예: "바르셀로나")
  /// [summary]: 씬 요약
  /// [mood]: 분위기/감정 (예: "warm", "exciting", "calm")
  /// [activity]: 활동 내용
  /// [usedImageUrls]: 이미 사용된 이미지 URL 목록 (중복 방지용)
  static Future<String?> searchSceneImage({
    required String sceneTitle,
    required String location,
    required String summary,
    String mood = '',
    String activity = '',
    List<String> usedImageUrls = const [],
  }) async {
    try {
      // 1. GPT-4로 향상된 검색 키워드 생성 (맥락 포함)
      final searchKeyword = await _generateEnhancedSearchKeyword(
        sceneTitle: sceneTitle,
        location: location,
        summary: summary,
        mood: mood,
        activity: activity,
      );

      if (searchKeyword == null || searchKeyword.isEmpty) {
        print('[GOOGLE_IMAGE] 검색 키워드 생성 실패, Fallback 사용');
        return _searchWithFallback(sceneTitle, location, usedImageUrls, 0);
      }

      print('[GOOGLE_IMAGE] 향상된 검색 키워드: $searchKeyword');

      // 2. 여러 이미지 가져오기 (중복 체크 포함)
      final imageUrl = await _searchImageWithDuplicateCheck(
        searchKeyword,
        usedImageUrls,
      );

      if (imageUrl != null) {
        print('[GOOGLE_IMAGE] 적절한 이미지 찾음: $imageUrl');
        return imageUrl;
      }

      // 3. Fallback: 간단한 키워드로 재시도
      print('[GOOGLE_IMAGE] 첫 검색 실패, Fallback 키워드 시도');
      final fallbackKeyword = _getFallbackKeyword(sceneTitle, location);
      final fallbackImage = await _searchImageWithDuplicateCheck(
        fallbackKeyword,
        usedImageUrls,
      );

      if (fallbackImage != null) return fallbackImage;

      // 4. 최종 Fallback: 중복 허용하여 가져오기
      return _searchWithFallback(sceneTitle, location, usedImageUrls, 0);
    } catch (e) {
      print('[GOOGLE_IMAGE] 씬 이미지 검색 오류: $e');
      return null;
    }
  }

  /// GPT-4로 최적의 검색 키워드 생성
  static Future<String?> _generateSearchKeyword({
    required String sceneTitle,
    required String location,
    required String summary,
  }) async {
    try {
      final prompt = '''
다음 브이로그 씬에 어울리는 실제 장소 이미지를 검색하기 위한 영어 키워드를 생성해주세요.

씬 정보:
- 제목: $sceneTitle
- 장소: $location
- 내용: $summary

요구사항:
1. 영어로만 출력
2. 2-4 단어로 구성
3. 구체적인 장소명이 있으면 포함
4. 검색하면 실제 사진이 나올만한 키워드

예시:
- "사그라다 파밀리아 감상" → "Sagrada Familia Barcelona"
- "에펠탑 방문" → "Eiffel Tower Paris"
- "해변 산책" → "Barcelona Beach"
- "점심 식사" → "Barcelona Restaurant"

키워드만 출력하세요 (설명 없이):
''';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getApiKey()}',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',  // 저렴한 모델 사용
          'messages': [
            {
              'role': 'system',
              'content': 'You are a search keyword generator.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.3,
          'max_tokens': 50,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final keyword = data['choices'][0]['message']['content'].trim();
        print('[GOOGLE_IMAGE] GPT-4 키워드 생성: $keyword');
        return keyword;
      } else {
        print('[GOOGLE_IMAGE] GPT-4 키워드 생성 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[GOOGLE_IMAGE] 키워드 생성 오류: $e');
      return null;
    }
  }

  /// Google Custom Search로 이미지 검색
  static Future<String?> _searchImage(String query) async {
    try {
      // API 키가 설정되지 않은 경우
      if (_apiKey == null || _searchEngineId == null) {
        print('[GOOGLE_IMAGE] Google Custom Search API 키 또는 Search Engine ID 미설정');
        return null;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'key': _apiKey,
        'cx': _searchEngineId,
        'q': query,
        'searchType': 'image',
        'num': '1',  // 첫 번째 결과만
        'imgSize': 'large',  // 큰 이미지
        'safe': 'active',  // 세이프 서치
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>?;

        if (items != null && items.isNotEmpty) {
          final imageUrl = items[0]['link'] as String;
          return imageUrl;
        } else {
          print('[GOOGLE_IMAGE] 검색 결과 없음: $query');
          return null;
        }
      } else {
        print('[GOOGLE_IMAGE] API 오류: ${response.statusCode}');
        print('[GOOGLE_IMAGE] 응답: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[GOOGLE_IMAGE] 검색 오류: $e');
      return null;
    }
  }

  /// Fallback 키워드 생성 (간단한 규칙 기반)
  static String _getFallbackKeyword(String sceneTitle, String location) {
    // 간단한 매핑
    final keywords = <String>[];

    // 장소 추가
    if (location.isNotEmpty) {
      keywords.add(location);
    }

    // 씬 제목에서 주요 단어 추출
    final titleLower = sceneTitle.toLowerCase();

    final mappings = {
      '도착': 'arrival',
      '입구': 'entrance',
      '관람': 'view',
      '감상': 'sightseeing',
      '산책': 'walking',
      '공원': 'park',
      '해변': 'beach',
      '식사': 'restaurant',
      '점심': 'lunch',
      '저녁': 'dinner',
      '쇼핑': 'shopping',
      '기념품': 'souvenir',
      '야경': 'night view',
      '마무리': 'sunset',
      '사원': 'temple',
      '성당': 'cathedral',
      '박물관': 'museum',
      '광장': 'square',
      '거리': 'street',
    };

    mappings.forEach((kr, en) {
      if (titleLower.contains(kr)) {
        keywords.add(en);
      }
    });

    // 키워드가 없으면 기본값
    if (keywords.isEmpty) {
      keywords.add('travel destination');
    }

    return keywords.join(' ');
  }

  /// OpenAI API 키 가져오기 (키워드 생성용)
  static Future<String> _getApiKey() async {
    // ApiConfig에서 OpenAI API 키 가져오기
    try {
      final apiKey = ApiConfig.apiKey;
      return apiKey ?? '';
    } catch (e) {
      return '';
    }
  }

  /// 향상된 검색 키워드 생성 (맥락 + 감정 + 활동 포함)
  static Future<String?> _generateEnhancedSearchKeyword({
    required String sceneTitle,
    required String location,
    required String summary,
    String mood = '',
    String activity = '',
  }) async {
    try {
      final prompt = '''
다음 브이로그 씬에 가장 어울리는 실제 장소 이미지를 검색하기 위한 고도화된 영어 키워드를 생성해주세요.

씬 정보:
- 제목: $sceneTitle
- 장소: $location
- 내용: $summary
${mood.isNotEmpty ? '- 분위기: $mood' : ''}
${activity.isNotEmpty ? '- 활동: $activity' : ''}

요구사항:
1. 영어로만 출력 (2-6 단어)
2. 구체적인 장소명이 있으면 반드시 포함
3. 분위기/감정이 있으면 그에 맞는 수식어 추가
4. "cinematic, high quality, photo realistic" 같은 품질 키워드 제외
5. 검색하면 실제 사진이 나올만한 키워드

예시:
- 서울역, 출발, 설렘 → "Seoul station travel morning"
- 에펠탑, 감상, 따뜻한 → "Eiffel Tower Paris daytime"
- 해변, 산책, 평온 → "Barcelona beach walking"
- 카페, 휴식, 편안 → "coffee shop Barcelona"

키워드만 출력하세요 (설명 없이):
''';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getApiKey()}',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a search keyword generator that creates contextually rich image search queries.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.3,
          'max_tokens': 50,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final keyword = data['choices'][0]['message']['content'].trim();
        print('[GOOGLE_IMAGE] 향상된 키워드 생성: $keyword');
        return keyword;
      } else {
        print('[GOOGLE_IMAGE] GPT-4 키워드 생성 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[GOOGLE_IMAGE] 키워드 생성 오류: $e');
      return null;
    }
  }

  /// 중복 체크하면서 이미지 검색 (여러 개 가져오기)
  static Future<String?> _searchImageWithDuplicateCheck(
    String query,
    List<String> usedImageUrls,
  ) async {
    try {
      // 여러 이미지 가져오기 (최대 5개)
      final images = await _searchMultipleImages(query, 5);
      
      if (images == null || images.isEmpty) {
        print('[GOOGLE_IMAGE] 검색 결과 없음: $query');
        return null;
      }

      // 중복 체크: 사용되지 않은 이미지 찾기
      for (final imageUrl in images) {
        if (!usedImageUrls.contains(imageUrl)) {
          print('[GOOGLE_IMAGE] 중복 없는 이미지 찾음: $imageUrl');
          return imageUrl;
        }
      }

      // 모두 중복이면 첫 번째 것이라도 반환
      print('[GOOGLE_IMAGE] 모든 이미지가 중복, 첫 번째 이미지 반환');
      return images[0];
    } catch (e) {
      print('[GOOGLE_IMAGE] 중복 체크 검색 오류: $e');
      return null;
    }
  }

  /// 여러 이미지 검색 (중복 체크를 위해)
  static Future<List<String>?> _searchMultipleImages(
    String query,
    int count,
  ) async {
    try {
      if (_apiKey == null || _searchEngineId == null) {
        print('[GOOGLE_IMAGE] Google Custom Search API 키 또는 Search Engine ID 미설정');
        return null;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'key': _apiKey,
        'cx': _searchEngineId,
        'q': query,
        'searchType': 'image',
        'num': count.toString(),
        'imgSize': 'large',
        'safe': 'active',
        'fileType': 'jpg,png',  // 특정 파일 형식만
        'imgType': 'photo',  // 사진만
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>?;

        if (items != null && items.isNotEmpty) {
          final imageUrls = items
              .map((item) => item['link'] as String)
              .whereType<String>()
              .toList();
          
          print('[GOOGLE_IMAGE] ${imageUrls.length}개 이미지 찾음');
          return imageUrls;
        } else {
          print('[GOOGLE_IMAGE] 검색 결과 없음: $query');
          return null;
        }
      } else {
        print('[GOOGLE_IMAGE] API 오류: ${response.statusCode}');
        print('[GOOGLE_IMAGE] 응답: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[GOOGLE_IMAGE] 검색 오류: $e');
      return null;
    }
  }

  /// Fallback 검색 (인덱스 지정 가능)
  static Future<String?> _searchWithFallback(
    String sceneTitle,
    String location,
    List<String> usedImageUrls,
    int index,
  ) async {
    final fallbackKeyword = _getFallbackKeyword(sceneTitle, location);
    final images = await _searchMultipleImages(fallbackKeyword, 5);
    
    if (images == null || images.isEmpty) return null;
    
    // 특정 인덱스의 이미지 반환 (0이면 첫 번째)
    final safeIndex = index.clamp(0, images.length - 1);
    return images[safeIndex];
  }
}
