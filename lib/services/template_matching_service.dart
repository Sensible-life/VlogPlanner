import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart' show rootBundle;
import '../models/cue_card.dart';
import '../models/plan.dart';
import 'vlog_data_service.dart';

/// template_extract 데이터를 사용하여 유사한 예시를 찾는 서비스
class TemplateMatchingService {
  static final TemplateMatchingService _instance = TemplateMatchingService._internal();
  factory TemplateMatchingService() => _instance;
  TemplateMatchingService._internal();

  // 캐시: 로드된 템플릿들
  Map<String, Map<String, dynamic>>? _templateCache;

  /// 사용자 입력과 생성된 데이터를 기반으로 가장 유사한 템플릿을 찾습니다
  Future<String?> findMostSimilarTemplate({
    required Map<String, String> userInput,
    required Plan plan,
  }) async {
    try {
      // 스타일 분석 정보
      final tone = plan.styleAnalysis?.tone ?? '';
      final vibe = plan.styleAnalysis?.vibe ?? '';
      final category = _extractCategoryFromKeywords(plan.keywords);

      print('[TEMPLATE_MATCHING] 매칭 시작: tone=$tone, vibe=$vibe, category=$category');

      // 템플릿 로드
      final templates = await _loadTemplates();

      // 가장 유사한 템플릿 찾기
      String? bestMatch;
      double bestScore = 0.0;

      for (var entry in templates.entries) {
        final templateDir = entry.key;
        final template = entry.value;

        final score = _calculateSimilarityScore(
          targetTone: tone,
          targetVibe: vibe,
          targetCategory: category,
          template: template,
        );

        print('[TEMPLATE_MATCHING] $templateDir: $score');
        
        if (score > bestScore) {
          bestScore = score;
          bestMatch = templateDir;
        }
      }

      print('[TEMPLATE_MATCHING] 가장 유사한 템플릿: $bestMatch (score: $bestScore)');
      return bestMatch;
    } catch (e) {
      print('[TEMPLATE_MATCHING] 오류: $e');
      return null;
    }
  }

  /// 유사도 점수 계산
  double _calculateSimilarityScore({
    required String targetTone,
    required String targetVibe,
    required String targetCategory,
    required Map<String, dynamic> template,
  }) {
    double score = 0.0;

    // 1. 카테고리 매칭 (가장 중요)
    final templateCategory = template['category'] as String? ?? '';
    if (targetCategory.isNotEmpty && templateCategory.isNotEmpty) {
      if (templateCategory == targetCategory) {
        score += 3.0;
      } else {
        // 부분 매칭
        final keywords = templateCategory.split('_');
        if (keywords.any((k) => targetCategory.contains(k))) {
          score += 1.0;
        }
      }
    }

    // 2. 감정 톤 매칭
    final emotionTone = template['emotion_tone'] as Map<String, dynamic>?;
    if (emotionTone != null) {
      final brightness = emotionTone['brightness'] as int? ?? 3;
      final energy = emotionTone['energy'] as int? ?? 3;

      // tone을 간단히 분석
      if (targetTone.contains('밝') && brightness >= 3) {
        score += 1.0;
      }
      if (targetTone.contains('에너지') && energy >= 3) {
        score += 1.0;
      }
    }

    // 3. 바이브 매칭
    final visualSignature = template['visual_signature'] as Map<String, dynamic>?;
    if (visualSignature != null) {
      final pacing = visualSignature['pacing'] as String? ?? '';
      if (targetVibe.isNotEmpty && pacing.isNotEmpty) {
        if (targetVibe == 'MZ') {
          // MZ 바이브는 빠른 템포 선호
          if (pacing.toLowerCase().contains('fast')) {
            score += 1.5;
          }
        } else if (targetVibe == '시네마틱') {
          if (pacing.toLowerCase().contains('slow')) {
            score += 1.5;
          }
        }
      }
    }

    return score;
  }

