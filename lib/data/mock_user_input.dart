/// Mock Data for User Input - 운동 브이로그
/// 임시 생성 버튼을 위한 더미 데이터

class MockUserInput {
  // 운동 브이로그 Mock Data
  static Map<String, String> getWorkoutVlogData() {
    return {
      // 컨셉 & 스타일 탭
      'vlog_concept': 'fitness',
      'style_preference': 'dynamic',
      'target_audience': 'fitness_beginner',
      'target_duration': '10',
      
      // 세부 계획 탭
      'location': '헬스장',
      'location_detail': '강남역 근처 피트니스 센터',
      'people': '1',
      'main_content': '상체 운동 루틴',
      'content_detail': '가슴, 어깨, 삼두 운동',
      'special_scene': '운동 후 프로틴 섭취',
      
      // 환경 탭
      'time_weather': 'daytime',
      'season': 'spring',
      'difficulty': 'intermediate',
      'equipment': 'smartphone',
      'equipment_detail': '삼각대, 짐벌',
      
      // 추가 정보
      'tone': 'energetic',
      'pacing': 'fast',
      'mood': '열정적이고 동기부여되는',
      'shooting_style': '다이나믹',
      
      // 예산 및 기타
      'budget_range': '50000',
      'special_requests': '운동 자세 클로즈업, 땀 흘리는 모습 강조, 비포/애프터 비교',
    };
  }
  
  // 여행 브이로그 Mock Data (추가 옵션)
  static Map<String, String> getTravelVlogData() {
    return {
      'vlog_concept': 'travel',
      'style_preference': 'cinematic',
      'target_audience': 'travel_lover',
      'target_duration': '12',
      
      'location': '제주도',
      'location_detail': '성산일출봉, 섭지코지, 카페거리',
      'people': '2',
      'main_content': '제주도 동부 투어',
      'content_detail': '맛집 탐방과 일출 촬영',
      'special_scene': '성산일출봉 정상에서 일출',
      
      'time_weather': 'sunrise',
      'season': 'autumn',
      'difficulty': 'intermediate',
      'equipment': 'mirrorless',
      'equipment_detail': 'Sony A7C, 24-70mm 렌즈, ND 필터',
      
      'tone': 'calm',
      'pacing': 'slow',
      'mood': '감성적이고 여유로운',
      'shooting_style': '시네마틱',
      
      'budget_range': '200000',
      'special_requests': '골든아워 촬영, 드론 샷, 로컬 맛집 포커스',
    };
  }
  
  // 일상 브이로그 Mock Data (추가 옵션)
  static Map<String, String> getDailyVlogData() {
    return {
      'vlog_concept': 'daily',
      'style_preference': 'casual',
      'target_audience': 'general',
      'target_duration': '8',
      
      'location': '집, 카페',
      'location_detail': '홍대 근처 감성 카페',
      'people': '1',
      'main_content': '주말 일상',
      'content_detail': '브런치 먹고 카페에서 작업',
      'special_scene': '카페 창가에서 노트북 작업',
      
      'time_weather': 'daytime',
      'season': 'winter',
      'difficulty': 'novice',
      'equipment': 'smartphone',
      'equipment_detail': '아이폰 14 Pro',
      
      'tone': 'friendly',
      'pacing': 'medium',
      'mood': '편안하고 친근한',
      'shooting_style': '캐주얼',
      
      'budget_range': '30000',
      'special_requests': '자연스러운 분위기, 브이로그 토크',
    };
  }
}
