# Script 생성 방식 결정: GPT-4o vs Fine-tuning

## 현재 상황 분석

### 보유 자산
- ✅ Fine-tuned model (vlog-template-v1) - 스토리보드 생성용
- ✅ GPT-4o 사용 중 - Script 생성용
- ✅ template_extract/outputs 데이터 20+ 개 영상
- ✅ scene_contexts.json, merged_text_content.json 등 구조화된 데이터

## 두 가지 옵션 비교

### Option 1: GPT-4o + 프롬프트 개선 (추천 ⭐)

#### 장점
| 항목 | 설명 |
|------|------|
| **즉시 사용** | 지금 당장 구현 가능 |
| **유연성** | 다양한 씬에 대응 가능 |
| **개발 시간** | 1-2일 |
| **비용** | API 호출당 약 $0.01-0.03 (매번 발생) |
| **유지보수** | 프롬프트 수정으로 빠른 개선 |
| **데이터 활용** | template_extract 데이터 실시간 반영 |

#### 단점
- API 호출 비용 지속적 발생
- 토큰 제한 (약 128K)
- 매 호출마다 GPT 처리 필요

#### 구현 방식
```dart
// scene_contexts.json + merged_text_content.json 활용
final contextData = {
  'activity': sceneContexts['activity'],
  'location': sceneContexts['location'],
  'mood': sceneContexts['mood'],
  'transcript': mergedContent['text'],
  'ocr_results': onscreenText,
};

final script = await OpenAIService.generateScriptForScene(
  contextData: contextData, // 이렇게 넘겨줌
);
```

---

### Option 2: 새로운 Fine-tuned Model

#### 장점
- 일관된 성능
- 학습된 패턴 재사용
- 장기적으로 비용 효율적 (사용량 많을 경우)

#### 단점
| 항목 | 문제점 |
|------|--------|
| **초기 비용** | $10-50 (학습 비용) |
| **데이터 준비** | JSONL 변환, 50-100개 샘플 필요 |
| **학습 시간** | 수일 소요 |
| **고정성** | 학습 후 수정 어려움 |
| **개발 시간** | 1-2주 (데이터 준비 포함) |
| **유지보수** | 새 데이터 추가 시 재학습 필요 |

#### 필요한 데이터 형식
```jsonl
{"messages": [{"role": "system", "content": "You are a vlog script writer..."}, {"role": "user", "content": "{scene_contexts + transcript}"}, {"role": "assistant", "content": "{예상 스크립트}"}]}
{"messages": [...]}
// 50-100개 필요
```

---

## 결론: GPT-4o + 프롬프트 개선 추천 ⭐

### 결정 근거

1. **현재 상황**
   - 이미 20+ 개의 추출된 데이터 보유
   - scene_contexts.json과 merged_text_content.json 완성
   - 개발 시간 제약 (졸업 작품)

2. **효과 비교**
   - GPT-4o는 Few-shot + 컨텍스트로 충분히 좋은 결과
   - Fine-tuning은 초기 투자 대비 즉시 효과 불확실
   
3. **비용 효율**
   ```
   Fine-tuning 초기 비용: $30-50
   GPT-4o 사용 1,000회: $10-30
   
   → 1,000회 이상 사용해도 비슷한 비용
   → 하지만 개발 시간이 훨씬 빠름
   ```

4. **유연성**
   - 새로운 영상 추가 시 데이터만 넣으면 됨
   - Fine-tuning은 새 데이터로 재학습 필요

---

## 추천 구현 방식

### Phase 1: 즉시 구현 (현재 상태)
- GPT-4o + 컨텍스트 데이터 2-3개 (transcript, activity)
- 개발 시간: 없음 (이미 구현됨)

### Phase 2: 개선 (1-2일)
```dart
// 추가 데이터 활용
final contextData = {
  'transcript': transcriptData,
  'activity': sceneContexts['activity'],
  'location': sceneContexts['location'],
  'mood': sceneContexts['mood'],
  'key_elements': sceneContexts['key_elements'],
  'ocr_results': onscreenText,
};
```
- 추가 데이터: scene_contexts.json, onscreen_text.json
- 예상 효과: 30-40% 품질 향상

### Phase 3: Fine-tuning (나중에)
- 사용자가 늘어나고
- 사용 패턴이 안정화되면
- 그때 최적화된 Fine-tuned model 생성

---

## 실제 구현 예시

### 현재 (Phase 1)
```dart
final script = await OpenAIService.generateScriptForScene(
  sceneSummary: '씬 내용',
  sceneLocation: '장소',
  tone: '밝고 경쾌',
  vibe: 'MZ',
  durationSec: 30,
  contextData: {
    'transcript': '실제 대사',
  },
);
```

### Phase 2 개선
```dart
final script = await OpenAIService.generateScriptForScene(
  sceneSummary: sceneContexts['activity'],
  sceneLocation: sceneContexts['location'],
  tone: _determineTone(sceneContexts['mood']),
  vibe: '자연스러운',
  durationSec: 30,
  contextData: {
    'transcript': mergedContent['text'],
    'activity': sceneContexts['activity'],
    'location': sceneContexts['location'],
    'mood': sceneContexts['mood'],
    'key_elements': sceneContexts['key_elements'],
    'ocr_results': onscreenText,
  },
);
```

---

## 최종 권장사항

### 지금 바로 할 것
✅ **GPT-4o + scene_contexts.json, merged_text_content.json 활용**
- 개발 시간: 1-2일
- 효과: 즉시 체감
- 비용: 사용량에 따라

### 나중에 고려할 것
❌ **새로운 Fine-tuned model (지금은 NO)**
- 이유: 초기 비용 대비 효과 불확실
- 시기: 서비스 안정화 후

### 이유 요약
1. **빠른 성과**: 지금 당장 좋은 결과 필요
2. **유연성**: 다양한 씬에 대응
3. **비용**: Fine-tuning은 초기 투자 후 효과 불확실
4. **유지보수**: 프롬프트 수정이 재학습보다 빠름

---

## 결론

**지금은 GPT-4o + 풍부한 컨텍스트 데이터 사용을 강력 추천합니다.**

Fine-tuning은 서비스가 안정화되고 사용자가 늘어난 후에 ROI가 확실할 때 고려하세요.

