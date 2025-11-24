# 프로젝트 리팩토링 계획 및 진행 상황

## 📋 작업 개요

대규모 리팩토링 작업으로, 스토리보드 생성 API 및 데이터 구조를 전면 개편합니다.

### 주요 목표
1. 불필요한 코드 및 파일 삭제
2. 코드 리팩토링 (중복 제거, 기능 통합)
3. **스토리보드 생성 API 및 응답/요청 구조 변경 (가장 중요)**

---

## ✅ 완료된 작업

### 1. 불필요한 파일 삭제 (7개)

다음 파일들이 더 이상 사용되지 않아 삭제되었습니다:

- `lib/screens/shooting/shooting_page.dart` - CameraModePage로 대체됨
- `lib/widgets/shooting_overlay.dart` - shooting_page와 함께 사용되던 위젯
- `lib/screens/storyboard/storyboard_page_old.dart` - 구버전 스토리보드 페이지
- `lib/screens/storyboard/storyboard_page_new.dart` - 중간 버전 스토리보드 페이지
- `lib/models/take.dart` - shooting_page에서만 사용
- `lib/models/shooting_session.dart` - shooting_page에서만 사용
- `lib/services/shake_detection_service.dart` - shooting_page에서만 사용

### 2. Plan 모델 구조 변경

**변경된 필드:**
```dart
class Plan {
  // 새로 추가된 필드
  final String equipment; // 촬영 도구 (기존 equipmentRecommendation을 명확하게)
  final int totalPeople; // 전체 촬영 인원
  final String userNotes; // 사용자 메모

  // 계산 필드 (getter)
  int get sceneCount; // 전체 씬 개수
  int get totalBudget; // 전체 예산
}
```

**LocationPoint 모델 변경:**
```dart
class LocationPoint {
  final List<String> sceneIds; // 각 위치와 씬 매핑
}
```

### 3. CueCard 모델 구조 변경

**새로운 촬영 정보:**
```dart
class CueCard {
  // 기존 script 대신 구체적인 정보로 변경
  final List<String> shotComposition; // 구도 정보
  final List<String> shootingInstructions; // 촬영 지시사항

  // 새로운 미디어 필드
  final String? storyboardImageUrl; // 스토리보드 스타일 이미지 (졸라맨/연필스케치)
  final String? referenceVideoUrl; // YouTube 레퍼런스 영상 URL

  // 씬 세부 정보
  final String location; // 촬영 장소
  final int cost; // 씬별 비용
  final int peopleCount; // 씬별 촬영 인원
  final int shootingTimeMin; // 예상 촬영 시간 (분)
}
```

---

## ✅ 완료된 작업 (계속)

### 3. API 프롬프트 수정 완료

**수정된 파일:**
- `lib/constants/prompts.dart` - JSON 응답 구조 및 요구사항 업데이트
- `lib/services/openai_service.dart` - 파싱 로직 업데이트

**변경된 API 응답 구조:**

#### 1. 시나리오 요약
- `summary` (기존) ✅

#### 2. 세부 정보
- `goal_duration_min` (시나리오 전체 길이) ✅
- `equipment` (촬영 도구) ✅ 추가됨
- `total_people` (촬영 인원) ✅ 추가됨
- `user_notes` (사용자 메모) ✅ 추가됨
- `style_analysis.tone` (전체 톤) ✅
- `scene_count` (씬 개수) ✅ 계산 필드
- `budget.total_budget` (전체 비용) ✅

#### 3. 촬영 동선 (Google Maps)
- `shooting_route.locations` ✅
- `LocationPoint.scene_ids` ✅ 추가됨

#### 4. 촬영 예산
- `budget` (전체 예산 세부 내역) ✅

#### 5. 연출 톤앤매너
- `style_analysis` ✅
- `style_analysis.rationale` (각 점수에 대한 이유) ✅

#### 6. 촬영 체크리스트 & 메모
- `shooting_checklist` ✅

