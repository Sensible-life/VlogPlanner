import '../models/cue_template.dart';
import '../models/plan.dart';
import '../models/cue_card.dart';
import '../models/chapter.dart';
import 'firestore_service.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'user_input': userInput,
      'plan': plan.toJson(),
      'cue_cards': cueCards.map((c) => c.toJson()).toList(),
      if (mainThumbnail != null) 'main_thumbnail': mainThumbnail,
    };
  }

  factory SavedStoryboard.fromJson(Map<String, dynamic> json) {
    final planJson = json['plan'] as Map<String, dynamic>? ?? {};
    print('[VLOG_DATA] SavedStoryboard.fromJson - plan JSON 확인');
    print('[VLOG_DATA]   - alternative_scenes 존재: ${planJson.containsKey('alternative_scenes')}');
    if (planJson.containsKey('alternative_scenes')) {
      final altScenes = planJson['alternative_scenes'];
      print('[VLOG_DATA]   - alternative_scenes 타입: ${altScenes.runtimeType}');
      if (altScenes is List) {
        print('[VLOG_DATA]   - alternative_scenes 개수: ${altScenes.length}');
      }
    }
    
    final plan = Plan.fromJson(planJson);
    print('[VLOG_DATA] SavedStoryboard.fromJson - Plan 파싱 완료');
    print('[VLOG_DATA]   - Plan.alternativeScenes 개수: ${plan.alternativeScenes.length}');
    
    return SavedStoryboard(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      userInput: Map<String, String>.from(json['user_input'] as Map? ?? {}),
      plan: plan,
      cueCards: (json['cue_cards'] as List<dynamic>?)
              ?.map((e) => CueCard.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      mainThumbnail: json['main_thumbnail'] as String?,
    );
  }
}

/// 브이로그 데이터를 관리하는 싱글톤 서비스
class VlogDataService {
  static final VlogDataService _instance = VlogDataService._internal();
  factory VlogDataService() => _instance;
  VlogDataService._internal();

  // Firebase 서비스
  final FirestoreService _firestoreService = FirestoreService();

  // 사용자 입력 정보
  Map<String, String> userInput = {};

  // 생성된 데이터
  List<CueTemplate>? templates;
  Plan? plan;
  List<CueCard>? cueCards;

  // 저장된 스토리보드 목록 (캐시)
  final List<SavedStoryboard> _savedStoryboards = [];
  String? _currentStoryboardId;
  bool _sampleDataInitialized = false;
  bool _firestoreLoaded = false;

  // 구도 이미지 저장: sceneId -> checklistIndex -> imageUrl
  final Map<String, Map<int, String>> _compositionImages = {};

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
        tone: '차분함',
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
        totalBudget: 40000,
        items: [
          BudgetItem(category: '입장료', amount: 5000, description: '성산일출봉, 섭지코지'),
          BudgetItem(category: '식사', amount: 15000, description: '점심, 저녁 맛집'),
          BudgetItem(category: '카페', amount: 10000, description: '카페 2-3곳'),
          BudgetItem(category: '교통비', amount: 10000, description: '렌터카 주유비 등'),
        ],
        currency: 'USD',
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

  // 현재 스토리보드를 Firestore에 저장
  Future<String> saveCurrentStoryboard({String? mainThumbnail}) async {
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

    // Firestore에 저장
    try {
      final firestoreId = await _firestoreService.saveStoryboard(storyboard);

      // 로컬 캐시에도 추가 (Firestore ID 사용)
      final savedStoryboard = SavedStoryboard(
        id: firestoreId,
        title: storyboard.title,
        createdAt: storyboard.createdAt,
        userInput: storyboard.userInput,
        plan: storyboard.plan,
        cueCards: storyboard.cueCards,
        mainThumbnail: storyboard.mainThumbnail,
      );

      _savedStoryboards.insert(0, savedStoryboard);
      _currentStoryboardId = firestoreId;

      return firestoreId;
    } catch (e) {
      // Firestore 저장 실패 시 로컬에만 저장
      print('Firestore 저장 실패, 로컬에만 저장: $e');
      _savedStoryboards.insert(0, storyboard);
      _currentStoryboardId = id;
      return id;
    }
  }

