import '../models/cue_template.dart';
import '../models/plan.dart';
import '../models/cue_card.dart';
import '../models/chapter.dart';

// Plan 내부 클래스들도 사용 가능하도록
export '../models/plan.dart';

/// 저장된 스토리보드 정보
class SavedStoryboard {
  final String id;
  final String title;
  final DateTime createdAt;
  final Map<String, String> userInput;
  final Plan plan;
  final List<CueCard> cueCards;
  final String? mainThumbnail;

  SavedStoryboard({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.userInput,
    required this.plan,
    required this.cueCards,
    this.mainThumbnail,
  });
}

/// 브이로그 데이터를 관리하는 싱글톤 서비스
class VlogDataService {
  static final VlogDataService _instance = VlogDataService._internal();
  factory VlogDataService() => _instance;
  VlogDataService._internal();

  // 사용자 입력 정보
  Map<String, String> userInput = {};

  // 생성된 데이터
  List<CueTemplate>? templates;
  Plan? plan;
  List<CueCard>? cueCards;

  // 저장된 스토리보드 목록
  final List<SavedStoryboard> _savedStoryboards = [];
  String? _currentStoryboardId;
  bool _sampleDataInitialized = false;

  // 데이터 초기화
  void reset() {
    userInput.clear();
    templates = null;
    plan = null;
    cueCards = null;
    // 스토리보드 목록은 유지
  }