  /// 키워드에서 카테고리를 추출
  String _extractCategoryFromKeywords(List<String> keywords) {
    if (keywords.isEmpty) return '';

    final keywordText = keywords.join(' ').toLowerCase();

    if (keywordText.contains('운동') || keywordText.contains('피트니스')) {
      return 'fitness_health';
    } else if (keywordText.contains('일') || keywordText.contains('업무') || keywordText.contains('프리랜서')) {
      return 'daily_routine';
    } else if (keywordText.contains('여행') || keywordText.contains('여행지')) {
      return 'travel';
    } else if (keywordText.contains('공부') || keywordText.contains('학습')) {
      return 'study';
    }

    return '';
  }

  /// template_extract 디렉토리에서 템플릿 로드
  Future<Map<String, Map<String, dynamic>>> _loadTemplates() async {
    if (_templateCache != null) {
      return _templateCache!;
    }

    final templates = <String, Map<String, dynamic>>{};

    try {
      // 1. Assets에서 템플릿 로드 시도
      print('[TEMPLATE_MATCHING] Assets에서 템플릿 로드 시도');
      
      // 직접 디렉토리 목록 로드
      final assetManifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = jsonDecode(assetManifestContent);
      
      // 디버깅: assets/templates로 시작하는 모든 키 출력
      final allTemplateKeys = manifestMap.keys
          .where((key) => key.startsWith('assets/templates/'))
          .toList();
      print('[TEMPLATE_MATCHING] 디버깅: assets/templates로 시작하는 키들:');
      for (var key in allTemplateKeys.take(10)) {
        print('[TEMPLATE_MATCHING]   - $key');
      }
      
      // templates 디렉토리의 모든 extracted_template.json 파일 찾기
      final templateAssets = manifestMap.keys
          .where((key) => key.startsWith('assets/templates/') && key.endsWith('/extracted_template.json'))
          .toList();

      print('[TEMPLATE_MATCHING] Assets에서 ${templateAssets.length}개 템플릿 발견');

      for (final assetPath in templateAssets) {
        try {
          final content = await rootBundle.loadString(assetPath);
          final templateData = jsonDecode(content) as Map<String, dynamic>;
          // assets/templates/fitness_01/extracted_template.json -> fitness_01
          final pathParts = assetPath.split('/');
          final templateName = pathParts[2]; // [assets, templates, fitness_01, ...]
          templates[templateName] = templateData;
          print('[TEMPLATE_MATCHING] 로드: $templateName');
        } catch (e) {
          print('[TEMPLATE_MATCHING] $assetPath 로드 실패: $e');
        }
      }

      _templateCache = templates;
      print('[TEMPLATE_MATCHING] ${templates.length}개의 템플릿 로드 완료');
    } catch (e) {
      print('[TEMPLATE_MATCHING] Assets 로드 오류: $e');
    }

    return templates;
  }

  /// 해당 템플릿의 대본 예시를 추출 (screenplay.txt 우선)
  /// 반환: screenplay 형태의 실제 브이로그 예시
  Future<String?> getScriptExample(String templateName, String sceneType) async {
    try {
      // Assets 경로로 변환: fitness_01 -> assets/templates/fitness_01/
      final assetBasePath = 'assets/templates/$templateName';

      // 1. screenplay.txt 우선 사용 (가장 고품질)
      try {
        final screenplayContent = await rootBundle.loadString('$assetBasePath/screenplay.txt');
        print('[TEMPLATE_MATCHING] screenplay.txt 발견, 추출 시작');

        // screenplay.txt에서 씬 타입에 맞는 예시 추출
        return _extractExamplesFromScreenplay(screenplayContent, sceneType);
      } catch (e) {
        print('[TEMPLATE_MATCHING] screenplay.txt 없음, 대체 방법 사용');
      }

      // 2. Fallback: merged_text_content.json 사용
      try {
        final mergedContent = await rootBundle.loadString('$assetBasePath/merged_text_content.json');
        final mergedData = jsonDecode(mergedContent) as Map<String, dynamic>;

        // 행동 정보 포함 (scene_contexts.txt 활용)
        final activityInfo = await _loadActivityInfo(assetBasePath);

        // merged_text_content.json 활용한 고품질 예시 추출
        return _extractExamplesFromMergedContent(mergedData, sceneType, activityInfo);
      } catch (e) {
        print('[TEMPLATE_MATCHING] merged_text_content.json 로드 실패: $e');
      }

      // 3. Fallback: cleaned_subtitles.txt 사용
      final content = await rootBundle.loadString('$assetBasePath/cleaned_subtitles.txt');

      // 행동 정보 포함 (scene_contexts.txt 활용)
      final activityInfo = await _loadActivityInfo(assetBasePath);

      // 씬 타입에 맞는 예시 추출 (여러 개, 30초~1분 분량)
      return _extractExamplesBySceneType(content, sceneType, activityInfo);
    } catch (e) {
      print('[TEMPLATE_MATCHING] 대본 예시 추출 오류: $e');
      return null;
    }
  }
  
