# 고급 Script 생성 가이드: 행동 지시 포함 대본

## 개요

`scene_contexts.json`과 `merged_text_content.json`을 활용하여 영화나 연극 대본처럼 **행동과 상황을 포함한** 고품질 스크립트를 생성합니다.

## 데이터 구조 활용

### 1. scene_contexts.json 구조
```json
{
  "timestamp": 5.0,
  "activity": "A person is adjusting their hair, possibly preparing for a video recording.",
  "location": "Indoor, likely a living room or personal space.",
  "mood": "Casual and relaxed.",
  "key_elements": ["Person in a white outfit", "sofa with cushions", "wall art"],
  "scene_type": "Introduction."
}
```

### 2. merged_text_content.json 구조
```json
{
  "timestamp": "[00:00:28]",
  "source": "VOICE",  // 또는 "SCREEN"
  "text": "아, 나 진짜 너무 좋아."
}
```

## 활용 방법

### 컨텍스트 데이터 추출 예시

```dart
// 타임스탬프에 맞는 데이터 추출
Map<String, dynamic> extractContextForTimestamp(
  List<dynamic> sceneContexts,
  List<dynamic> mergedContent,
  double targetTimestamp,
) {
  // scene_contexts.json에서 가장 가까운 씬 찾기
  Map<String, dynamic>? closestScene;
  double minDiff = double.infinity;
  
  for (var scene in sceneContexts) {
    double diff = (scene['timestamp'] as num - targetTimestamp).abs();
    if (diff < minDiff) {
      minDiff = diff;
      closestScene = scene as Map<String, dynamic>;
    }
  }
  
  // merged_text_content.json에서 해당 타임스탬프의 텍스트 찾기
  List<String> relevantTexts = [];
  for (var item in mergedContent) {
    String timestampStr = item['timestamp'] as String;
    double itemTime = _parseTimestamp(timestampStr);
    if ((itemTime - targetTimestamp).abs() <= 2.0) { // 2초 범위
      relevantTexts.add(item['text'] as String);
    }
  }
  
  return {
    'activity': closestScene?['activity'],
    'location': closestScene?['location'],
    'mood': closestScene?['mood'],
    'key_elements': closestScene?['key_elements'],
    'scene_type': closestScene?['scene_type'],
    'transcript': relevantTexts.join('\n'),
  };
}
```

### Script 생성 호출

```dart
// 씬별 script 생성
final contextData = {
  'activity': 'A person is working on a laptop while talking on the phone.',
  'location': 'Indoor, likely a living room.',
  'mood': 'Calm and focused.',
  'key_elements': ['Laptop', 'phone', 'sofa', 'potted plant', 'guitar'],
  'scene_type': 'Dialogue.',
  'transcript': '아니 제가 링크 스테이션에서만 일하니까 좀 효율이 안 나는 것 같아서...',
};

final script = await OpenAIService.generateScriptForScene(
  sceneSummary: '공유오피스 가는 이유 설명',
  sceneLocation: '거실',
  tone: '자연스럽고 친근',
  vibe: '일상',
  durationSec: 30,
  contextData: contextData,
);
```

## 프롬프트 향상

`openai_service.dart`의 프롬프트를 영화 대본 스타일로 확장:

```dart
// 추천 프롬프트 형식
'''
당신은 프로 브이로그 시나리오 작가입니다.
실제 영화나 연극 대본처럼 행동과 상황을 포함한 대본을 작성해주세요.

[실제 브이로그 예시]

예시 1 - 행동과 대사 포함:
"[00:00:28] 거실에서 노트북을 보며 반 친구와 통화
- 자문자답으로 공유오피스 결정한 이유 설명 (밝은 톤, 가끔 미소)
- 화면: 거실 풍경 + 노트북 화면
대사: "아니 제가 링크 스테이션에서만 일하니까 좀 효율이 안 나는 것 같아서...""

예시 2 - 상황 전환:
"[00:01:51] 공유오피스 도착
- 문을 열며 즐거운 표정
- 화면: 오피스 내부 + 자신의 모습
대사: "저는 도착했습니다~"

[생성할 씬 정보]
${contextData}
- 활동: ${activity}
- 장소: ${location}
- 분위기: ${mood}
- 주요 요소: ${key_elements.join(', ')}
- 대사 참고: ${transcript}

위 정보를 바탕으로 영화 대본처럼 작성해주세요:
1. 타임스탬프로 씬 시작
2. 행동과 장소 묘사
3. 대사 (나레이션)
4. 화면 구성 힌트
'''
```

## 실제 구현 예시

### 1. 씬 컨텍스트 서비스 생성