  // 샘플 스토리보드 초기화 (앱 시작 시 한 번만)
  void initializeSampleData() {
    if (_sampleDataInitialized) return;
    _sampleDataInitialized = true;

    // 제주도 여행 샘플 데이터
    final sampleUserInput = {
      'location': '제주도',
      'subject': '친구들과 제주도 여행',
      'target_audience': '20대 여행 좋아하는 사람들',
      'tone_manners': '밝고 경쾌한 분위기',
      'target_duration': '10',
      'equipment': 'smartphone',
      'time_weather': '낮, 맑음',
      'difficulty': 'novice',
      'people': '3명',
    };

    final samplePlan = Plan(
      summary: '친구들과 함께하는 제주도 1박 2일 여행. 성산일출봉에서 시작해 섭지코지, 카페 투어, 해변 산책, 맛집 탐방까지 알찬 일정으로 제주의 매력을 가득 담은 여행 브이로그.',
      vlogTitle: '제주도 1박2일 🌴 친구들과 떠나는 힐링 여행',
      keywords: ['제주도', '친구여행', '힐링', '카페투어', '맛집'],
      goalDurationMin: 10,
      bufferRate: 1.15,
      chapters: [
        Chapter(id: '오프닝 & 성산일출봉', allocSec: 120, alternatives: []),
        Chapter(id: '섭지코지 & 카페', allocSec: 180, alternatives: []),
        Chapter(id: '해변 산책 & 저녁', allocSec: 180, alternatives: []),
        Chapter(id: '맛집 투어 & 마무리', allocSec: 120, alternatives: []),
      ],
      styleAnalysis: StyleAnalysis(
        tone: '밝고 경쾌한',
        vibe: 'MZ 힐링',
        pacing: '적당한 템포',
        visualStyle: ['자연 풍경', '밝은 색감', '카페 감성'],
        audioStyle: ['경쾌한 배경음악', '자연 소리'],
        emotionalExpression: 4,
        movement: 4,
        intensity: 3,
        locationDiversity: 5,
        speedRhythm: 4,
        excitementSurprise: 4,
      ),
      shootingRoute: ShootingRoute(
        locations: [
          LocationPoint(name: '성산일출봉', latitude: 33.4603, longitude: 126.9423, order: 1, description: '일출로 유명한 화산분화구'),
          LocationPoint(name: '섭지코지', latitude: 33.4244, longitude: 126.9279, order: 2, description: '넓은 잔디밭과 등대'),
          LocationPoint(name: '월정리 해변', latitude: 33.5564, longitude: 126.7960, order: 3, description: '에메랄드빛 바다'),
          LocationPoint(name: '제주 맛집', latitude: 33.5006, longitude: 126.5219, order: 4, description: '흑돼지 맛집'),
        ],
        routeDescription: '성산일출봉에서 시작해 동쪽 해안을 따라 이동하며 제주의 자연을 만끽',
        estimatedWalkingMinutes: 120,
      ),
      budget: Budget(
        totalBudget: 150000,
        items: [
          BudgetItem(category: '입장료', amount: 20000, description: '성산일출봉, 섭지코지'),
          BudgetItem(category: '식사', amount: 60000, description: '점심, 저녁 맛집'),
          BudgetItem(category: '카페', amount: 30000, description: '카페 2-3곳'),
          BudgetItem(category: '교통비', amount: 40000, description: '렌터카 주유비 등'),
        ],
        currency: 'KRW',
      ),
      shootingChecklist: [
        '카메라/스마트폰 충전',
        '여분 배터리 준비',
        '선크림, 모자',
        '편한 신발',
        '물, 간식',
      ],
      locationImage: 'https://images.unsplash.com/photo-1599481238640-4c1288750d7a?w=800',
      equipmentRecommendation: '제주 여행은 풍경이 아름답기 때문에 스마트폰으로도 충분히 좋은 영상을 담을 수 있습니다. 손떨림 방지를 위해 간단한 짐벌이 있으면 더욱 좋습니다.',
    );

    final sampleCueCards = <CueCard>[
      CueCard(
        title: '성산일출봉 입구',
        allocatedSec: 60,
        trigger: 'timed',
        summary: ['제주도 도착', '성산일출봉으로 이동', '오프닝 멘트'],
        steps: ['주차장에서 입구까지 걸으며 촬영', '입구에서 오프닝 멘트', '날씨와 기분 이야기'],
        checklist: ['카메라 준비', '마이크 테스트'],
        fallback: '날씨가 흐리면 실내 카페에서 오프닝',
        startHint: '주차하고 내리면서',
        stopHint: '입장권을 사고 난 후',
        completionCriteria: '오프닝 멘트와 입구 풍경',
        tone: '밝고 신나는',
        styleVibe: 'MZ 여행',
        targetAudience: '20대',
        script: '안녕하세요~ 드디어 제주도에 도착했어요! 오늘은 친구들과 제주도 1박2일 여행 시작합니다.',
        thumbnailUrl: 'https://images.unsplash.com/photo-1599481238640-4c1288750d7a?w=400',
        rawMarkdown: ''',
        rawMarkdown: '',
      ),
      CueCard(
        title: '성산일출봉 등반',
        allocatedSec: 90,
        trigger: 'timed',
        summary: ['계단 오르며 중간 중간 풍경 촬영', '정상까지 가는 과정'],
        steps: ['계단 오르면서 반응 촬영', '중간 쉬는 곳에서 풍경 담기', '친구들과 대화'],
        checklist: ['안정적인 촬영'],
        fallback: '체력이 부족하면 중간까지만',
        startHint: '계단 오르기 시작',
        stopHint: '정상 도착',
        completionCriteria: '오르는 과정과 풍경',
        tone: '힘들지만 재미있는',
        styleVibe: '친구들과의 케미',
        targetAudience: '20대',
        script: '아~ 계단 엄청 많네요! 그래도 풍경이 너무 예뻐요. 친구들아 힘내자!',
        thumbnailUrl: 'https://images.unsplash.com/photo-1598181799590-e4c1288750d7a?w=400',
        rawMarkdown: '',
      ),
      CueCard(
        title: '성산일출봉 정상',
        allocatedSec: 90,
        trigger: 'timed',
        summary: ['정상에서 바라본 풍경', '분화구와 바다 전경'],
        steps: ['360도 풍경 촬영', '정상 도착 반응', '기념 사진'],
        checklist: ['광각으로 풍경 담기'],
        fallback: '사람이 많으면 잠깐 대기',
        startHint: '정상 도착',
        stopHint: '하산 시작',
        completionCriteria: '정상 풍경과 반응',
        tone: '감탄하는',
        styleVibe: '힐링',
        targetAudience: '20대',
        script: '와... 진짜 너무 예쁘다. 이래서 성산일출봉이 유명한 거구나! 바다 색깔 좀 보세요.',
        thumbnailUrl: 'https://images.unsplash.com/photo-1565795266-7ab8ff6f39db?w=400',
        rawMarkdown: '',
      ),
      CueCard(
        title: '섭지코지 도착',
        allocatedSec: 60,
        trigger: 'timed',
        summary: ['섭지코지로 이동', '넓은 잔디밭과 바다'],
        steps: ['차에서 내려 첫 인상', '잔디밭 걸으며 촬영'],
        checklist: ['자연광 활용'],
        fallback: '바람이 세면 실내로',
        startHint: '주차장 도착',
        stopHint: '등대 방향으로 이동',
        completionCriteria: '섭지코지 첫 인상',
        tone: '여유로운',
        styleVibe: '자연 힐링',
        targetAudience: '20대',
        script: '다음 장소는 섭지코지! 여기 진짜 넓고 시원해요. 사진 찍기 좋은 곳이 많을 것 같아요.',
        thumbnailUrl: 'https://images.unsplash.com/photo-1598198166242-984f6f8ddfe1?w=400',
        rawMarkdown: '',
      ),
      CueCard(
        title: '섭지코지 등대',
        allocatedSec: 90,
        trigger: 'timed',
        summary: ['등대까지 걸어가며 풍경 촬영', '포토 스팟'],
        steps: ['등대 가는 길 촬영', '등대 근처에서 사진', '친구들과 단체 사진'],
        checklist: ['역광 주의'],
        fallback: '사람 많으면 각도 조정',
        startHint: '등대 방향 이동',
        stopHint: '카페로 이동',
        completionCriteria: '등대 풍경',
        tone: '감성적인',
        styleVibe: '인생샷',
        targetAudience: '20대',
        script: '드디어 등대 도착! 여기서 사진 찍으면 진짜 예쁘게 나올 것 같아요.',
        thumbnailUrl: 'https://images.unsplash.com/photo-1590649880765-91b1956b8276?w=400',
        rawMarkdown: ''',
      ),
      CueCard(
        title: '제주 감성 카페',
        allocatedSec: 120,
        trigger: 'timed',
        summary: ['카페 도착', '인테리어와 음료', '친구들과 수다'],
        steps: ['카페 외관 촬영', '메뉴 주문', '음료와 디저트', '창밖 풍경'],
        checklist: ['실내 조명 확인'],
        fallback: '사람 많으면 테이크아웃',
        startHint: '카페 입장',
        stopHint: '카페 나가기',
        completionCriteria: '카페 분위기',
        tone: '편안한',
        styleVibe: '카페 감성',
        targetAudience: '20대',
        script: '제주 감성 카페에 왔어요! 인테리어도 예쁘고 창밖으로 바다도 보여요. 아메리카노 시켰는데 진짜 맛있어요.',
        thumbnailUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400',
        rawMarkdown: ''',
      ),
      CueCard(
        title: '월정리 해변',
        allocatedSec: 90,
        trigger: 'timed',
        summary: ['해변 도착', '하얀 모래와 에메랄드 바다'],
        steps: ['해변 입구 촬영', '모래사장 걸으며', '파도 소리'],
        checklist: ['신발 벗고 촬영'],
        fallback: '날씨 안 좋으면 짧게',
        startHint: '해변 도착',
        stopHint: '근처 식당 이동',
        completionCriteria: '해변 풍경',
        tone: '시원한',
        styleVibe: '자연 힐링',
        targetAudience: '20대',
        script: '월정리 해변이에요! 물이 진짜 맑고 예뻐요. 신발 벗고 모래 밟으니까 너무 좋다.',
        thumbnailUrl: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=400',
        rawMarkdown: ''',
      ),
      CueCard(
        title: '제주 흑돼지 맛집',
        allocatedSec: 120,
        trigger: 'timed',
        summary: ['저녁 식사', '제주 흑돼지 구이'],
        steps: ['식당 입장', '고기 굽는 모습', '먹방', '친구들 반응'],
        checklist: ['음식 촬영 각도'],
        fallback: '연기 많으면 환기 후',
        startHint: '식당 도착',
        stopHint: '식사 마무리',
        completionCriteria: '먹방과 반응',
        tone: '맛있는',
        styleVibe: '먹방',
        targetAudience: '20대',
        script: '제주 왔으면 흑돼지 먹어야죠! 고기 두께 좀 보세요. 이거 진짜 육즙 장난 아니에요.',
        thumbnailUrl: 'https://images.unsplash.com/photo-1600891964092-4316c288032e?w=400',
        rawMarkdown: ''',
      ),
      CueCard(
        title: '제주 야경',
        allocatedSec: 60,
        trigger: 'timed',
        summary: ['저녁 산책', '제주 야경'],
        steps: ['식사 후 근처 산책', '야경 촬영', '하루 마무리'],
        checklist: ['삼각대 또는 고정'],
        fallback: '어두우면 짧게',
        startHint: '식당 나와서',
        stopHint: '숙소 이동',
        completionCriteria: '야경',
        tone: '차분한',
        styleVibe: '감성',
        targetAudience: '20대',
        script: '배불리 먹고 나와서 산책 중이에요. 제주 밤 공기 너무 좋아요.',
        thumbnailUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400',
        rawMarkdown: ''',
      ),
      CueCard(
        title: '마무리 & 엔딩',
        allocatedSec: 60,
        trigger: 'timed',
        summary: ['여행 마무리', '다음 날 아침 또는 돌아가는 길'],
        steps: ['여행 소감', '하이라이트 회상', '시청자 인사'],
        checklist: ['마무리 멘트'],
        fallback: '없음',
        startHint: '마지막 장면',
        stopHint: '영상 종료',
        completionCriteria: '엔딩 멘트',
        tone: '아쉬운',
        styleVibe: '감동',
        targetAudience: '20대',
        script: '제주도 1박2일 여행 너무 재밌었어요! 다음에 또 올게요. 오늘 영상 재밌게 보셨다면 좋아요와 구독 부탁드려요!',
        thumbnailUrl: 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?w=400',
        rawMarkdown: '',
      ),
    ];

    final sampleStoryboard = SavedStoryboard(
      id: 'sample_jeju_trip',
      title: '제주도 1박2일 🌴 친구들과 떠나는 힐링 여행',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      userInput: sampleUserInput,
      plan: samplePlan,
      cueCards: sampleCueCards,
      mainThumbnail: 'https://images.unsplash.com/photo-1599481238640-4c1288750d7a?w=800',
    );

    _savedStoryboards.add(sampleStoryboard);
  }