  /// screenplay.txt에서 씬 타입에 맞는 예시 추출
  String _extractExamplesFromScreenplay(String screenplayContent, String sceneType) {
    // screenplay.txt는 ---로 씬 구분
    final scenes = screenplayContent.split('---').where((s) => s.trim().isNotEmpty).toList();

    print('[TEMPLATE_MATCHING] screenplay.txt에서 ${scenes.length}개 씬 발견');

    // 씬 타입별 키워드
    final keywords = _getKeywordsForSceneType(sceneType);

    // 키워드와 매칭되는 씬 찾기
    final matchingScenes = <String>[];

    for (var scene in scenes) {
      final sceneLower = scene.toLowerCase();

      // 키워드가 씬에 포함되어 있는지 확인
      if (keywords.any((keyword) => keyword.isNotEmpty && sceneLower.contains(keyword))) {
        matchingScenes.add(scene.trim());

        // 최대 2-3개만 수집
        if (matchingScenes.length >= 3) break;
      }
    }

    // 매칭된 씬이 없으면 처음 2개 씬 반환
    if (matchingScenes.isEmpty) {
      print('[TEMPLATE_MATCHING] 키워드 매칭 실패, 처음 2개 씬 사용');
      matchingScenes.addAll(scenes.take(2).map((s) => s.trim()));
    }

    print('[TEMPLATE_MATCHING] ${matchingScenes.length}개 매칭 씬 찾음');

    // 씬들을 ---로 구분하여 반환
    return matchingScenes.join('\n\n---\n\n');
  }

  /// scene_contexts.txt에서 행동 정보 로드
  Future<Map<String, String>> _loadActivityInfo(String assetBasePath) async {
    final activityInfo = <String, String>{};
    
    try {
      final content = await rootBundle.loadString('$assetBasePath/scene_contexts.txt');
      final lines = content.split('\n');
      
      String? currentTime;
      String? activity;
      
      for (var line in lines) {
        if (line.startsWith('Scene ')) {
          // Scene 1: 0:00:01 형식 파싱
          final timeMatch = RegExp(r'(\d+:\d+:\d+)').firstMatch(line);
          if (timeMatch != null) {
            currentTime = timeMatch.group(1)!;
          }
        } else if (line.startsWith('Activity:') && currentTime != null) {
          activity = line.replaceFirst('Activity:', '').trim();
          activityInfo[currentTime] = activity;
        }
      }
    } catch (e) {
      print('[TEMPLATE_MATCHING] scene_contexts.txt 로드 오류: $e');
    }
    
    return activityInfo;
  }

  /// 씬 타입에 따라 30초~1분 분량의 여러 예시 추출
  String _extractExamplesBySceneType(
    String subtitleContent, 
    String sceneType,
    Map<String, String> activityInfo,
  ) {
    // 타임스탬프와 대본을 파싱
    final segments = _parseSubtitles(subtitleContent);
    
    // 씬 타입별 키워드
    final keywords = _getKeywordsForSceneType(sceneType);
    
    // 키워드와 매칭되는 세그먼트 찾기
    final matchingIndices = <int>[];
    for (var i = 0; i < segments.length; i++) {
      final text = segments[i]['text'] as String? ?? '';
      if (keywords.any((keyword) => text.contains(keyword))) {
        matchingIndices.add(i);
      }
    }
    
    if (matchingIndices.isEmpty) {
      // 매칭 실패 시 처음부터 5-10개 세그먼트 반환
      return _buildExampleFromSegments(segments, 0, 10, activityInfo) ?? '';
    }
    
    // 매칭된 인덱스 주변의 3-5개 예시 추출
    final examples = <String>[];
    final usedIndices = <int>{};
    
    for (var idx in matchingIndices.take(5)) {
      if (usedIndices.contains(idx)) continue;
      
      // 각 매칭된 세그먼트 주변에서 30초~1분 분량 추출
      final startIdx = idx;
      final endIdx = (idx + 8).clamp(0, segments.length - 1);
      
      final example = _buildExampleFromSegments(segments, startIdx, endIdx, activityInfo);
      if (example != null && example.isNotEmpty) {
        examples.add(example);
        
        // 사용된 인덱스 표시 (중복 방지)
        for (var i = startIdx; i <= endIdx; i++) {
          usedIndices.add(i);
        }
      }
    }
    
    // 최소 3개는 보장
    if (examples.length < 3) {
      examples.clear();
      examples.add(_buildExampleFromSegments(segments, 0, 15, activityInfo)!);
    }
    
    return examples.join('\n\n---\n\n');
  }

