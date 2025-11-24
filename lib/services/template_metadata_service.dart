import 'dart:convert';
import 'package:flutter/services.dart';

class TemplateMetadataService {
  /// 템플릿 메타데이터에서 YouTube URL 가져오기
  static Future<String?> getTemplateYoutubeUrl(String templateId) async {
    try {
      print('[TEMPLATE_METADATA] 템플릿 메타데이터 로드 시도: $templateId');
      
      final metadataPath = 'assets/templates/$templateId/metadata.json';
      final metadataString = await rootBundle.loadString(metadataPath);
      final metadata = json.decode(metadataString);
      
      final youtubeUrl = metadata['youtube_url'] as String?;
      
      if (youtubeUrl != null && youtubeUrl.isNotEmpty) {
        print('[TEMPLATE_METADATA] ✅ YouTube URL 발견: $youtubeUrl');
        return youtubeUrl;
      } else {
        print('[TEMPLATE_METADATA] ⚠️ YouTube URL이 비어있거나 없음');
        return null;
      }
    } catch (e) {
      print('[TEMPLATE_METADATA] ❌ 메타데이터 로드 실패: $e');
      return null;
    }
  }
  
  /// 여러 템플릿에서 YouTube URL 찾기 (카테고리 기반)
  static Future<String?> findYoutubeUrlByCategory(String category) async {
    // 카테고리별 대표 템플릿 매핑
    final categoryTemplates = {
      'fitness_health': ['fitness_01', 'fitness_02', 'fitness_03'],
      'food_cooking': ['food_01', 'food_02', 'food_03', 'food_04'],
      'travel': [
        'japan_tokyo_01', 'japan_kyoto_01', 'japan_osaka_01',
        'france_paris_01', 'italy_rome_01', 'korea_seoul_01'
      ],
      'daily_life': ['daily_01', 'daily_02', 'daily_03', 'daily_04'],
      'art_culture': ['art_01', 'art_02', 'art_03'],
      'event': ['event_01', 'event_02'],
    };
    
    final templates = categoryTemplates[category] ?? [];
    
    for (final templateId in templates) {
      final url = await getTemplateYoutubeUrl(templateId);
      if (url != null) {
        print('[TEMPLATE_METADATA] ✅ 카테고리 "$category"에서 URL 발견: $templateId');
        return url;
      }
    }
    
    print('[TEMPLATE_METADATA] ⚠️ 카테고리 "$category"에서 URL을 찾을 수 없음');
    return null;
  }
  
  /// 키워드 기반으로 가장 관련성 높은 템플릿의 YouTube URL 찾기
  static Future<String?> findYoutubeUrlByKeywords(List<String>? keywords) async {
    if (keywords == null || keywords.isEmpty) {
      print('[TEMPLATE_METADATA] ⚠️ 키워드가 없어 검색 불가');
      return null;
    }
    
    print('[TEMPLATE_METADATA] 키워드 기반 템플릿 검색: ${keywords.join(", ")}');
    
    // 키워드 -> 카테고리 매핑
    final keywordCategoryMap = {
      '헬스장': 'fitness_health',
      '운동': 'fitness_health',
      '요가': 'fitness_health',
      '필라테스': 'fitness_health',
      '음식': 'food_cooking',
      '요리': 'food_cooking',
      '레시피': 'food_cooking',
      '맛집': 'food_cooking',
      '여행': 'travel',
      '관광': 'travel',
      '호텔': 'travel',
      '일상': 'daily_life',
      '브이로그': 'daily_life',
      'vlog': 'daily_life',
      '미술': 'art_culture',
      '전시': 'art_culture',
      '이벤트': 'event',
      '파티': 'event',
    };
    
    // 키워드와 매칭되는 카테고리 찾기
    for (final keyword in keywords) {
      final lowerKeyword = keyword.toLowerCase();
      for (final entry in keywordCategoryMap.entries) {
        if (lowerKeyword.contains(entry.key) || entry.key.contains(lowerKeyword)) {
          final url = await findYoutubeUrlByCategory(entry.value);
          if (url != null) {
            return url;
          }
        }
      }
    }
    
    print('[TEMPLATE_METADATA] ⚠️ 키워드와 매칭되는 템플릿 없음');
    return null;
  }
  
  /// 모든 템플릿의 YouTube URL과 제목 가져오기
  static Future<List<Map<String, String>>> getAllTemplateVideos() async {
    final videos = <Map<String, String>>[];
    
    try {
      // AssetManifest에서 모든 템플릿 디렉토리 찾기
      final assetManifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(assetManifestContent);
      
      // metadata.json 파일들 찾기
      final metadataAssets = manifestMap.keys
          .where((key) => key.startsWith('assets/templates/') && key.endsWith('/metadata.json'))
          .toList();
      
      print('[TEMPLATE_METADATA] ${metadataAssets.length}개 템플릿 메타데이터 발견');
      
      for (final assetPath in metadataAssets) {
        try {
          final metadataString = await rootBundle.loadString(assetPath);
          final metadata = json.decode(metadataString) as Map<String, dynamic>;
          
          final youtubeUrl = metadata['youtube_url'] as String?;
          final videoId = metadata['video_id'] as String?;
          final category = metadata['category'] as String?;
          
          if (youtubeUrl != null && youtubeUrl.isNotEmpty && videoId != null) {
            // 템플릿 ID에서 제목 생성 (예: fitness_01 -> Fitness 01)
            final title = _formatTemplateTitle(videoId);
            
            videos.add({
              'title': title,
              'url': youtubeUrl,
              'templateId': videoId,
              'category': category ?? '',
            });
          }
        } catch (e) {
          print('[TEMPLATE_METADATA] $assetPath 로드 실패: $e');
        }
      }
      
      // 제목 순으로 정렬
      videos.sort((a, b) => a['title']!.compareTo(b['title']!));
      
      print('[TEMPLATE_METADATA] ${videos.length}개 비디오 정보 로드 완료');
    } catch (e) {
      print('[TEMPLATE_METADATA] 템플릿 목록 로드 오류: $e');
    }
    
    return videos;
  }
  
  /// 템플릿 ID를 읽기 쉬운 제목으로 변환
  static String _formatTemplateTitle(String templateId) {
    // 언더스코어를 공백으로, 각 단어의 첫 글자를 대문자로
    final parts = templateId.split('_');
    final formatted = parts.map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
    
    return formatted;
  }
}
