# 씬별 Script 생성 - 컨텍스트 활용 가이드

## 개요

실제 transcript, OCR 결과, 영상 맥락 분석 데이터를 활용하여 더 정확하고 자연스러운 대본을 생성하는 방법입니다.

## 접근 방법 비교

### 1. Fine-tuned Model 사용
**장점:**
- 높은 성능과 일관성
- 데이터 패턴 학습 가능

**단점:**
- 초기 데이터 수집 및 정제 작업 필요 (수백~수천 개 샘플)
- 모델 학습 비용 (수만~수십만원)
- 학습 시간 소요 (수일~수주)
- 새로운 데이터 반영 시 재학습 필요

**적합한 경우:**
- 확정된 스타일이 있고, 데이터가 충분할 때
- 장기적으로 고정된 서비스인 경우

### 2. 향상된 프롬프트 + 컨텍스트 데이터 사용 (추천)
**장점:**
- 즉시 사용 가능 (개발 시간 단축)
- 유연하고 빠른 수정 가능
- 추가 비용 없음
- 새로운 데이터 실시간 반영 가능

**단점:**
- GPT-4o 토큰 제한 (약 128K)
- 매번 API 호출 비용 발생

**적합한 경우:**
- 초기 프로토타입 및 빠른 개발
- 다양한 스타일 지원 필요
- 데이터가 계속 변화하는 경우

## 사용 방법

### 기본 사용 (컨텍스트 없음)

```dart
final script = await OpenAIService.generateScriptForScene(
  sceneSummary: '오월드 입장하는 장면',
  sceneLocation: '오월드 메인 게이트',
  tone: '밝고 경쾌',
  vibe: 'MZ',
  durationSec: 30,
);
```

### 컨텍스트 데이터 추가

```dart
// 실제 영상 데이터에서 추출한 정보
final contextData = {
  'transcript': '안녕하세요 여러분~ 오늘은 드디어 친구들이랑 오월드 왔어요! 완전 기대돼요~',
  'ocr_results': '오월드\nEverland\n입구 게이트\n티켓 부스',
  'visual_context': '비가 온 후 햇살이 쨍쨍한 날씨, 입구에 사람들이 많이 있음, 큐 카드 보이지 않음',
  'speaking_pattern': '밝고 경쾌한 톤, 자주 "~어요" 사용, 물음표와 느낌표 활용이 많음',
};

final script = await OpenAIService.generateScriptForScene(
  sceneSummary: '오월드 입장하는 장면',
  sceneLocation: '오월드 메인 게이트',
  tone: '밝고 경쾌',
  vibe: 'MZ',
  durationSec: 30,
  contextData: contextData, // 컨텍스트 데이터 전달
);
```

### 컨텍스트 데이터 필드 설명

| 필드 | 설명 | 예시 |
|------|------|------|
| `transcript` | 영상의 실제 대사 전사 | "안녕하세요~ 오늘은 드디어..." |
| `ocr_results` | 영상에서 추출한 텍스트 정보 | "메인 게이트\n티켓 구매\n..." |
| `visual_context` | 영상의 맥락과 상황 분석 | "맑은 날씨, 사람 많음,..." |
| `speaking_pattern` | 말투와 스타일 분석 | "밝은 톤, 간결한 문장, "~어요" 자주 사용" |

## 실제 구현 예시

### 1. Transcript 기반으로 말투 학습

```dart
// 실제 브이로그 영상에서 transcript 추출
final transcript = '와 진짜 맛있겠다! 일단 한입 먹어볼게요. 음~ 완전 맛있어! 가격도 합리적이고 양도 많아요~';

final contextData = {
  'transcript': transcript,
  'speaking_pattern': '감탄사("와", "~") 자주 사용, 느낌표 활용, 쉼표로 리듬감 표현',
};

final script = await OpenAIService.generateScriptForScene(
  sceneSummary: '음식 리뷰하는 장면',
  sceneLocation: '음식점',
  tone: '밝고 경쾌',
  vibe: 'MZ',
  durationSec: 40,
  contextData: contextData,
);
```

### 2. OCR 결과로 구체적인 내용 반영

```dart
final contextData = {
  'ocr_results': '''
티켓 가격: 50,000원
할인 정보: 학생 할인 20%
메뉴: 기본 버거 세트, 감자튀김 등
''',
  'visual_context': '패스트푸드점, 메뉴판에 여러 옵션 보임, 가격표가 명확함',
};

final script = await OpenAIService.generateScriptForScene(
  sceneSummary: '메뉴 주문하는 장면',
  sceneLocation: '패스트푸드점',
  tone: '밝고 경쾌',
  vibe: 'MZ',
  durationSec: 30,
  contextData: contextData,
);
```

### 3. 영상 맥락 분석으로 자연스러운 대본 생성

```dart
final contextData = {
  'visual_context': '비가 주룩주룩 내리고 있음, 우산을 쓰고 있음, 사람들이 빨리 걸어감, 분위기가 어두움',
};

final script = await OpenAIService.generateScriptForScene(
  sceneSummary: '비오는 날 이동하는 장면',
  sceneLocation: '거리',
  tone: '차분하게',
  vibe: '일상',
  durationSec: 20,
  contextData: contextData,
);
```

## 최적화 팁

### 1. 컨텍스트 데이터 길이 관리
- 너무 긴 데이터는 요약하여 제공
- 핵심 정보만 추출
- GPT-4o 토큰 제한 주의 (약 128K)

```dart
// ❌ 나쁜 예: 너무 긴 컨텍스트
final contextData = {
  'transcript': '전체 대사를 다 넣으면 토큰이 너무 많아짐...', // 수천 자
};

// ✅ 좋은 예: 핵심만 추출
final contextData = {
  'transcript': '말투 요약: "밝은 톤, "~어요" 자주 사용"',
  'speaking_pattern': '간결한 문장, 느낌표 활용 많음',
};
```

### 2. 반복 사용되는 패턴 추출
- 여러 영상을 분석하여 공통 말투 패턴 추출
- 패턴을 데이터베이스에 저장하여 재사용

```dart
// 공통 패턴을 데이터베이스에 저장
class SpeakingPattern {
  final String speakerId;
  final String commonPhrases; // "완전", "진짜", "~어요" 등
  final String punctuationStyle; // "느낌표 자주, 물음표 적게"
  final String tone; // "밝고 경쾌"
}

// 추출된 패턴 활용
final pattern = await db.getSpeakingPattern(speakerId);
final contextData = {
  'speaking_pattern': pattern.toString(),
};
```

### 3. 컨텍스트 데이터는 Optional로
- 컨텍스트 데이터가 없어도 기본 동작
- 데이터가 있을 때만 향상된 대본 생성

```dart
// 컨텍스트가 있을 때만 사용
if (contextData != null && contextData.isNotEmpty) {
  final enhancedScript = await OpenAIService.generateScriptForScene(
    // ...
    contextData: contextData,
  );
}
```

## 결론

**추천 방법:** 컨텍스트 데이터를 활용한 향상된 프롬프트 접근

1. **즉시 구현 가능**: Fine-tuning 대비 시간 단축
2. **유연성**: 다양한 상황에 대응 가능
3. **비용 효율**: 초기 투자 없음
4. **데이터 반영**: 실시간으로 새로운 데이터 활용

Fine-tuned Model은 사용자 규모가 커지고, 데이터가 충분히 축적된 후 고려하는 것을 권장합니다.