```dart
// lib/services/vlog_context_service.dart
class VlogContextService {
  // scene_contexts.json과 merged_text_content.json 파싱
  static Map<String, dynamic> getContextData(
    Map<String, dynamic> sceneContexts,
    Map<String, dynamic> mergedContent,
    int targetSeconds,
  ) {
    // scene_contexts.json에서 가장 가까운 씬 찾기
    final scene = findClosestScene(sceneContexts, targetSeconds);
    
    // merged_text_content.json에서 해당 타임스탬프의 텍스트 찾기
    final transcripts = findTranscripts(mergedContent, targetSeconds);
    
    return {
      'activity': scene['activity'],
      'location': scene['location'],
      'mood': scene['mood'],
      'key_elements': scene['key_elements'] ?? [],
      'scene_type': scene['scene_type'],
      'transcript': transcripts.join('\n'),
      'timestamp': scene['timestamp'],
    };
  }
  
  static Map<String, dynamic> findClosestScene(
    Map<String, dynamic> scenes,
    int targetSeconds,
  ) {
    double minDiff = double.infinity;
    Map<String, dynamic>? closest;
    
    for (var scene in (scenes['scenes'] as List)) {
      double sceneTimestamp = (scene['timestamp'] as num).toDouble();
      double diff = (sceneTimestamp - targetSeconds).abs();
      
      if (diff < minDiff) {
        minDiff = diff;
        closest = scene as Map<String, dynamic>;
      }
    }
    
    return closest ?? {};
  }
  
  static List<String> findTranscripts(
    Map<String, dynamic> mergedContent,
    int targetSeconds,
  ) {
    List<String> results = [];
    
    for (var item in (mergedContent['merged_segments'] as List)) {
      String timestampStr = item['timestamp'] as String;
      double itemTime = parseTimestamp(timestampStr);
      
      // 타임스탬프 ±2초 범위
      if ((itemTime - targetSeconds).abs() <= 2.0) {
        results.add(item['text'] as String);
      }
    }
    
    return results;
  }
  
  static double parseTimestamp(String timestampStr) {
    // "[00:00:28]" 형식을 초로 변환
    String cleaned = timestampStr.replaceAll('[', '').replaceAll(']', '');
    List<String> parts = cleaned.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    int seconds = int.parse(parts[2]);
    return hours * 3600 + minutes * 60 + seconds;
  }
}
```

### 2. 향상된 Script 생성

```dart
// lib/services/openai_service.dart에 추가
static Future<String?> generateAdvancedScript({
  required int targetSecond,
  required Map<String, dynamic> sceneContexts,
  required Map<String, dynamic> mergedContent,
}) async {
  // 컨텍스트 데이터 추출
  final contextData = VlogContextService.getContextData(
    sceneContexts,
    mergedContent,
    targetSecond,
  );
  
  // 프롬프트 생성
  final prompt = _buildAdvancedScriptPrompt(contextData);
  
  // GPT 호출 (위에서 만든 프롬프트 사용)
  return await generateScriptForScene(
    sceneSummary: contextData['activity'] ?? '',
    sceneLocation: contextData['location'] ?? '',
    tone: _determineTone(contextData['mood']),
    vibe: '일상',
    durationSec: 30,
    contextData: contextData,
  );
}

static String _buildAdvancedScriptPrompt(Map<String, dynamic> contextData) {
  return '''
당신은 프로 브이로그 시나리오 작가입니다.
실제 영화나 연극 대본처럼 행동과 상황을 포함한 대본을 작성해주세요.

[씬 정보]
- 활동: ${contextData['activity']}
- 장소: ${contextData['location']}
- 분위기: ${contextData['mood']}
- 주요 요소: ${contextData['key_elements']?.join(', ') ?? '없음'}
- 씬 타입: ${contextData['scene_type']}
- 타임스탬프: ${contextData['timestamp']}초

[참고 Transcript]
${contextData['transcript']}

위 정보를 바탕으로 다음 형식으로 작성해주세요:

[타임스탬프] 장면: [장소]
활동: [행동 묘사]
대사: "[실제 대사]"
화면 구성: [촬영 힌트]

- 행동과 상황을 구체적으로 묘사
- 실제 브이로거가 말하는 것처럼 자연스럽게
- 화면 구성을 명확히 제시
''';
}
```

## 최종 사용 예시

```dart
// 1. 데이터 로드
final sceneContexts = await FileService.loadJson(
  'template_extract/outputs/work_01/scene_contexts.json',
);
final mergedContent = await FileService.loadJson(
  'template_extract/outputs/work_01/merged_text_content.json',
);

// 2. 특정 씬의 대본 생성
final script = await OpenAIService.generateAdvancedScript(
  targetSecond: 28,  // 28초 지점
  sceneContexts: sceneContexts,
  mergedContent: mergedContent,
);

// 결과 예시:
// [00:00:28] 장면: 거실
// 활동: 노트북을 앞에 두고 반 친구와 통화하며 공유오피스 가는 이유 설명
// 대사: "아니 제가 링크 스테이션에서만 일하니까 좀 효율이 안 나는 것 같아서 같이 일하는 공유 오피스로 가고 있거든요?"
// 화면 구성: 거실 풍경 (소파, 식물, 기타) + 노트북 화면 클로즈업
```

## 장점

1. **구체적 행동 지시**: 단순 대사가 아닌 행동까지 포함
2. **화면 구성 명확**: 촬영할 때 정확히 무엇을 찍을지 알 수 있음
3. **자연스러운 대사**: 실제 transcript 기반이라 자연스러움
4. **상황 반영**: 장소, 분위기, 주요 요소 모두 반영

이렇게 하면 영화 대본처럼 완성도 높은 스크립트를 생성할 수 있습니다!

