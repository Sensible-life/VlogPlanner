import '../models/cue_template.dart';
import '../models/plan.dart';
import '../models/cue_card.dart';

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

  // 데이터 초기화
  void reset() {
    userInput.clear();
    templates = null;
    plan = null;
    cueCards = null;
    // 스토리보드 목록은 유지
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