  /// 자막 파싱 (타임스탬프 + 텍스트)
  List<Map<String, dynamic>> _parseSubtitles(String content) {
    final lines = content.split('\n');
    final segments = <Map<String, dynamic>>[];
    
    String? currentTimestamp;
    String? currentText;
    
    for (var line in lines) {
      final trimmed = line.trim();
      
      if (trimmed.isEmpty) {
        // 빈 줄: 세그먼트 종료
        if (currentTimestamp != null && currentText != null) {
          segments.add({
            'timestamp': currentTimestamp,
            'text': currentText,
          });
          currentTimestamp = null;
          currentText = null;
        }
      } else if (trimmed.startsWith('[')) {
        // 타임스탬프
        currentTimestamp = trimmed;
      } else if (!trimmed.startsWith('=') && !trimmed.startsWith('CLEANED') &&
                 !trimmed.startsWith('STATISTICS')) {
        // 대본 텍스트
        currentText = (currentText ?? '') + (currentText != null ? ' ' : '') + trimmed;
      }
    }
    
    // 마지막 세그먼트
    if (currentTimestamp != null && currentText != null) {
      segments.add({
        'timestamp': currentTimestamp,
        'text': currentText,
      });
    }
    
    return segments;
  }

  /// 세그먼트 목록에서 예시 문자열 생성 (행동 정보 포함)
  String? _buildExampleFromSegments(
    List<Map<String, dynamic>> segments,
    int startIdx,
    int endIdx,
    Map<String, String> activityInfo,
  ) {
    if (startIdx >= segments.length) return null;
    
    final actualEndIdx = endIdx.clamp(0, segments.length - 1);
    final exampleLines = <String>[];
    
    for (var i = startIdx; i <= actualEndIdx; i++) {
      final segment = segments[i];
      final timestamp = segment['timestamp'] as String? ?? '[00:00:00]';
      final text = segment['text'] as String? ?? '';
      
      // 타임스탬프에서 시간 추출 (예: [00:00:48] -> 0:00:48)
      final timeMatch = RegExp(r'\[(\d+:\d+:\d+)\]').firstMatch(timestamp);
      String? timeStr = timeMatch?.group(1);
      
      // 해당 시간의 행동 정보 찾기
      String? activity;
      if (timeStr != null && activityInfo.containsKey(timeStr)) {
        activity = activityInfo[timeStr];
      }
      
      // 행동 정보가 있으면 포함
      if (activity != null && activity.isNotEmpty) {
        exampleLines.add('$timestamp\n[행동] $activity\n[대사] $text');
      } else {
        exampleLines.add('$timestamp\n$text');
      }
    }
    
    return exampleLines.join('\n\n');
  }