#### 7. 각 씬 정보
각 CueCard에 추가된 필드:
- `shot_composition` (구도 정보) ✅ 프롬프트 추가 완료
- `shooting_instructions` (촬영 방법) ✅ 프롬프트 추가 완료
- `location` (장소) ✅ 프롬프트 추가 완료
- `cost` (비용) ✅ 프롬프트 추가 완료
- `people_count` (촬영 인원) ✅ 프롬프트 추가 완료
- `shooting_time_min` (촬영 시간) ✅ 프롬프트 추가 완료
- `storyboard_image_url` (스토리보드 이미지) ✅ 빈 값으로 준비됨 (이미지 생성은 다음 단계)
- `reference_video_url` (YouTube 레퍼런스) ✅ 빈 값으로 준비됨 (YouTube API는 다음 단계)

---

## ✅ 최근 완료된 작업 (2025-11-17)

### 8. 체크리스트 프롬프트 수정
**목적:** 촬영 준비물 체크리스트에서 촬영 샷 확인 체크리스트로 변경

**변경 내용:**
- 기존: "배터리 체크", "마이크 확인" 등 준비물 위주
- 변경: "와이드 샷 촬영 완료", "클로즈업 샷 촬영 완료" 등 촬영 구도 확인 위주
- 각 씬의 `checklist` 필드는 이제 "이 씬에서 이런 샷을 찍었는지" 확인하는 대본 역할
- `shot_composition`과 연관되어 촬영 시 가이드로 활용

**수정된 파일:**
- `lib/constants/prompts.dart` - checklist 설명 및 예시 업데이트

**프롬프트 추가 설명:**
```
checklist: 해당 씬의 촬영 확인 체크리스트 배열
- 촬영 중 꼭 찍어야 할 샷/구도 리스트
- 예: "와이드 샷 촬영 완료", "인물 클로즈업 완료", "반응샷 촬영 완료"
- 촬영 준비물이 아니라 "이 씬에서 이런 샷을 찍었는지" 확인하는 용도
- shot_composition과 연관되어야 하며, 실제 촬영 시 대본처럼 활용
```

### 9. UI 대격변 (메인/입력/스토리보드/씬리스트)

#### 9.1 새로운 컬러 시스템
- White: #FFFEFA
- Black: #303030
- Dark Gray: #A6A6A6
- Light Gray: #DFDFDF
- Key Yellow: #FFF6CC

#### 9.2 메인 페이지 (`home_page.dart`)
- 자산 기반 버튼 디자인으로 전환
- 카드뷰에 메인 이미지 표시
- 깔끔한 네비게이션 구조

#### 9.3 사용자 입력 페이지 (`user_input_page.dart`)
- 탭 기반 인터페이스 (3개 탭)
  - Concept & Style 탭
  - Detail Plan 탭
  - Environment 탭
- 노란색 선택 강조
- Mock Data 임시 생성 버튼 추가 (운동 브이로그)

#### 9.4 스토리보드 페이지 (`storyboard_page.dart`)
- 고정 상단 바 + 스크롤 가능한 컨텐츠
- 촬영 탭에 새 필드 표시:
  - 📷 구도 정보 (`shotComposition`)
  - 🎬 촬영 지시사항 (`shootingInstructions`)
- Drawer (사이드바) 추가:
  - 라이브러리 관리
  - 이전 스토리보드 목록
  - 새 스토리보드 생성

#### 9.5 세부 씬 리스트 (`scene_list_page.dart`)
- 드롭다운 카드 형태
- 항상 보이는 부분: 썸네일 / 제목 / **촬영하기 버튼**
- 클릭 시 펼쳐지는 부분: 촬영 체크리스트
- **촬영하기 버튼**: 카메라로 씬 정보 전달
  - 씬 번호, 제목, 체크리스트
  - 구도 정보, 촬영 지시사항
  - 스토리보드 이미지, 레퍼런스 비디오 URL

### 10. DALL-E API 스토리보드 이미지 생성

**구현 내용:**
- `lib/services/dalle_image_service.dart` 생성
- DALL-E 3 API 사용
- 각 씬의 구도를 표현한 스케치 스타일 이미지 생성

**프롬프트 특징:**
```
- Simple pencil sketch storyboard frame
- Clean line drawing, minimalist, hand-drawn feel
- Basic composition and framing
- Simple stick figures
- Black and white pencil drawing
```

