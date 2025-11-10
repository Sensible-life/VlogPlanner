# Fine-tuned Model 사용 가이드

## 개요

이 프로젝트는 OpenAI의 Fine-tuned GPT-4o 모델을 사용하여 사용자 입력으로부터 완전한 브이로그 스토리보드를 생성합니다.

**Fine-tuned Model ID**: `ft:gpt-4o-2024-08-06:ael-kaist:vlog-template-v1:CUv7VoVY`

## 주요 기능

Fine-tuned model을 사용하면 다음 정보들이 포함된 완전한 스토리보드가 생성됩니다:

### 1. 스토리보드 기본 정보
- **브이로그 제목**: 사용자 입력에 맞는 매력적인 제목
- **키워드 3개**: 브이로그를 요약하는 핵심 키워드 (예: "일상", "친구들과", "낮, 맑음")
- **촬영 장비**: 스마트폰, DSLR 등
- **촬영 길이**: 목표 영상 길이 (분)
- **씬 개수**: 최소 10개 이상
- **촬영 예산**: 입장료, 식비, 기타 포함
- **등장 인물**: 촬영 인원
- **영상 톤**: 밝고 경쾌, 차분한 등

### 2. 스타일/톤 분석 (레이더 차트용)
다음 6개 항목에 대해 1-5 점수로 분석됩니다:
- **감정 표현**: 감정의 풍부함과 다양성
- **동작**: 움직임의 활발함
- **강도**: 에너지와 몰입도
- **장소 다양성**: 촬영 장소의 다양성
- **속도/리듬**: 영상의 템포
- **흥분/놀람**: 예상치 못한 이벤트와 재미 요소

### 3. 촬영 동선 (구글맵 마커용)
- 실제 **위도/경도 좌표**를 포함한 촬영 장소 목록
- 촬영 순서대로 정렬
- 각 장소에 대한 설명
- 예상 이동 시간

### 4. 세부 씬 정보 (최소 10개)
각 씬마다 다음 정보가 포함됩니다:
- **요약본**: 씬에 대한 간단한 설명 (2줄)
- **촬영 시간**: 씬별 할당 시간 (초)
- **간단한 대본**: 3-5줄의 나레이션/대화
- **촬영 스텝**: 3단계 촬영 가이드
- **체크리스트**: 촬영 전 확인 사항 3개
- **Pro 팁**: 프레이밍, 오디오, 편집 힌트 등

### 5. 촬영 준비 체크리스트
전체 촬영을 위한 종합 체크리스트

## 사용 방법

### 1. 기본 사용법

```dart
import 'package:graduationdesign/services/openai_service.dart';

// 사용자 입력 준비
final userInput = {
  'target_duration': '8',  // 분
  'location': '오월드',
  'visit_context': '친구들과',
  'time_weather': '낮, 맑음',
  'equipment': '스마트폰',
  'difficulty': 'novice',
  'budget': '50000',  // 원
};

// Fine-tuned model로 스토리보드 생성
final storyboard = await OpenAIService.generateStoryboardWithFineTunedModel(userInput);

if (storyboard != null) {
  // Plan과 CueCards 파싱
  final result = await OpenAIService.parseStoryboard(storyboard);

  if (result != null) {
    final plan = result.plan;
    final cueCards = result.cueCards;

    // VlogDataService에 저장
    final dataService = VlogDataService();
    dataService.setUserInput(userInput);
    dataService.setPlan(plan!);
    dataService.setCueCards(cueCards!);

    print('스토리보드 생성 완료!');
    print('제목: ${plan.vlogTitle}');
    print('키워드: ${plan.keywords.join(", ")}');
    print('씬 개수: ${cueCards.length}');
  }
}
```

### 2. UI에서 사용하기

user_input_page.dart에서 사용자 입력을 받은 후:

```dart
// 사용자 입력을 받은 후
final userInput = {
  'target_duration': _targetDuration,
  'location': _selectedLocation,
  'visit_context': _visitContext,
  'time_weather': _timeWeather,
  'equipment': _equipment,
  'difficulty': _difficulty,
  'budget': _budget,
};

// Loading 다이얼로그 표시
showLoadingDialog(context, '스토리보드 생성 중...');

try {
  // Fine-tuned model로 스토리보드 생성
  final storyboard = await OpenAIService.generateStoryboardWithFineTunedModel(userInput);

  if (storyboard != null) {
    final result = await OpenAIService.parseStoryboard(storyboard);

    if (result != null) {
      // VlogDataService에 저장
      final dataService = VlogDataService();
      dataService.setUserInput(userInput);
      dataService.setPlan(result.plan!);
      dataService.setCueCards(result.cueCards!);

      // 스토리보드 페이지로 이동
      Navigator.pop(context); // 다이얼로그 닫기
      Navigator.pushNamed(context, '/storyboard');
    }
  }
} catch (e) {
  Navigator.pop(context); // 다이얼로그 닫기
  showErrorDialog(context, '스토리보드 생성 중 오류가 발생했습니다: $e');
}
```

## 응답 데이터 구조