  // 현재 스토리보드를 저장된 목록에 추가
  String saveCurrentStoryboard({String? mainThumbnail}) {
    if (plan == null || cueCards == null) {
      throw Exception('저장할 스토리보드가 없습니다');
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final storyboard = SavedStoryboard(
      id: id,
      title: plan!.vlogTitle,
      createdAt: DateTime.now(),
      userInput: Map.from(userInput),
      plan: plan!,
      cueCards: List.from(cueCards!),
      mainThumbnail: mainThumbnail,
    );

    _savedStoryboards.insert(0, storyboard);
    _currentStoryboardId = id;
    
    return id;
  }

  // 저장된 스토리보드 목록 가져오기
  List<SavedStoryboard> getSavedStoryboards() {
    return List.unmodifiable(_savedStoryboards);
  }

  // 특정 스토리보드 로드
  void loadStoryboard(String id) {
    final storyboard = _savedStoryboards.firstWhere(
      (s) => s.id == id,
      orElse: () => throw Exception('스토리보드를 찾을 수 없습니다'),
    );

    userInput = Map.from(storyboard.userInput);
    plan = storyboard.plan;
    cueCards = List.from(storyboard.cueCards);
    _currentStoryboardId = id;
  }

  // 현재 스토리보드 ID
  String? get currentStoryboardId => _currentStoryboardId;

  // 현재 스토리보드 업데이트 (편집 후)
  void updateCurrentStoryboard() {
    if (_currentStoryboardId == null || plan == null || cueCards == null) {
      return;
    }

    final index = _savedStoryboards.indexWhere((s) => s.id == _currentStoryboardId);
    if (index != -1) {
      final oldStoryboard = _savedStoryboards[index];
      _savedStoryboards[index] = SavedStoryboard(
        id: oldStoryboard.id,
        title: plan!.vlogTitle,
        createdAt: oldStoryboard.createdAt,
        userInput: Map.from(userInput),
        plan: plan!,
        cueCards: List.from(cueCards!),
        mainThumbnail: oldStoryboard.mainThumbnail,
      );
    }
  }

  // 사용자 입력 설정
  void setUserInput(Map<String, String> input) {
    userInput = input;
  }

  // 템플릿 설정
  void setTemplates(List<CueTemplate> newTemplates) {
    templates = newTemplates;
  }

  // 계획 설정
  void setPlan(Plan newPlan) {
    plan = newPlan;
  }

  // 큐카드 설정
  void setCueCards(List<CueCard> newCueCards) {
    cueCards = newCueCards;
  }

  // 개별 큐카드 업데이트
  void updateCueCard(int index, CueCard updatedCard) {
    if (cueCards != null && index >= 0 && index < cueCards!.length) {
      cueCards![index] = updatedCard;
    }
  }

  // 모든 데이터가 준비되었는지 확인
  bool get isReady {
    return templates != null && 
           plan != null && 
           cueCards != null && 
           cueCards!.isNotEmpty;
  }

  // 브이로그 제목
  String getVlogTitle() {
    if (plan == null) return '브이로그 제목';
    return plan!.vlogTitle.isNotEmpty ? plan!.vlogTitle : '브이로그 제목';
  }

  // 브이로그 키워드
  List<String> getKeywords() {
    if (plan == null) return [];
    return plan!.keywords;
  }

  // 키워드 문자열 (| 로 구분)
  String getKeywordsString() {
    final keywords = getKeywords();
    if (keywords.isEmpty) {
      return '${userInput['visit_context'] ?? '친구들과'} | ${userInput['time_weather'] ?? '낮, 맑음'}';
    }
    return keywords.join(' | ');
  }

  // 시나리오 요약 정보 가져오기
  String getScenarioSummary() {
    if (!isReady) return '시나리오 정보를 생성 중입니다...';

    final duration = plan!.goalDurationMin;
    final sceneCount = cueCards!.length;
    final mainStyle = templates != null && templates!.isNotEmpty ? templates![0].styleVibe : '일상';

    return '친구들과 함께하는 ${mainStyle} 브이로그 ($duration분, $sceneCount개 씬)';
  }

  // 촬영 장비 정보
  String getEquipment() {
    return userInput['equipment'] ?? '스마트폰';
  }

  // 장비 추천
  String? getEquipmentRecommendation() {
    return plan?.equipmentRecommendation;
  }

  // 촬영 길이
  String getDuration() {
    if (plan == null) return '미정';
    return '${plan!.goalDurationMin}분';
  }

  // 씬 개수
  String getSceneCount() {
    if (cueCards == null) return '0개';
    return '${cueCards!.length}개';
  }

  // 촬영 예산 (사용자 입력에서 가져오기)
  String getBudget() {
    if (plan?.budget != null) {
      return getTotalBudget();
    }
    return userInput['budget'] ?? '미정';
  }

  // 등장 인물
  String getPeople() {
    return userInput['people'] ?? '3명';
  }

  // 영상 톤
  String getTone() {
    if (plan?.styleAnalysis != null) {
      return plan!.styleAnalysis!.tone;
    }
    if (templates == null || templates!.isEmpty) return '일상';
    return templates![0].styleTone;
  }

  // 촬영 준비 체크리스트
  List<String> getChecklist() {
    if (plan != null && plan!.shootingChecklist.isNotEmpty) {
      return plan!.shootingChecklist;
    }
    if (templates == null || templates!.isEmpty) return [];
    
    final checklistSet = <String>{};
    for (var template in templates!) {
      checklistSet.addAll(template.checklist);
    }
    
    return checklistSet.toList();
  }
  
  // 시나리오 요약
  String getSummary() {
    if (plan != null && plan!.summary.isNotEmpty) {
      return plan!.summary;
    }
    return '시나리오 정보를 생성 중입니다...';
  }
  
  // 스타일 분석 정보
  String getStyleTone() {
    if (plan?.styleAnalysis == null) return '밝고 경쾌';
    return plan!.styleAnalysis!.tone;
  }
  
  String getStyleVibe() {
    if (plan?.styleAnalysis == null) return 'MZ 감성';
    return plan!.styleAnalysis!.vibe;
  }
  
  String getStylePacing() {
    if (plan?.styleAnalysis == null) return '빠른 템포';
    return plan!.styleAnalysis!.pacing;
  }
  
  List<String> getVisualStyle() {
    if (plan?.styleAnalysis == null) return [];
    return plan!.styleAnalysis!.visualStyle;
  }
  
  List<String> getAudioStyle() {
    if (plan?.styleAnalysis == null) return [];
    return plan!.styleAnalysis!.audioStyle;
  }
  
  // 촬영 동선 정보
  List<LocationPoint> getShootingLocations() {
    if (plan?.shootingRoute == null) return [];
    return plan!.shootingRoute!.locations;
  }
  
  String getRouteDescription() {
    if (plan?.shootingRoute == null) return '';
    return plan!.shootingRoute!.routeDescription;
  }
  
  int getEstimatedWalkingMinutes() {
    if (plan?.shootingRoute == null) return 0;
    return plan!.shootingRoute!.estimatedWalkingMinutes;
  }
  
  // 예산 정보
  String getTotalBudget() {
    if (plan?.budget == null) return '미정';
    final budget = plan!.budget!;
    return '${budget.totalBudget.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
  }
  
  List<BudgetItem> getBudgetItems() {
    if (plan?.budget == null) return [];
    return plan!.budget!.items;
  }

  // 날씨 정보
  Map<String, dynamic>? getWeatherInfo() {
    return plan?.weatherInfo;
  }

  String getWeatherDescription() {
    final weather = getWeatherInfo();
    if (weather == null) return '정보 없음';
    return weather['description'] as String? ?? '정보 없음';
  }

  int? getWeatherTemperature() {
    final weather = getWeatherInfo();
    if (weather == null) return null;
    return weather['temperature'] as int?;
  }

  String getWeatherRecommendation() {
    final weather = getWeatherInfo();
    if (weather == null) return '';
    return weather['recommendation'] as String? ?? '';
  }

  // 레이더 차트 점수들
  int getEmotionalExpression() {
    if (plan?.styleAnalysis == null) return 3;
    return plan!.styleAnalysis!.emotionalExpression;
  }

  int getMovement() {
    if (plan?.styleAnalysis == null) return 3;
    return plan!.styleAnalysis!.movement;
  }

  int getIntensity() {
    if (plan?.styleAnalysis == null) return 3;
    return plan!.styleAnalysis!.intensity;
  }

  int getLocationDiversity() {
    if (plan?.styleAnalysis == null) return 3;
    return plan!.styleAnalysis!.locationDiversity;
  }

  int getSpeedRhythm() {
    if (plan?.styleAnalysis == null) return 3;
    return plan!.styleAnalysis!.speedRhythm;
  }

  int getExcitementSurprise() {
    if (plan?.styleAnalysis == null) return 3;
    return plan!.styleAnalysis!.excitementSurprise;
  }
  
  // 스타일 분석 이유들
  String? getEmotionalExpressionRationale() {
    if (plan?.styleAnalysis?.rationale == null) return null;
    return plan!.styleAnalysis!.rationale!.emotionalExpression;
  }
  
  String? getMovementRationale() {
    if (plan?.styleAnalysis?.rationale == null) return null;
    return plan!.styleAnalysis!.rationale!.movement;
  }
  
  String? getIntensityRationale() {
    if (plan?.styleAnalysis?.rationale == null) return null;
    return plan!.styleAnalysis!.rationale!.intensity;
  }
  
  String? getLocationDiversityRationale() {
    if (plan?.styleAnalysis?.rationale == null) return null;
    return plan!.styleAnalysis!.rationale!.locationDiversity;
  }
  
  String? getSpeedRhythmRationale() {
    if (plan?.styleAnalysis?.rationale == null) return null;
    return plan!.styleAnalysis!.rationale!.speedRhythm;
  }
  
  String? getExcitementSurpriseRationale() {
    if (plan?.styleAnalysis?.rationale == null) return null;
    return plan!.styleAnalysis!.rationale!.excitementSurprise;
  }
}