  // Firestore에서 스토리보드 목록 로드
  Future<void> loadStoryboardsFromFirestore() async {
    if (_firestoreLoaded) return;

    try {
      final storyboards = await _firestoreService.getAllStoryboards();
      _savedStoryboards.clear();
      _savedStoryboards.addAll(storyboards);
      _firestoreLoaded = true;
    } catch (e) {
      print('Firestore에서 스토리보드 로드 실패: $e');
    }
  }

  // 저장된 스토리보드 목록 가져오기 (캐시된 데이터)
  List<SavedStoryboard> getSavedStoryboards() {
    return List.unmodifiable(_savedStoryboards);
  }

  // Firestore 스토리보드 스트림 가져오기
  Stream<List<SavedStoryboard>> getStoryboardsStream() {
    return _firestoreService.getStoryboardsStream();
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
  Future<void> updateCurrentStoryboard() async {
    if (_currentStoryboardId == null || plan == null || cueCards == null) {
      return;
    }

    final index = _savedStoryboards.indexWhere((s) => s.id == _currentStoryboardId);
    if (index != -1) {
      final oldStoryboard = _savedStoryboards[index];
      final updatedStoryboard = SavedStoryboard(
        id: oldStoryboard.id,
        title: plan!.vlogTitle,
        createdAt: oldStoryboard.createdAt,
        userInput: Map.from(userInput),
        plan: plan!,
        cueCards: List.from(cueCards!),
        mainThumbnail: oldStoryboard.mainThumbnail,
      );

      // Firestore에 업데이트
      try {
        await _firestoreService.updateStoryboard(updatedStoryboard);
        _savedStoryboards[index] = updatedStoryboard;
      } catch (e) {
        print('Firestore 업데이트 실패, 로컬만 업데이트: $e');
        _savedStoryboards[index] = updatedStoryboard;
      }
    }
  }

  // 스토리보드 삭제
  Future<void> deleteStoryboard(String id) async {
    try {
      await _firestoreService.deleteStoryboard(id);
      _savedStoryboards.removeWhere((s) => s.id == id);

      if (_currentStoryboardId == id) {
        _currentStoryboardId = null;
        reset();
      }
    } catch (e) {
      print('Firestore 삭제 실패: $e');
      throw Exception('스토리보드 삭제 실패');
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

  // 등장 인물 (숫자+명 형태로 반환)
  String getPeople() {
    final people = userInput['people'];
    if (people == null) return '3명';
    
    // 이미 "명"이 붙어있으면 그대로 반환
    if (people.toString().contains('명')) {
      return people.toString();
    }
    
    // 숫자만 있으면 "명" 추가
    final numMatch = RegExp(r'\d+').firstMatch(people.toString());
    if (numMatch != null) {
      return '${numMatch.group(0)}명';
    }
    
    return '3명';
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
    // plan의 shootingRoute.locations를 기본으로 사용 (실제 GPS 좌표가 있는 것만)
    final routeLocations = plan?.shootingRoute?.locations ?? [];
    
    if (cueCards == null || cueCards!.isEmpty) {
      return routeLocations;
    }
    
    // routeLocations에 있는 location만 사용 (실제 GPS 좌표가 있는 것만)
    // 같은 이름의 location이 여러 씬에서 사용되면 하나로 합침
    final locationMap = <String, LocationPoint>{}; // location 이름 -> LocationPoint
    
    // routeLocations를 맵에 추가 (이름 기준)
    for (final loc in routeLocations) {
      // 같은 이름의 location이 있으면 sceneIds를 합침
      if (locationMap.containsKey(loc.name)) {
        final existing = locationMap[loc.name]!;
        final combinedSceneIds = <String>{
          ...existing.sceneIds,
          ...loc.sceneIds,
        }.toList();
        locationMap[loc.name] = LocationPoint(
          name: existing.name,
          description: existing.description,
          latitude: existing.latitude,
          longitude: existing.longitude,
          order: existing.order,
          sceneIds: combinedSceneIds,
        );
      } else {
        locationMap[loc.name] = loc;
      }
    }
    
    // 각 씬의 location을 routeLocations에서 찾아서 sceneIds에 추가
    for (int i = 0; i < cueCards!.length; i++) {
      final card = cueCards![i];
      final sceneLocation = card.location;
      
      if (sceneLocation.isEmpty) {
        print('[VLOG_DATA] 씬 ${i + 1} (${card.title}): location이 비어있음');
        continue;
      }
      
      // routeLocations에서 location 이름으로 찾기
      if (locationMap.containsKey(sceneLocation)) {
        final location = locationMap[sceneLocation]!;
        final sceneId = 'scene_${i + 1}';
        
        // sceneIds에 없으면 추가
        if (!location.sceneIds.contains(sceneId)) {
          locationMap[sceneLocation] = LocationPoint(
            name: location.name,
            description: location.description,
            latitude: location.latitude,
            longitude: location.longitude,
            order: location.order,
            sceneIds: [...location.sceneIds, sceneId],
          );
        }
        print('[VLOG_DATA] 씬 ${i + 1} (${card.title}): ${sceneLocation} 매칭됨');
      } else {
        // routeLocations에 없는 location은 제외 (GPS 좌표가 없으므로)
        print('[VLOG_DATA] 씬 ${i + 1} (${card.title}): ${sceneLocation} - routeLocations에 없어서 제외됨');
      }
    }
    
    // 순서대로 정렬하여 반환
    final allLocations = locationMap.values.toList();
    allLocations.sort((a, b) => a.order.compareTo(b.order));
    
    print('[VLOG_DATA] getShootingLocations: ${allLocations.length}개 위치 반환 (씬 개수: ${cueCards!.length}, routeLocations: ${routeLocations.length}개)');
    
    return allLocations;
  }
  
  String getRouteDescription() {
    if (plan?.shootingRoute == null) return '';
    return plan!.shootingRoute!.routeDescription;
  }
  
  int getEstimatedWalkingMinutes() {
    if (plan?.shootingRoute == null) return 0;
    return plan!.shootingRoute!.estimatedWalkingMinutes;
  }
  
  // 예산 정보 (원화 형식으로 반환)
  // 예산 탭과 동일한 로직으로 계산: plan의 budget.items와 모든 씬의 cost를 통합한 합계
  String getTotalBudget() {
    // 예산 탭과 동일한 로직으로 합계 계산
    final budgetItems = plan?.budget?.items ?? [];
    
    // 모든 씬의 cost를 카테고리별로 그룹화
    final sceneCostsByCategory = <String, int>{};
    
    if (cueCards != null) {
      for (final card in cueCards!) {
        if (card.cost > 0) {
          // 씬의 location이나 title을 기반으로 카테고리 추정
          String category = '기타';
          if (card.location.contains('식당') || card.location.contains('맛집') || card.location.contains('푸드')) {
            category = '식사';
          } else if (card.location.contains('카페') || card.location.contains('커피')) {
            category = '카페';
          } else if (card.location.contains('입장') || card.location.contains('게이트') || card.location.contains('공원')) {
            category = '입장료';
          } else if (card.location.contains('교통') || card.location.contains('주차')) {
            category = '교통비';
          }
          
          sceneCostsByCategory[category] = (sceneCostsByCategory[category] ?? 0) + card.cost;
        }
      }
    }
    
    // 기존 budget items와 씬 cost를 통합
    final allBudgetItems = <Map<String, dynamic>>[];
    
    // 기존 budget items 추가
    for (final item in budgetItems) {
      allBudgetItems.add({
        'category': item.category,
        'description': item.description,
        'amount': item.amount,
      });
    }
    
    // 씬 cost를 카테고리별로 추가 (기존 항목과 같은 카테고리가 있으면 합산)
    sceneCostsByCategory.forEach((category, amount) {
      final existingIndex = allBudgetItems.indexWhere((item) => item['category'] == category);
      if (existingIndex >= 0) {
        // 기존 항목에 합산
        allBudgetItems[existingIndex]['amount'] = (allBudgetItems[existingIndex]['amount'] as int) + amount;
      } else {
        // 새 항목 추가
        allBudgetItems.add({
          'category': category,
          'description': '씬별 촬영 비용',
          'amount': amount,
        });
      }
    });
    
    // 표시된 모든 예산 항목의 합계 계산 (예산 탭과 동일)
    final totalAmount = allBudgetItems.fold<int>(
      0,
      (sum, item) => sum + (item['amount'] as int),
    );
    
    // 원화 포맷으로 변환
    if (totalAmount == 0) {
      return '0원';
    }
    
    final formatted = totalAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    
    return '$formatted원';
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

  // 구도 이미지 관련 메서드
  void setCompositionImage(String sceneId, int checklistIndex, String imageUrl) {
    // 메모리 캐시에 저장
    if (!_compositionImages.containsKey(sceneId)) {
      _compositionImages[sceneId] = {};
    }
    _compositionImages[sceneId]![checklistIndex] = imageUrl;

    // CueCard에도 저장 (씬 인덱스 추출)
    if (cueCards != null) {
      // sceneId에서 씬 인덱스 추출 (예: "scene_1" -> 0)
      final sceneIndex = int.tryParse(sceneId.replaceAll('scene_', '')) ?? 1;
      final cardIndex = sceneIndex - 1; // 0-based 인덱스

      if (cardIndex >= 0 && cardIndex < cueCards!.length) {
        final card = cueCards![cardIndex];

        // 기존 compositionImages에 새 이미지 추가
        final updatedCompositionImages = Map<int, String>.from(card.compositionImages ?? {});
        updatedCompositionImages[checklistIndex] = imageUrl;

        // 새로운 CueCard 생성 (불변성 유지)
        final updatedCard = CueCard(
          title: card.title,
          allocatedSec: card.allocatedSec,
          trigger: card.trigger,
          summary: card.summary,
          steps: card.steps,
          checklist: card.checklist,
          fallback: card.fallback,
          startHint: card.startHint,
          stopHint: card.stopHint,
          completionCriteria: card.completionCriteria,
          tone: card.tone,
          styleVibe: card.styleVibe,
          targetAudience: card.targetAudience,
          script: card.script,
          pro: card.pro,
          rawMarkdown: card.rawMarkdown,
          shotComposition: card.shotComposition,
          shootingInstructions: card.shootingInstructions,
          storyboardImageUrl: card.storyboardImageUrl,
          referenceVideoUrl: card.referenceVideoUrl,
          referenceVideoTimestamp: card.referenceVideoTimestamp,
          location: card.location,
          cost: card.cost,
          peopleCount: card.peopleCount,
          shootingTimeMin: card.shootingTimeMin,
          thumbnailUrl: card.thumbnailUrl,
          compositionImages: updatedCompositionImages,
        );

        // CueCard 업데이트
        cueCards![cardIndex] = updatedCard;

        // Firebase에 자동 저장
        updateCurrentStoryboard().catchError((error) {
          print('[VLOG_DATA] Firebase 구도 이미지 저장 실패: $error');
        });
      }
    }
  }

  String? getCompositionImage(String sceneId, int checklistIndex) {
    // 먼저 메모리 캐시 확인
    final cachedImage = _compositionImages[sceneId]?[checklistIndex];
    if (cachedImage != null) return cachedImage;

    // CueCard에서도 확인
    if (cueCards != null) {
      final sceneIndex = int.tryParse(sceneId.replaceAll('scene_', '')) ?? 1;
      final cardIndex = sceneIndex - 1;

      if (cardIndex >= 0 && cardIndex < cueCards!.length) {
        final card = cueCards![cardIndex];
        return card.compositionImages?[checklistIndex];
      }
    }

    return null;
  }

  bool hasCompositionImage(String sceneId, int checklistIndex) {
    return getCompositionImage(sceneId, checklistIndex) != null;
  }
}