### Plan 객체
```dart
Plan {
  vlogTitle: "친구들과 오월드 나들이! 🎢",
  keywords: ["일상", "친구들과", "낮, 맑음"],
  goalDurationMin: 8,
  bufferRate: 0.12,
  chapters: [...],
  styleAnalysis: StyleAnalysis {
    tone: "밝고 경쾌",
    vibe: "MZ 감성",
    pacing: "빠른 템포",
    emotionalExpression: 4,  // 1-5
    movement: 3,
    intensity: 4,
    locationDiversity: 3,
    speedRhythm: 4,
    excitementSurprise: 5,
    visualStyle: [...],
    audioStyle: [...],
  },
  shootingRoute: ShootingRoute {
    locations: [
      LocationPoint {
        name: "메인 게이트",
        description: "입구에서 오프닝 촬영",
        latitude: 36.8109,
        longitude: 127.1498,
        order: 1,
      },
      ...
    ],
    routeDescription: "효율적인 동선 설명",
    estimatedWalkingMinutes: 45,
  },
  budget: Budget {
    totalBudget: 50000,
    currency: "KRW",
    items: [...],
  },
}
```

### CueCard 객체
```dart
CueCard {
  title: "오월드 도착!",
  allocatedSec: 30,
  trigger: "entrance",
  summary: ["오월드 도착!", "친구들과 함께 입구에서 소개"],
  steps: ["게이트 앞 서기", "소개 멘트 하기", "마이크 체크"],
  checklist: ["노출 고정", "마이크 확인", "포커스 락"],
  fallback: "사람 많으면 인서트 촬영",
  startHint: "표지판 보일 때",
  stopHint: "나레이션 완료",
  completionCriteria: "표지판 + 나레이션",
  tone: "밝고 경쾌",
  styleVibe: "MZ",
  targetAudience: "20대",
  script: "나레이션: 오늘은 친구들과 오월드에 왔어요!\n주인공: 날씨도 좋고 기분 좋네요~\n친구1: 오늘 뭐 탈까?",
  pro: CueCardPro {
    framing: ["상1/3 구도", "워킹 최소"],
    audio: ["입 30~40cm"],
    dialogue: ["드디어 도착했어요!", "오늘 날씨 완전 좋네요"],
    editHint: ["인서트→점프컷"],
    safety: ["통행 방해 금지"],
    broll: ["표지판 클로즈업", "하늘 촬영", "발걸음"],
  },
}
```

## 데이터 활용

### VlogDataService를 통한 데이터 접근

```dart
final dataService = VlogDataService();

// 기본 정보
String vlogTitle = dataService.getVlogTitle();
String keywords = dataService.getKeywordsString();
String equipment = dataService.getEquipment();
String duration = dataService.getDuration();
String sceneCount = dataService.getSceneCount();
String totalBudget = dataService.getTotalBudget();

// 레이더 차트 점수
int emotionalExpression = dataService.getEmotionalExpression();
int movement = dataService.getMovement();
int intensity = dataService.getIntensity();
int locationDiversity = dataService.getLocationDiversity();
int speedRhythm = dataService.getSpeedRhythm();
int excitementSurprise = dataService.getExcitementSurprise();

// 촬영 동선
List<LocationPoint> locations = dataService.getShootingLocations();
String routeDescription = dataService.getRouteDescription();

// 예산 상세
List<BudgetItem> budgetItems = dataService.getBudgetItems();

// 씬 리스트
List<CueCard> scenes = dataService.cueCards ?? [];
```

## 주의사항

1. **API 키 설정**: OpenAI API 키가 [ApiConfig](lib/config/api_config.dart)에 설정되어 있어야 합니다.

2. **모델 ID**: Fine-tuned model ID가 정확해야 합니다:
   ```dart
   static const String _fineTunedModel = 'ft:gpt-4o-2024-08-06:ael-kaist:vlog-template-v1:CUv7VoVY';
   ```

3. **응답 시간**: Fine-tuned model은 많은 데이터를 생성하므로 응답 시간이 10-30초 정도 걸릴 수 있습니다.

4. **최소 씬 개수**: 프롬프트에서 최소 10개의 씬을 요청하지만, 실제로는 사용자의 목표 길이에 따라 달라질 수 있습니다.

5. **GPS 좌표**: 촬영 장소의 GPS 좌표는 실제 장소를 기반으로 생성되므로 정확합니다.

## 에러 처리

```dart
try {
  final storyboard = await OpenAIService.generateStoryboardWithFineTunedModel(userInput);

  if (storyboard == null) {
    print('스토리보드 생성 실패: API 응답이 null입니다.');
    return;
  }

  final result = await OpenAIService.parseStoryboard(storyboard);

  if (result == null) {
    print('스토리보드 파싱 실패: 데이터 형식이 올바르지 않습니다.');
    return;
  }

  // 성공
  final plan = result.plan;
  final cueCards = result.cueCards;

} catch (e) {
  print('에러 발생: $e');
  // 에러 처리
}
```

## 참고 파일

- [lib/constants/prompts.dart](lib/constants/prompts.dart) - Fine-tuned model 프롬프트
- [lib/services/openai_service.dart](lib/services/openai_service.dart) - API 호출 로직
- [lib/services/vlog_data_service.dart](lib/services/vlog_data_service.dart) - 데이터 관리
- [lib/models/plan.dart](lib/models/plan.dart) - Plan 데이터 모델
- [lib/models/cue_card.dart](lib/models/cue_card.dart) - CueCard 데이터 모델
- [lib/screens/storyboard/storyboard_page.dart](lib/screens/storyboard/storyboard_page.dart) - 스토리보드 UI

## 문의

Fine-tuned model 관련 문의사항이 있으면 프로젝트 관리자에게 문의해주세요.