**통합:**
- User Input 페이지에서 스토리보드 생성 시 자동으로 DALL-E 이미지 생성
- 각 씬당 약 10초 소요
- `storyboardImageUrl` 필드에 저장
- 씬 리스트와 카메라 페이지에서 표시

### 11. 카메라 페이지 씬 정보 전달

**변경 내용:**
- `CameraModePage`에 `sceneInfo` 파라미터 추가
- 씬 리스트에서 "촬영하기" 버튼 클릭 시 다음 정보 전달:
  ```dart
  {
    'sceneIndex': 씬 번호,
    'totalScenes': 전체 씬 개수,
    'title': 씬 제목,
    'allocatedSec': 할당 시간,
    'summary': 요약,
    'checklist': 촬영 확인 체크리스트,
    'shotComposition': 구도 정보,
    'shootingInstructions': 촬영 지시사항,
    'storyboardImageUrl': 스토리보드 이미지,
    'referenceVideoUrl': 레퍼런스 비디오,
    'referenceVideoTimestamp': 레퍼런스 시작 시점,
    // ... 기타 씬 정보
  }
  ```

**UI 업데이트:**
- 씬 제목 표시
- 전체 씬 개수 표시 (예: "씬 #2 / 5")
- 체크리스트를 sceneInfo에서 가져와 표시

### 12. YouTube 레퍼런스 비디오 기능 완성 (2025-11-17)

**구현 내용:**

#### 12.1 모델 업데이트
- `CueCard` 모델에 `referenceVideoTimestamp` 필드 추가 (초 단위 정수)
- 프롬프트에서 AI가 씬 구도와 가장 유사한 레퍼런스 영상의 timestamp 제공하도록 요청

#### 12.2 비디오 저장 시스템
- `VideoStorageService` 생성 (`lib/services/video_storage_service.dart`)
- 표준화된 파일명: `scene_{씬번호}_take_{테이크번호}_{timestamp}.mp4`
  - 예: `scene_03_take_02_20250117_143022.mp4`
- 이전 Take 검색: 파일명 패턴 매칭으로 동일 씬의 모든 Take 찾기
- 자동 Take 번호 증가: 씬별로 마지막 Take 번호 + 1

#### 12.3 YouTube Player 통합
- `youtube_player_flutter` 패키지 추가 (v9.1.3)
- 카메라 페이지 오른쪽에 YouTube 레퍼런스 플레이어 오버레이
- `referenceVideoTimestamp` 시점부터 자동 재생
- 음소거 상태로 루프 재생

#### 12.4 이전 Take 플레이어
- 카메라 페이지 왼쪽에 로컬 비디오 플레이어 오버레이
- 동일 씬의 이전 촬영본들을 최신순으로 표시
- 탭하여 다음 Take로 전환 (스와이프 효과)
- Take 번호 표시 (예: "Take 2/5")

#### 12.5 카메라 페이지 전면 개편
**새로운 기능:**
- ✅ 오른쪽 오버레이: YouTube 레퍼런스 (특정 timestamp부터 재생)
- ✅ 왼쪽 오버레이: 이전 Take 비디오 (여러 개 전환 가능)
- ✅ 자동 Take 번호 계산 및 표시
- ✅ 녹화 완료 시 표준화된 파일명으로 자동 저장
- ✅ 녹화 후 이전 Take 목록 자동 새로고침

**UI 컨트롤:**
- 왼쪽 하단 버튼: 이전 Take 오버레이 토글
- 중앙 하단 버튼: 녹화 시작/중지 (원형 → 사각형)
- 오른쪽 하단 버튼: YouTube 레퍼런스 오버레이 토글

**파일 구조:**
```
lib/
  services/
    video_storage_service.dart ← 새로 추가
  screens/
    camera/
      camera_mode_page.dart ← 전면 개편
      camera_mode_page_old.dart ← 백업
```

### 13. YouTube 레퍼런스 검색 기능 (2025-11-17)

**구현 내용:**