  /// merged_text_content.json에서 고품질 예시 추출
  String _extractExamplesFromMergedContent(
    Map<String, dynamic> mergedData,
    String sceneType,
    Map<String, String> activityInfo,
  ) {
    final segments = (mergedData['merged_segments'] as List<dynamic>?)
        ?.cast<Map<String, dynamic>>() ?? [];
    
    if (segments.isEmpty) return '';
    
    // 씬 타입별 키워드
    final keywords = _getKeywordsForSceneType(sceneType);
    
    // 키워드와 매칭되는 세그먼트 찾기
    final matchingIndices = <int>[];
    for (var i = 0; i < segments.length; i++) {
      final text = segments[i]['text'] as String? ?? '';
      if (keywords.any((keyword) => text.contains(keyword))) {
        matchingIndices.add(i);
      }
    }
    
    if (matchingIndices.isEmpty) {
      // 매칭 실패 시 처음부터 5-10개 세그먼트 반환
      return _buildExampleFromMergedSegments(segments, 0, 10, activityInfo) ?? '';
    }
    
    // 매칭된 인덱스 주변의 3-5개 예시 추출
    final examples = <String>[];
    final usedIndices = <int>{};
    
    for (var idx in matchingIndices.take(5)) {
      if (usedIndices.contains(idx)) continue;
      
      // 각 매칭된 세그먼트 주변에서 30초~1분 분량 추출
      final startIdx = idx;
      final endIdx = (idx + 12).clamp(0, segments.length - 1);
      
      final example = _buildExampleFromMergedSegments(segments, startIdx, endIdx, activityInfo);
      if (example != null && example.isNotEmpty) {
        examples.add(example);
        
        // 사용된 인덱스 표시 (중복 방지)
        for (var i = startIdx; i <= endIdx; i++) {
          usedIndices.add(i);
        }
      }
    }
    
    // 최소 3개는 보장
    if (examples.length < 3) {
      examples.clear();
      examples.add(_buildExampleFromMergedSegments(segments, 0, 20, activityInfo)!);
    }
    
    return examples.join('\n\n---\n\n');
  }

  /// merged 세그먼트에서 풍부한 예시 생성 (행동 + 나레이션 + 자막)
  String? _buildExampleFromMergedSegments(
    List<Map<String, dynamic>> segments,
    int startIdx,
    int endIdx,
    Map<String, String> activityInfo,
  ) {
    if (startIdx >= segments.length) return null;
    
    final actualEndIdx = endIdx.clamp(0, segments.length - 1);
    final exampleLines = <String>[];
    
    for (var i = startIdx; i <= actualEndIdx; i++) {
      final segment = segments[i];
      final timestamp = segment['timestamp'] as String? ?? '[00:00:00]';
      final source = segment['source'] as String? ?? '';
      final text = segment['text'] as String? ?? '';
      
      if (text.trim().isEmpty) continue;
      
      // 타임스탬프에서 시간 추출 (예: [00:00:48] -> 0:00:48)
      final timeMatch = RegExp(r'\[(\d+:\d+:\d+)\]').firstMatch(timestamp);
      String? timeStr = timeMatch?.group(1);
      
      // 해당 시간의 행동 정보 찾기
      String? activity;
      if (timeStr != null && activityInfo.containsKey(timeStr)) {
        activity = activityInfo[timeStr];
      }
      
      // 소스 타입에 따라 구분
      String sourceLabel;
      if (source == 'VOICE') {
        sourceLabel = '[나레이션]';
      } else if (source == 'SCREEN') {
        sourceLabel = '[자막]';
      } else {
        sourceLabel = '[대사]';
      }
      
      // 행동 정보가 있으면 포함
      if (activity != null && activity.isNotEmpty) {
        exampleLines.add('$timestamp\n[행동] $activity\n$sourceLabel $text');
      } else {
        exampleLines.add('$timestamp\n$sourceLabel $text');
      }
    }
    
    return exampleLines.join('\n\n');
  }

  /// 씬 타입별 키워드
  List<String> _getKeywordsForSceneType(String sceneType) {
    switch (sceneType) {
      case 'opening':
      case 'intro':
        return ['안녕', '도착', '시작', '오늘', '드디어'];
      
      case 'food':
      case 'snack':
        return ['맛', '먹', '음식', '치킨', '메뉴', '좋아', '맛있'];
      
      case 'work':
      case 'office':
        return ['일', '업무', '오피스', '작업', '회사', '프리랜서', '컨퍼런스'];
      
      case 'moving':
      case 'travel':
        return ['이동', '가다', '도착', '이동', '걷', '여행'];
      
      case 'rest':
        return ['쉬', '휴식', '벤치', '마시'];
      
      case 'ending':
        return ['마지막', '인사', '마무리', '감사', '다음'];
      
      default:
        return ['', '']; // 빈 키워드로 전체 매칭
    }
  }

  /// 캐시 초기화
  void clearCache() {
    _templateCache = null;
  }
}

