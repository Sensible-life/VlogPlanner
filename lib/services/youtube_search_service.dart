import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'template_metadata_service.dart';

/// YouTube 영상 방향
enum VideoOrientation {
  vertical,   // 세로 (9:16, Shorts 등)
  horizontal, // 가로 (16:9, 일반 영상)
  square,     // 정사각형 (1:1)
  unknown     // 확인 불가
}

/// YouTube Data API v3를 사용한 레퍼런스 영상 검색 서비스
class YoutubeSearchService {
  static String? _apiKey;

  /// API 키 초기화
  static void initialize() {
    _apiKey = dotenv.env['YOUTUBE_API_KEY'];
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('[YOUTUBE_API] ⚠️ YouTube API 키가 설정되지 않았습니다.');
      print('[YOUTUBE_API] .env 파일에 YOUTUBE_API_KEY를 추가하세요.');
    }
  }

  /// YouTube 영상의 방향(세로/가로) 확인
  ///
  /// [videoUrl]: YouTube 영상 URL (예: "https://www.youtube.com/watch?v=VIDEO_ID")
  ///
  /// Returns: VideoOrientation enum (vertical, horizontal, square, unknown)
  static Future<VideoOrientation> getVideoOrientation(String videoUrl) async {
    try {
      // URL에서 비디오 ID 추출
      final videoId = _extractVideoId(videoUrl);
      if (videoId == null) {
        print('[YOUTUBE_API] ❌ 비디오 ID 추출 실패: $videoUrl');
        return VideoOrientation.unknown;
      }

      // YouTube oEmbed API 호출 (width, height 정보 포함)
      final oembedUrl = Uri.parse('https://www.youtube.com/oembed').replace(
        queryParameters: {
          'url': 'https://www.youtube.com/watch?v=$videoId',
          'format': 'json',
        },
      );

      final response = await http.get(oembedUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final width = data['width'] as int?;
        final height = data['height'] as int?;

        if (width != null && height != null) {
          final aspectRatio = width / height;

          print('[YOUTUBE_API] 📐 영상 크기: ${width}x$height (비율: ${aspectRatio.toStringAsFixed(2)})');

          // Aspect ratio로 방향 판단
          if (aspectRatio < 0.9) {
            // 세로 영상 (예: 9:16 = 0.5625)
            print('[YOUTUBE_API] ↕️ 세로 영상 감지');
            return VideoOrientation.vertical;
          } else if (aspectRatio > 1.1) {
            // 가로 영상 (예: 16:9 = 1.777...)
            print('[YOUTUBE_API] ↔️ 가로 영상 감지');
            return VideoOrientation.horizontal;
          } else {
            // 정사각형에 가까움 (0.9 ~ 1.1)
            print('[YOUTUBE_API] ⬜ 정사각형 영상 감지');
            return VideoOrientation.square;
          }
        }
      } else {
        print('[YOUTUBE_API] ⚠️ oEmbed API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('[YOUTUBE_API] ❌ 영상 방향 확인 오류: $e');
    }

    return VideoOrientation.unknown;
  }

  /// URL에서 YouTube 비디오 ID 추출
  ///
  /// 지원 형식:
  /// - https://www.youtube.com/watch?v=VIDEO_ID
  /// - https://youtu.be/VIDEO_ID
  /// - https://www.youtube.com/embed/VIDEO_ID
  static String? _extractVideoId(String url) {
    try {
      final uri = Uri.parse(url);

      // youtube.com/watch?v=VIDEO_ID
      if (uri.host.contains('youtube.com') && uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }

      // youtu.be/VIDEO_ID
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      }

      // youtube.com/embed/VIDEO_ID
      if (uri.host.contains('youtube.com') && uri.pathSegments.isNotEmpty) {
        if (uri.pathSegments[0] == 'embed' && uri.pathSegments.length > 1) {
          return uri.pathSegments[1];
        }
      }
    } catch (e) {
      print('[YOUTUBE_API] URL 파싱 오류: $e');
    }

    return null;
  }

  /// 씬 정보를 기반으로 레퍼런스 영상 검색
  /// 
  /// [sceneTitle]: 씬 제목 (예: "워밍업 - 스트레칭")
  /// [shotComposition]: 구도 정보 리스트 (예: ["와이드 샷으로 전체 풍경", "클로즈업"])
  /// [keywords]: 추가 키워드 (예: ["운동", "브이로그", "헬스장"])
  /// 
  /// Returns: YouTube 영상 URL 또는 null
  static Future<String?> searchReferenceVideo({
    required String sceneTitle,
    List<String>? shotComposition,
    List<String>? keywords,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('[YOUTUBE_API] API 키가 없어 검색을 건너뜁니다.');
      return null;
    }

    try {
      // 검색 쿼리 생성
      final query = _buildSearchQuery(
        sceneTitle: sceneTitle,
        shotComposition: shotComposition,
        keywords: keywords,
      );

      print('[YOUTUBE_API] 검색 쿼리: $query');

      // YouTube Data API 호출
      final url = Uri.parse('https://www.googleapis.com/youtube/v3/search').replace(
        queryParameters: {
          'part': 'snippet',
          'q': query,
          'type': 'video',
          'maxResults': '5', // 상위 5개 결과 (더 많은 옵션)
          'order': 'relevance', // 관련성 높은 순
          'videoDefinition': 'any', // HD 제한 해제 (더 많은 결과)
          'videoDuration': 'any', // 길이 제한 해제
          'key': _apiKey!,
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>?;

        if (items != null && items.isNotEmpty) {
          // 첫 번째 결과의 비디오 ID 추출
          final videoId = items[0]['id']['videoId'] as String;
          final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
          
          final videoTitle = items[0]['snippet']['title'] as String;
          print('[YOUTUBE_API] ✅ 레퍼런스 영상 찾음: $videoTitle');
          print('[YOUTUBE_API] URL: $videoUrl');
          
          return videoUrl;
        } else {
          // 검색 결과가 없으면 더 단순한 쿼리로 재시도
          print('[YOUTUBE_API] ⚠️ 검색 결과가 없습니다. 단순 쿼리로 재시도...');
          final fallbackResult = await _searchWithFallback(keywords);
          
          // 폴백 검색도 실패하면 템플릿 메타데이터에서 가져오기
          if (fallbackResult == null) {
            print('[YOUTUBE_API] ⚠️ 폴백 검색 실패. 템플릿 메타데이터에서 URL 시도...');
            return await TemplateMetadataService.findYoutubeUrlByKeywords(keywords);
          }
          
          return fallbackResult;
        }
      } else {
        print('[YOUTUBE_API] ❌ API 호출 실패: ${response.statusCode}');
        print('[YOUTUBE_API] 응답: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[YOUTUBE_API] ❌ 검색 오류: $e');
      return null;
    }
  }

  /// 검색 쿼리 생성
  static String _buildSearchQuery({
    required String sceneTitle,
    List<String>? shotComposition,
    List<String>? keywords,
  }) {
    final queryParts = <String>[];
    
    // 제외할 촬영 기술 용어들 (일반 YouTube 영상 제목에 잘 안 나옴)
    final excludeWords = {
      '와이드', '클로즈업', '미디엄', '샷', '촬영', '구도', '프레임',
      '앵글', '롱샷', '풀샷', '버스트', '팬', '틸트', '줌'
    };

    // 1. 기본 키워드 (브이로그 타입)
    if (keywords != null && keywords.isNotEmpty) {
      // '브이로그', 'vlog'만 추가 (나머지는 너무 구체적일 수 있음)
      for (final keyword in keywords) {
        if (keyword.toLowerCase() == '브이로그' || 
            keyword.toLowerCase() == 'vlog') {
          queryParts.add(keyword);
        }
      }
    }

    // 2. 씬 제목에서 핵심 단어 추출 (촬영 용어 제외)
    final titleWords = sceneTitle
        .replaceAll(RegExp(r'[^\w\s가-힣]'), ' ')
        .split(' ')
        .where((word) => 
          word.length >= 2 && 
          !excludeWords.contains(word) &&
          !word.contains('-') // "씬-1" 같은 것 제외
        )
        .take(2) // 최대 2개만
        .toList();
    queryParts.addAll(titleWords);

    // 3. 구도 정보는 건너뛰기 (기술 용어가 많아서 검색에 방해됨)
    // shotComposition은 사용하지 않음

    // 중복 제거
    final uniqueWords = queryParts.toSet().toList();
    
    // 쿼리가 너무 짧으면 기본 키워드 추가
    if (uniqueWords.length < 2) {
      // keywords에서 주제 관련 단어 찾기
      if (keywords != null) {
        for (final keyword in keywords) {
          if (keyword != '브이로그' && keyword != 'vlog' && keyword.length >= 2) {
            uniqueWords.add(keyword);
            if (uniqueWords.length >= 3) break;
          }
        }
      }
    }
    
    // 최종 쿼리 (최대 3-4개 단어)
    final finalQuery = uniqueWords.take(4).join(' ');
    
    // 쿼리가 너무 짧으면 기본값 사용
    if (finalQuery.trim().isEmpty) {
      return 'vlog 브이로그';
    }
    
    return finalQuery;
  }

  /// 폴백 검색 (단순한 쿼리로 재시도)
  static Future<String?> _searchWithFallback(List<String>? keywords) async {
    try {
      // 가장 기본적인 쿼리로 검색
      String fallbackQuery = 'vlog 브이로그';
      
      // keywords에서 주제 하나만 추가
      if (keywords != null && keywords.isNotEmpty) {
        for (final keyword in keywords) {
          if (keyword != '브이로그' && keyword != 'vlog') {
            fallbackQuery = '$fallbackQuery $keyword';
            break; // 하나만 추가
          }
        }
      }
      
      print('[YOUTUBE_API] 폴백 쿼리: $fallbackQuery');
      
      final url = Uri.parse('https://www.googleapis.com/youtube/v3/search').replace(
        queryParameters: {
          'part': 'snippet',
          'q': fallbackQuery,
          'type': 'video',
          'maxResults': '5',
          'order': 'relevance',
          'videoDefinition': 'any',
          'videoDuration': 'any',
          'key': _apiKey!,
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>?;

        if (items != null && items.isNotEmpty) {
          final videoId = items[0]['id']['videoId'] as String;
          final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
          final videoTitle = items[0]['snippet']['title'] as String;
          
          print('[YOUTUBE_API] ✅ 폴백 검색 성공: $videoTitle');
          return videoUrl;
        }
      }
      
      print('[YOUTUBE_API] ⚠️ 폴백 검색도 실패. 템플릿 메타데이터에서 URL 시도...');
      return await TemplateMetadataService.findYoutubeUrlByKeywords(keywords);
    } catch (e) {
      print('[YOUTUBE_API] ❌ 폴백 검색 오류: $e');
      // 오류가 발생해도 템플릿 메타데이터 시도
      print('[YOUTUBE_API] 템플릿 메타데이터에서 URL 시도...');
      return await TemplateMetadataService.findYoutubeUrlByKeywords(keywords);
    }
  }

  /// 여러 씬에 대해 일괄 검색 (비용 절감을 위해 제한적 사용)
  static Future<Map<int, String?>> searchMultipleScenes({
    required List<Map<String, dynamic>> scenes,
    List<String>? commonKeywords,
  }) async {
    final results = <int, String?>{};

    for (var i = 0; i < scenes.length; i++) {
      final scene = scenes[i];
      final title = scene['title'] as String? ?? '';
      final shotComp = scene['shotComposition'] as List<dynamic>?;
      
      final videoUrl = await searchReferenceVideo(
        sceneTitle: title,
        shotComposition: shotComp?.map((e) => e.toString()).toList(),
        keywords: commonKeywords,
      );

      results[i] = videoUrl;

      // API 호출 제한을 위한 딜레이 (1초)
      if (i < scenes.length - 1) {
        await Future.delayed(Duration(seconds: 1));
      }
    }

    return results;
  }

  /// YouTube 영상의 추천 시작 시점 추정 (간단한 휴리스틱)
  /// 
  /// 실제 구도 매칭은 Vision AI가 필요하므로, 여기서는 간단한 규칙 사용:
  /// - 오프닝/인트로 씬: 5-15초 (인트로 스킵)
  /// - 메인 씬: 30-60초 (본론 시작 부분)
  /// - 클로징 씬: 0초 (처음부터)
  static int estimateStartTimestamp(String sceneTitle, int sceneIndex, int totalScenes) {
    final titleLower = sceneTitle.toLowerCase();

    // 오프닝/인트로
    if (sceneIndex == 0 || titleLower.contains('오프닝') || titleLower.contains('인트로')) {
      return 10; // 10초 (인트로 스킵)
    }

    // 클로징/아웃트로
    if (sceneIndex == totalScenes - 1 || titleLower.contains('클로징') || titleLower.contains('아웃트로')) {
      return 0; // 처음부터
    }

    // 메인 씬 (중간 부분)
    // 씬 위치에 따라 영상의 다른 부분 참고
    final progress = sceneIndex / totalScenes;
    if (progress < 0.3) {
      return 30; // 초반부
    } else if (progress < 0.7) {
      return 60; // 중반부
    } else {
      return 45; // 후반부
    }
  }
}