#### 13.1 YouTube Data API v3 통합
- `YoutubeSearchService` 생성 (`lib/services/youtube_search_service.dart`)
- 씬 키워드 기반 자동 검색
  - 씬 제목 + 구도 정보 + 브이로그 타입
  - 검색 쿼리 자동 생성 로직
- API 할당량 관리 (검색 간 500ms 딜레이)

#### 13.2 검색 로직
```dart
// 검색 쿼리 생성
씬 제목: "워밍업 - 스트레칭"
구도: ["와이드 샷으로 전체 풍경", "클로즈업"]
키워드: ["브이로그", "운동"]
→ YouTube 검색: "브이로그 운동 워밍업 스트레칭 와이드 샷"
→ 관련성 높은 상위 3개 결과 중 1위 선택
```

#### 13.3 Timestamp 추정
간단한 휴리스틱 기반:
- 오프닝/인트로: 10초 (인트로 스킵)
- 메인 씬: 30-60초 (본론 시작)
- 클로징: 0초 (처음부터)

#### 13.4 스토리보드 생성 워크플로우
1. AI가 스토리보드 생성
2. DALL-E가 구도 스케치 생성
3. **YouTube 레퍼런스 검색 (NEW!)**
4. 각 씬에 URL + Timestamp 저장

#### 13.5 비용
- YouTube Data API v3: 무료 할당량
- 일일 10,000 units (검색 1회 = 100 units)
- 하루 약 10개 스토리보드 무료 생성 가능

---

## 📝 남은 작업

### 1. Vision AI 기반 구도 매칭 (미래 구현)

**목표:** DALL-E 스케치와 실제로 유사한 YouTube 프레임 찾기

**구현 단계:**
1. DALL-E로 구도 스케치 생성 ✅ (완료)
2. YouTube Data API로 관련 영상 검색 ✅ (완료)
3. YouTube 영상의 프레임 추출 (ffmpeg 또는 YouTube API)
4. Cloud Vision API로 이미지 유사도 분석
5. 가장 비슷한 프레임의 timestamp 찾기

**필요한 것:**
- Cloud Vision API 키
- 프레임 추출 로직
- 유사도 비교 알고리즘

**예상 비용:** $0.15 per 스토리보드 (10씬)

**예상 시간:** 5-10분

### 2. Veo 2 AI 비디오 생성 (프리미엄 기능)

**목표:** 각 씬의 정확한 레퍼런스 비디오를 AI로 생성

**구현 방식:**
- Google AI Studio의 Veo 2 API 사용
- 백그라운드 생성 (비동기)
- 완료 시 푸시 알림
- 사용자 선택: "YouTube 검색 (즉시)" vs "AI 생성 (고품질, 50분)"

**예상 시간:** 50분~1.5시간 (10씬)
**예상 비용:** $1~5 per 스토리보드

**구현 단계:**
1. Veo 2 API 접근 권한 확보 (현재 제한적 베타)
2. 백그라운드 작업 큐 구현
3. Firebase Cloud Messaging 푸시 알림
4. 비디오 다운로드 및 저장 로직

### 3. 추가 UI 개선

**씬 상세 페이지 (`scene_detail_page.dart`):**
- 스토리보드 이미지 크게 표시
- 레퍼런스 비디오 플레이어 임베드
- 장소/비용/인원/시간 정보 카드

**카메라 모드 (`camera_mode_page.dart`):**
- 레퍼런스 재생 컨트롤 추가
- 이전 Take 비교 모드 (Split Screen)
- 실시간 구도 가이드 오버레이

### 4. 코드 중복 제거 및 통합

**검토 대상:**
- 이미지 서비스 통합 (`image_service.dart`, `google_image_service.dart`)
- 위치 서비스 정리 (`location_service.dart`, `google_places_service.dart`)
- 스타일 관련 파일 통합 (`app_styles.dart`, `styles.dart`)

---

## 🎯 구현 우선순위

