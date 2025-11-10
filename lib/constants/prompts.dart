class Prompts {
  // Fine-tuned model을 사용한 통합 스토리보드 생성 프롬프트
  static String buildFineTunedStoryboardPrompt(Map<String, String> userInput) {
    // 실제로 입력된 필드만 추출
    final inputLines = <String>[];
    
    if (userInput['target_duration']?.isNotEmpty ?? false) {
      inputLines.add('- 목표 영상 길이: ${userInput['target_duration']}분');
    }
    if (userInput['location']?.isNotEmpty ?? false) {
      inputLines.add('- 촬영 장소: ${userInput['location']}');
    }
    if (userInput['time_weather']?.isNotEmpty ?? false) {
      inputLines.add('- 시간/날씨: ${userInput['time_weather']}');
    }
    if (userInput['equipment']?.isNotEmpty ?? false) {
      inputLines.add('- 촬영 장비: ${userInput['equipment']}');
    }
    if (userInput['difficulty']?.isNotEmpty ?? false) {
      inputLines.add('- 난이도: ${userInput['difficulty']}');
    }
    
    // 추가 입력 필드들 (화면에서 입력받는 것들)
    if (userInput['subject']?.isNotEmpty ?? false) {
      inputLines.add('- 촬영 주제: ${userInput['subject']}');
    }
    if (userInput['target_audience']?.isNotEmpty ?? false) {
      inputLines.add('- 타깃 시청자: ${userInput['target_audience']}');
    }
    if (userInput['tone_manners']?.isNotEmpty ?? false) {
      inputLines.add('- 영상 톤&바이브: ${userInput['tone_manners']}');
    }
    if (userInput['required_location']?.isNotEmpty ?? false) {
      inputLines.add('- 필수 촬영 장소: ${userInput['required_location']}');
    }
    if (userInput['topics']?.isNotEmpty ?? false) {
      inputLines.add('- 대화 주제: ${userInput['topics']}');
    }
    if (userInput['crew_count']?.isNotEmpty ?? false) {
      inputLines.add('- 촬영 인원: ${userInput['crew_count']}');
    }
    if (userInput['restrictions']?.isNotEmpty ?? false) {
      inputLines.add('- 촬영 제약: ${userInput['restrictions']}');
    }
    if (userInput['memo']?.isNotEmpty ?? false) {
      inputLines.add('- 기타 메모: ${userInput['memo']}');
    }
    
    return '''
사용자의 입력을 바탕으로 완전한 브이로그 스토리보드를 생성해주세요.

[사용자 입력]
${inputLines.isEmpty ? '- 모든 항목을 기본 설정으로 생성하세요' : inputLines.join('\n')}

다음 형식의 JSON 객체를 반환해주세요 (코드 펜스 없이 순수 JSON만):

{
  "summary": "전체 스토리보드의 요약입니다. 브이로그의 전체적인 흐름과 내용을 간결하게 설명합니다.",
  "vlog_title": "매력적인 브이로그 제목 (예: 친구들과 오월드 나들이! 🎢)",
  "keywords": ["키워드1", "키워드2", "키워드3"],
  "goal_duration_min": 8,
  "buffer_rate": 0.12,
  "chapters": [
    {
      "id": "opening_gate",
      "alloc_sec": 30,
      "alternatives": []
    }
  ],
  "style_analysis": {
    "tone": "밝고 경쾌",
    "vibe": "MZ 감성",
    "pacing": "빠른 템포",
    "visual_style": ["다이나믹한 카메라 워크", "밝은 색감"],
    "audio_style": ["업비트 BGM", "자연스러운 나레이션"],
    "emotional_expression": 4,
    "movement": 3,
    "intensity": 4,
    "location_diversity": 3,
    "speed_rhythm": 4,
    "excitement_surprise": 5,
    "rationale": {
      "emotional_expression": "이 점수에 대한 1-2줄 이유 설명 (예: 친구들과의 자연스러운 대화와 감정 표현이 두드러지는 씬들)",
      "movement": "이 점수에 대한 1-2줄 이유 설명",
      "intensity": "이 점수에 대한 1-2줄 이유 설명",
      "location_diversity": "이 점수에 대한 1-2줄 이유 설명",
      "speed_rhythm": "이 점수에 대한 1-2줄 이유 설명",
      "excitement_surprise": "이 점수에 대한 1-2줄 이유 설명"
    }
  },
  "shooting_route": {
    "locations": [
      {
        "name": "메인 게이트",
        "description": "입구에서 오프닝 촬영",
        "latitude": 36.8109,
        "longitude": 127.1498,
        "order": 1
      }
    ],
    "route_description": "효율적인 동선 설명",
    "estimated_walking_minutes": 45
  },
  "budget": {
    "total_budget": 50000,
    "currency": "KRW",
    "items": [
      {
        "category": "입장료",
        "description": "테마파크 입장권",
        "amount": 30000
      },
      {
        "category": "식사",
        "description": "점심 식사",
        "amount": 15000
      },
      {
        "category": "기타",
        "description": "간식 및 음료",
        "amount": 5000
      }
    ]
  },
  "shooting_checklist": [
    "촬영 장비 충전 확인",
    "메모리카드 용량 확인",
    "조명 및 날씨 상황 확인",
    "추가 배터리 준비",
    "촬영 허가 필요 여부 확인"
  ],
  "scenes": [
    {
      "title": "씬 제목",
      "allocated_sec": 30,
      "trigger": "entrance",
      "summary": ["요약 1", "요약 2"],
      "steps": ["스텝 1", "스텝 2", "스텝 3"],
      "checklist": ["체크 1", "체크 2", "체크 3"],
      "fallback": "대안 방법",
      "start_hint": "시작 힌트",
      "stop_hint": "정지 힌트",
      "completion_criteria": "완료 기준",
      "tone": "밝고 경쾌",
      "style_vibe": "MZ",
      "target_audience": "20대 친구",
      "script": "간단한 대본 내용 (3-5줄)",
      "pro": {
        "framing": ["프레이밍 팁"],
        "audio": ["오디오 팁"],
        "dialogue": ["대화 예시 1", "대화 예시 2"],
        "edit_hint": ["편집 힌트"],
        "safety": ["안전 주의사항"],
        "broll": ["B-roll 제안"]
      }
    }
  ]
}

중요 요구사항:
1. summary는 전체 브이로그 스토리보드의 흐름과 내용을 간결하게 요약
2. vlog_title은 ${userInput['location']?.isNotEmpty ?? false ? userInput['location'] : '촬영 장소'} 맥락을 반영한 매력적인 제목
3. keywords는 정확히 3개 (예: "일상", "친구들과", "낮, 맑음")
4. chapters는 최소 10개 이상의 씬 (opening, main scenes, ending 포함)
5. style_analysis의 점수들은 1-5 사이의 정수 (사용자 입력에 맞게)
6. style_analysis.rationale의 각 항목은 해당 점수에 대한 구체적 이유를 1-2줄로 명시
7. budget.items에는 실제 촬영에 필요한 비용 내역을 상세히 포함 (입장료, 식사, 간식, 이동비 등)
8. shooting_checklist는 촬영 전 필요한 준비사항들을 실제적이고 구체적으로 제시
9. shooting_route의 GPS 좌표는 ${userInput['location']?.isNotEmpty ?? false ? userInput['location'] : '테마파크'}의 실제 위치 기반
   - 오월드: (36.8109, 127.1498) 근처
   - 에버랜드: (37.2940, 127.2020) 근처
   - 롯데월드: (37.5111, 127.0980) 근처
10. scenes는 chapters와 동일한 수 (최소 10개)
11. 각 씬의 script는 해당 씬의 간단한 대본 (3-5줄, 나레이션/대화 형식)
12. 모든 텍스트는 한국어로 작성
13. 순수 JSON만 반환 (코드 펜스나 설명 없이)
''';
  }

  // ============================================
  // [DEPRECATED] 아래 프롬프트들은 Fine-tuned model 사용으로 더 이상 필요하지 않습니다.
  // ============================================

  // [DEPRECATED] 템플릿 생성 프롬프트 - buildFineTunedStoryboardPrompt() 사용
  // static String buildTemplatePrompt(List<String> urls) { ... }

  // [DEPRECATED] 템플릿 정리 프롬프트 - buildFineTunedStoryboardPrompt() 사용
  // static String buildCleaningPrompt(String templateResponse) { ... }

  // [DEPRECATED] 계획 생성 프롬프트 - buildFineTunedStoryboardPrompt() 사용
  // static String buildPlanPrompt(Map<String, String> userInput) { ... }

  // [DEPRECATED] 큐카드 생성 프롬프트 - buildFineTunedStoryboardPrompt() 사용
  // static String buildCueCardPrompt(String templatesJson, String planJson) { ... }

  // [DEPRECATED] 큐카드 생성 프롬프트 (분할용) - buildFineTunedStoryboardPrompt() 사용
  // static String buildCueCardPromptBatch(...) { ... }
}
