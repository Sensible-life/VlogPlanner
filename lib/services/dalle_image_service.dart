import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';
import 'firebase_storage_service.dart';

/// DALL-E API를 사용한 스토리보드 스케치 이미지 생성 서비스
class DalleImageService {
  static const String _openaiImageUrl = 'https://api.openai.com/v1/images/generations';
  
  static String? get _apiKey => ApiConfig.apiKey;
  
  // SSL 인증서 검증을 우회하는 HTTP 클라이언트 (개발 환경용)
  // ⚠️ 주의: 프로덕션에서는 보안상 위험하므로 사용하지 마세요
  static http.Client _createHttpClient() {
    final httpClient = HttpClient();
    httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // 개발 환경에서만 인증서 검증 우회
      print('[DALLE] ⚠️ SSL 인증서 검증 우회 (개발 환경): $host:$port');
      return true;
    };
    return IOClient(httpClient);
  }

  /// 씬의 구도를 표현한 스케치 스타일 이미지 생성
  /// 
  /// [sceneTitle]: 씬 제목 (예: "헬스장 입구에서 인사")
  /// [shotComposition]: 구도 정보 리스트 (예: ["와이드샷으로 전체 풍경", "클로즈업으로 표정 강조"])
  /// [shootingInstructions]: 촬영 지시사항 (예: ["천천히 패닝", "손떨림 주의"])
  /// [location]: 촬영 장소 (예: "헬스장")
  /// [summary]: 씬 요약
  /// [checklist]: 촬영 체크리스트 (예: ["와이드 샷으로 전체 장면 포착", "주인공 클로즈업으로 표정 촬영"])
  static Future<String?> generateStoryboardImage({
    required String sceneTitle,
    required List<String> shotComposition,
    required List<String> shootingInstructions,
    required String location,
    required String summary,
    required List<String> checklist,
    int retryCount = 0, // 재시도 횟수 (내부용)
  }) async {
    try {
      if (_apiKey == null || _apiKey!.isEmpty) {
        print('[DALLE] API 키가 설정되지 않았습니다');
        return null;
      }

      // 프롬프트 생성
      final prompt = _generatePrompt(
        sceneTitle: sceneTitle,
        shotComposition: shotComposition,
        shootingInstructions: shootingInstructions,
        location: location,
        summary: summary,
        checklist: checklist,
      );

      print('[DALLE] 스토리보드 이미지 생성 시작');
      print('[DALLE] 프롬프트: $prompt');

      final client = _createHttpClient();
      try {
        final response = await client.post(
          Uri.parse(_openaiImageUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': 'dall-e-3',
            'prompt': prompt,
            'n': 1,
            'size': '1024x1024',
            'quality': 'standard',
            'style': 'natural', // 'vivid' 또는 'natural'
          }),
        ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('DALL-E API 타임아웃');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dalleImageUrl = data['data'][0]['url'] as String;
        
        print('[DALLE] 이미지 생성 성공: $dalleImageUrl');
        
        // TODO: Firebase Storage 업로드 로직 (Firebase 결제 활성화 후 주석 해제)
        // Firebase Storage에 업로드
        // final timestamp = DateTime.now().millisecondsSinceEpoch;
        // final storagePath = 'storyboard_images/${sceneTitle.replaceAll(' ', '_')}_$timestamp.png';
        // 
        // print('[DALLE] Firebase Storage 업로드 시작...');
        // final firebaseUrl = await FirebaseStorageService().uploadImageFromUrl(
        //   imageUrl: dalleImageUrl,
        //   path: storagePath,
        // );
        // 
        // if (firebaseUrl != null) {
        //   print('[DALLE] Firebase Storage 업로드 완료: $firebaseUrl');
        //   return firebaseUrl;
        // } else {
        //   print('[DALLE] Firebase Storage 업로드 실패, DALL-E URL 반환');
        //   // 업로드 실패 시 원본 URL 반환 (임시)
        //   return dalleImageUrl;
        // }
        
          // 임시: DALL-E URL 그대로 반환
          return dalleImageUrl;
        } else if (response.statusCode == 429 && retryCount < 2) {
          // Rate Limit 오류 (최대 2번 재시도)
          final waitTime = (retryCount + 1) * 10; // 10초, 20초로 증가
          print('[DALLE] Rate Limit 오류 (429), ${waitTime}초 대기 후 재시도... (${retryCount + 1}/2)');
          await Future.delayed(Duration(seconds: waitTime));
          // 재시도
          return await generateStoryboardImage(
            sceneTitle: sceneTitle,
            shotComposition: shotComposition,
            shootingInstructions: shootingInstructions,
            location: location,
            summary: summary,
            checklist: checklist,
            retryCount: retryCount + 1,
          );
        } else if (response.statusCode == 429) {
          // Rate Limit 오류 (재시도 횟수 초과)
          print('[DALLE] Rate Limit 오류 (429), 재시도 횟수 초과');
          return null;
        } else {
          print('[DALLE] API 오류: ${response.statusCode}');
          print('[DALLE] 응답: ${response.body}');
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('[DALLE] 이미지 생성 오류: $e');
      return null;
    }
  }

  /// DALL-E용 프롬프트 생성
  /// 
  /// 스케치 스타일의 스토리보드 이미지를 생성하기 위한 프롬프트
  static String _generatePrompt({
    required String sceneTitle,
    required List<String> shotComposition,
    required List<String> shootingInstructions,
    required String location,
    required String summary,
    required List<String> checklist,
  }) {
    // 구도 정보 정리
    final compositionText = shotComposition.isNotEmpty
        ? shotComposition.join(', ')
        : '미디엄 샷';

    // 촬영 지시사항에서 카메라 움직임 추출
    final cameraMovement = shootingInstructions.isNotEmpty
        ? shootingInstructions
            .where((inst) => 
                inst.contains('패닝') || 
                inst.contains('틸트') || 
                inst.contains('줌') ||
                inst.contains('고정'))
            .join(', ')
        : '';

    // 체크리스트에서 하나의 구도 선택 (첫 번째 항목 사용)
    final selectedChecklistItem = checklist.isNotEmpty ? checklist[0] : 'medium shot';
    
    // 영어로 프롬프트 작성 (DALL-E는 영어가 더 잘 작동함)
    // 실제 촬영할 화면을 연필로 그린 것처럼 표현 (스토리보드 프레임/번호 없이)
    // 전체 씬의 스타일을 통일하기 위한 스타일 가이드 포함
    final prompt = '''
Draw the actual scene content that will be filmed, as a pencil sketch. This is NOT a storyboard - it's the actual scene content drawn in pencil.

Scene: "$sceneTitle"
Location: $location
${summary.isNotEmpty ? 'What happens in this scene: $summary' : ''}

Required shot composition (from checklist): "$selectedChecklistItem"

Draw ONLY the scene content that the camera will capture, following this composition:
- The real location and environment (cafe, beach, gym, etc.) as it appears in real life
- People and objects that will appear in the shot, exactly as they would be filmed
- The atmosphere and mood of the scene
- The composition must match the checklist item: $selectedChecklistItem
  * If it mentions "wide shot" or "와이드", show the full scene with wide framing (what a wide shot camera sees)
  * If it mentions "close-up" or "클로즈업", show a close-up view (what a close-up camera sees)
  * If it mentions "medium shot" or "미디엄", show a medium framing (what a medium shot camera sees)
  * Follow the specific composition described in the checklist

**CRITICAL - This is NOT a storyboard sketch. Draw ONLY the scene content:**
- NO storyboard frames, borders, boxes, or panels
- NO scene numbers, labels, text, or annotations of any kind
- NO pencils, drawing tools, hands drawing, or "drawing in progress" elements
- NO storyboard-style formatting or layout
- NO technical diagrams, camera angle indicators, or film production elements
- NO grid lines, panel dividers, or comic book style frames
- Just the pure scene content - imagine you took a photo of the actual scene and converted it to a pencil sketch
- The image should fill the entire frame with scene content only

**UNIFIED STYLE GUIDE (apply consistently to all scenes):**
- Simple black and white pencil sketch, hand-drawn style
- Draw the scene exactly as it would appear if you photographed it, then converted to pencil sketch
- Consistent line weight: medium-thin pencil lines (not too thick, not too thin)
- Consistent shading: light hatching or cross-hatching for depth, minimal shading
- Consistent character style: simple stick figures or simplified human forms (same style across all scenes)
- Consistent environment style: minimal line work for backgrounds, focus on main subjects
- No colors, no detailed rendering, just clean pencil sketch lines
- Consistent artistic style throughout - all scenes should look like they were drawn by the same artist with the same pencil
- Keep it simple, clean, and sketch-like with consistent pencil line quality

The image should show WHAT the camera will capture, drawn in pencil sketch style, following the composition from the checklist.
It should look like a photograph of the scene converted to pencil sketch - NOT a storyboard panel or frame.
The entire image should be filled with scene content only - no borders, no frames, no storyboard elements.
Maintain the unified style guide above to ensure all scenes have a consistent visual appearance.
''';

    return prompt.trim();
  }

  /// 배치 생성 (여러 씬의 이미지를 동시에 생성)
  /// 
  /// 비용과 시간을 고려하여 순차 생성
  static Future<List<String?>> generateMultipleStoryboards({
    required List<Map<String, dynamic>> scenes,
  }) async {
    final results = <String?>[];

    for (var i = 0; i < scenes.length; i++) {
      final scene = scenes[i];
      
      print('[DALLE] 씬 ${i + 1}/${scenes.length} 이미지 생성 중...');
      
      final imageUrl = await generateStoryboardImage(
        sceneTitle: scene['title'] ?? '',
        shotComposition: scene['shotComposition'] ?? [],
        shootingInstructions: scene['shootingInstructions'] ?? [],
        location: scene['location'] ?? '',
        summary: scene['summary'] ?? '',
        checklist: scene['checklist'] ?? [],
      );

      results.add(imageUrl);

      // API Rate Limit 고려 (필요시 대기)
      if (i < scenes.length - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    return results;
  }

  /// 체크리스트 항목 하나에 대한 구도 이미지 생성
  ///
  /// [sceneTitle]: 씬 제목
  /// [checklistItem]: 체크리스트 항목 (예: "와이드 샷으로 전체 장면 포착")
  /// [location]: 촬영 장소
  /// [vlogTitle]: 브이로그 전체 제목 (컨텍스트)
  /// [sceneDescription]: 씬 설명
  static Future<String?> generateCompositionImage({
    required String sceneTitle,
    required String checklistItem,
    required String location,
    String? vlogTitle,
    String? sceneDescription,
  }) async {
    try {
      if (_apiKey == null || _apiKey!.isEmpty) {
        print('[DALLE] API 키가 설정되지 않았습니다');
        return null;
      }

      // 간단한 프롬프트 생성
      final prompt = _generateCompositionPrompt(
        sceneTitle: sceneTitle,
        checklistItem: checklistItem,
        location: location,
        vlogTitle: vlogTitle,
        sceneDescription: sceneDescription,
      );

      print('[DALLE] 구도 이미지 생성 시작');
      print('[DALLE] 프롬프트: $prompt');

      final client = _createHttpClient();
      try {
        final response = await client.post(
          Uri.parse(_openaiImageUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': 'dall-e-3',
            'prompt': prompt,
            'n': 1,
            'size': '1024x1024',
            'quality': 'standard',
            'style': 'natural',
          }),
        ).timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            throw Exception('DALL-E API 타임아웃');
          },
        );

        if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dalleImageUrl = data['data'][0]['url'] as String;

        print('[DALLE] 구도 이미지 생성 성공: $dalleImageUrl');
        
        // TODO: Firebase Storage 업로드 로직 (Firebase 결제 활성화 후 주석 해제)
        // Firebase Storage에 업로드
        // final timestamp = DateTime.now().millisecondsSinceEpoch;
        // final scenePath = sceneTitle.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w-]'), '_');
        // final checklistPath = checklistItem.substring(0, checklistItem.length > 20 ? 20 : checklistItem.length)
        //     .replaceAll(' ', '_').replaceAll(RegExp(r'[^\w-]'), '_');
        // final storagePath = 'composition_images/${scenePath}_${checklistPath}_$timestamp.png';
        // 
        // print('[DALLE] Firebase Storage 업로드 시작...');
        // final firebaseUrl = await FirebaseStorageService().uploadImageFromUrl(
        //   imageUrl: dalleImageUrl,
        //   path: storagePath,
        // );
        // 
        // if (firebaseUrl != null) {
        //   print('[DALLE] Firebase Storage 업로드 완료: $firebaseUrl');
        //   return firebaseUrl;
        // } else {
        //   print('[DALLE] Firebase Storage 업로드 실패, DALL-E URL 반환');
        //   // 업로드 실패 시 원본 URL 반환 (임시)
        //   return dalleImageUrl;
        // }
        
          // 임시: DALL-E URL 그대로 반환
          return dalleImageUrl;
        } else {
          print('[DALLE] API 오류: ${response.statusCode}');
          print('[DALLE] 응답: ${response.body}');
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('[DALLE] 구도 이미지 생성 오류: $e');
      return null;
    }
  }

  /// 체크리스트 항목을 위한 프롬프트 생성 (엄격한 버전)
  static String _generateCompositionPrompt({
    required String sceneTitle,
    required String checklistItem,
    required String location,
    String? vlogTitle,
    String? sceneDescription,
  }) {
    final prompt = '''
Draw the actual scene content that will be filmed, as a pencil sketch. This is NOT a storyboard - it's the actual scene content drawn in pencil.

${vlogTitle != null ? 'Vlog: "$vlogTitle"' : ''}
Scene: "$sceneTitle"
Location: $location
${sceneDescription != null ? 'What happens in this scene: $sceneDescription' : ''}

Required shot composition (from checklist): "$checklistItem"

Draw ONLY the scene content that the camera will capture, following this composition:
- The real location and environment ($location) as it appears in real life
- People and objects that will appear in the shot, exactly as they would be filmed
- The atmosphere and mood of the scene
- The composition must match the checklist item: $checklistItem
  * If it mentions "wide shot" or "와이드", show the full scene with wide framing (what a wide shot camera sees)
  * If it mentions "close-up" or "클로즈업", show a close-up view (what a close-up camera sees)
  * If it mentions "medium shot" or "미디엄", show a medium framing (what a medium shot camera sees)
  * Follow the specific composition described in the checklist

**CRITICAL - This is NOT a storyboard sketch. Draw ONLY the scene content:**
- NO storyboard frames, borders, boxes, or panels
- NO scene numbers, labels, text, or annotations of any kind
- NO pencils, drawing tools, hands drawing, or "drawing in progress" elements
- NO storyboard-style formatting or layout
- NO technical diagrams, camera angle indicators, or film production elements
- NO grid lines, panel dividers, or comic book style frames
- Just the pure scene content - imagine you took a photo of the actual scene and converted it to a pencil sketch
- The image should fill the entire frame with scene content only

**UNIFIED STYLE GUIDE (apply consistently to all composition images):**
- Simple black and white pencil sketch, hand-drawn style
- Draw the scene exactly as it would appear if you photographed it, then converted to pencil sketch
- Consistent line weight: medium-thin pencil lines (not too thick, not too thin)
- Consistent shading: light hatching or cross-hatching for depth, minimal shading
- Consistent character style: simple stick figures or simplified human forms (same style across all compositions)
- Consistent environment style: minimal line work for backgrounds, focus on main subjects
- No colors, no detailed rendering, just clean pencil sketch lines
- Consistent artistic style throughout - all compositions should look like they were drawn by the same artist with the same pencil
- Keep it simple, clean, and sketch-like with consistent pencil line quality

The image should show WHAT the camera will capture, drawn in pencil sketch style, following the composition from the checklist.
It should look like a photograph of the scene converted to pencil sketch - NOT a storyboard panel or frame.
The entire image should be filled with scene content only - no borders, no frames, no storyboard elements.
Maintain the unified style guide above to ensure all composition images have a consistent visual appearance.
''';

    return prompt.trim();
  }

  /// 스타일 변형 프롬프트 생성 (다양한 스케치 스타일)
  static String _generatePromptWithStyle({
    required String sceneTitle,
    required List<String> shotComposition,
    required String location,
    String style = 'sketch', // 'sketch', 'stickman', 'comic', 'technical'
  }) {
    final compositionText = shotComposition.isNotEmpty
        ? shotComposition.join(', ')
        : 'medium shot';

    final styleDescriptions = {
      'sketch': 'Simple pencil sketch, hand-drawn storyboard style',
      'stickman': 'Ultra-simple stick figure storyboard, minimalist line drawing',
      'comic': 'Comic book panel style sketch, clear compositions',
      'technical': 'Technical film storyboard, professional cinematography sketch',
    };

    final styleDesc = styleDescriptions[style] ?? styleDescriptions['sketch']!;

    return '''
$styleDesc for a vlog scene.

Scene: "$sceneTitle" at $location
Composition: $compositionText

Black and white, simple line art. Focus on composition and framing.
No detailed rendering, just clear storyboard sketch.
''';
  }
}