### 완료된 작업
1. **✅ 완료:** 모델 구조 변경
2. **✅ 완료:** API 프롬프트 수정
3. **✅ 완료:** 체크리스트 의미 변경 (준비물 → 촬영 샷 확인)
4. **✅ 완료:** UI 대격변 (메인/입력/스토리보드/씬리스트)
5. **✅ 완료:** DALL-E 스토리보드 이미지 생성
6. **✅ 완료:** 카메라 페이지 씬 정보 전달
7. **✅ 완료:** YouTube 레퍼런스 검색 (timestamp 포함)
8. **✅ 완료:** 이전 Take 비디오 재생 기능
9. **✅ 완료:** 비디오 파일명 표준화 및 자동 저장

### 남은 작업 (우선순위)
10. **🔄 다음 (단기):** 코드 정리 및 리팩토링
11. **🔄 다음 (단기):** 추가 UI 개선
12. **⏭️ 미래 (장기):** Vision AI 구도 매칭
13. **⏭️ 미래 (장기):** Veo 2 AI 비디오 생성
14. **⏭️ 미래 (장기):** 협업 및 고급 기능

---

## 📌 주의사항

1. **하위 호환성:** 기존 필드들은 deprecated로 표시하되 유지
2. **API 비용:** 이미지 생성과 YouTube API 호출은 비용 발생 가능
3. **에러 처리:** 새로운 필드가 없을 경우 기본값 사용
4. **테스트:** 각 단계마다 전체 플로우 테스트 필요

---

## 📊 예상 작업 시간

- API 프롬프트 수정: 2-3시간
- YouTube 레퍼런스 기능: 3-4시간
- 스토리보드 이미지 생성: 2-3시간
- UI 수정: 4-5시간
- 코드 정리 및 테스트: 2-3시간

**총 예상 시간:** 13-18시간

---

## 🔗 관련 파일

### 모델
- `lib/models/plan.dart` - Plan, StyleAnalysis, Budget, LocationPoint
- `lib/models/cue_card.dart` - CueCard

### 서비스
- `lib/services/openai_service.dart` - API 호출 로직
- `lib/constants/prompts.dart` - 프롬프트 템플릿

### UI
- `lib/screens/storyboard/storyboard_page.dart` - 스토리보드 메인
- `lib/screens/scene/scene_detail_page.dart` - 씬 상세
- `lib/screens/camera/camera_mode_page.dart` - 촬영 모드

---

## 📈 진행 상황 요약

### 완료율: ~85%

#### ✅ 완료된 주요 기능 (13개)
1. 모델 구조 전면 개편 (Plan, CueCard + referenceVideoTimestamp)
2. API 프롬프트 및 응답 구조 변경
3. 체크리스트 의미 변경 (촬영 샷 확인 용도)
4. 전체 UI 리디자인 (새로운 컬러 시스템)
5. DALL-E 스토리보드 이미지 자동 생성
6. 씬별 촬영 정보 전달 (카메라 페이지)
7. **YouTube 레퍼런스 검색 (timestamp 특정 시점부터 재생)**
8. **이전 Take 비디오 재생 (동일 씬 촬영본 관리)**
9. **비디오 파일명 표준화 시스템**
10. **자동 Take 번호 관리**
11. **YouTube Player Flutter 통합**
12. **비디오 저장 서비스 구축**
13. Mock Data 임시 생성 기능

#### 🔄 남은 주요 작업
- **단기 (1-2주):**
  - 코드 정리 및 리팩토링
  - 추가 UI 개선
  - 에러 처리 강화

- **중기 (1-2개월):**
  - Vision AI 구도 매칭
  - 협업 기능
  - 템플릿 마켓플레이스

- **장기 (3-6개월):**
  - Veo 2 AI 비디오 생성
  - AI 어시스턴트
  - 앱 배포 및 마케팅

#### 📊 세부 진행률
- 핵심 기능: **100%** ✅
- UI/UX: **90%** 🔄
- 고급 기능: **20%** ⏳
- 코드 품질: **70%** 🔄

---

## 📚 관련 문서

- [TODO.md](./TODO.md) - 상세 작업 목록 및 우선순위
- [API_KEY_SETUP.md](./API_KEY_SETUP.md) - API 키 설정 가이드
- [README.md](./README.md) - 프로젝트 개요

---

_작성일: 2025-01-17_
_마지막 업데이트: 2025-11-17 (YouTube 레퍼런스 검색 완성, TODO.md 추가, 문서 체계화)_
