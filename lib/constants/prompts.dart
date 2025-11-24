class Prompts {
  // Fine-tuned model을 사용한 Plan 정보 생성 프롬프트 (첫 번째 API 호출)
  static String buildFineTunedPlanPrompt(Map<String, String> userInput) {
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
    
    // 추가 입력 필드들
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
사용자의 입력을 바탕으로 브이로그 스토리보드의 Plan 정보와 대체 씬을 생성해주세요.

**[절대 중요] 씬 개수 규칙:**
- **chapters 배열에는 반드시 최소 10개 이상의 씬을 생성해야 합니다.**
- 6개, 7개, 8개, 9개처럼 10개 미만은 절대 안 됩니다.

[사용자 입력]
${inputLines.isEmpty ? '- 모든 항목을 기본 설정으로 생성하세요' : inputLines.join('\n')}

다음 형식의 JSON 객체를 반환해주세요 (코드 펜스 없이 순수 JSON만):

{
  "summary": "전체 스토리보드의 요약 (2문단, 각 문단 2문장)",
  "vlog_title": "매력적인 브이로그 제목",
  "keywords": ["키워드1", "키워드2", "키워드3"],
  "goal_duration_min": 8,
  "equipment": "스마트폰",
  "total_people": 3,
  "buffer_rate": 0.12,
  "user_notes": "",
  "chapters": [
    {"id": "opening_gate", "alloc_sec": 30, "alternatives": []}
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
      "emotional_expression": "• '씬 제목' 씬에서 구체적인 감정 표현\n• '씬 제목' 씬에서 구체적인 감정 표현",
      "movement": "• '씬 제목' 씬에서 구체적인 카메라 워크\n• '씬 제목' 씬에서 구체적인 카메라 워크",
      "intensity": "• '씬 제목' 씬에서 구체적인 강도 표현\n• '씬 제목' 씬에서 구체적인 강도 표현",
      "location_diversity": "• 구체적인 장소명과 씬 제목\n• 구체적인 장소명과 씬 제목",
      "speed_rhythm": "• '씬 제목' 씬에서 구체적인 템포\n• '씬 제목' 씬에서 구체적인 템포",
      "excitement_surprise": "• '씬 제목' 씬에서 구체적인 흥미 요소\n• '씬 제목' 씬에서 구체적인 흥미 요소"
    }
  },
  "shooting_route": {
    "locations": [
      {"name": "메인 게이트", "description": "입구", "latitude": 36.8109, "longitude": 127.1498, "order": 1, "scene_ids": []}
    ],
    "route_description": "효율적인 동선 설명",
    "estimated_walking_minutes": 45
  },
  "budget": {
    "total_budget": 50000,
    "currency": "KRW",
    "items": [
      {"category": "입장료", "description": "테마파크 입장권", "amount": 30000}
    ]
  },
  "shooting_checklist": ["촬영 장비 충전 확인", "메모리카드 용량 확인"],
  "alternative_scenes": [
    {
      "id": "alt_1",
      "title": "친구들과 함께하는 저녁 식사",
      "allocated_sec": 30,
      "trigger": "entrance",
      "summary": ["대체 씬 설명"],
      "steps": ["스텝 1", "스텝 2"],
      "checklist": ["와이드 샷으로 전체 장면 포착", "주인공 클로즈업으로 표정 촬영", "주변 환경/분위기 촬영"],
      "fallback": "대안 방법",
      "start_hint": "시작 힌트",
      "stop_hint": "정지 힌트",
      "completion_criteria": "완료 기준",
      "tone": "밝고 경쾌",
      "style_vibe": "MZ",
      "target_audience": "20대 친구",
      "script": "",
      "shot_composition": ["구도 1", "구도 2"],
      "shooting_instructions": ["촬영 지시사항 1"],
      "location": "메인 게이트 앞",
      "cost": 0,
      "people_count": 3,
      "shooting_time_min": 5,
      "storyboard_image_url": "",
      "reference_video_url": "",
      "reference_video_timestamp": 0
    }
  ]
}

**[중요] 위치 규칙:**
- 필수 촬영 장소가 명시된 경우, 모든 씬의 location과 GPS 좌표는 필수 촬영 장소와 같은 지역이어야 합니다.
- 모든 씬의 GPS 좌표는 필수 촬영 장소로부터 반경 10km 이내에 있어야 합니다.

중요 요구사항:
1. summary는 2문단, 각 문단 2문장
2. chapters는 반드시 10개 이상
3. rationale은 scenes 생성 후 작성 (임시로 씬 제목 플레이스홀더 사용 가능)
4. alternative_scenes는 정확히 4개, 각각 고유한 id (alt_1, alt_2, alt_3, alt_4)
5. 대체 씬의 title은 구체적인 제목으로 작성 (예: "친구들과 함께하는 저녁 식사")
''';
  }

  // Fine-tuned model을 사용한 Scenes 배열 생성 프롬프트 (두 번째 API 호출)
  static String buildFineTunedScenesPrompt(Map<String, String> userInput, Map<String, dynamic> planData) {
    // 실제로 입력된 필드만 추출
    final inputLines = <String>[];
    
    if (userInput['target_duration']?.isNotEmpty ?? false) {
      inputLines.add('- 목표 영상 길이: ${userInput['target_duration']}분');
    }
    if (userInput['location']?.isNotEmpty ?? false) {
      inputLines.add('- 촬영 장소: ${userInput['location']}');
    }
    if (userInput['required_location']?.isNotEmpty ?? false) {
      inputLines.add('- 필수 촬영 장소: ${userInput['required_location']}');
    }
    
    // Plan 정보 요약
    final planSummary = planData['summary'] ?? '';
    final vlogTitle = planData['vlog_title'] ?? '';
    final chapters = planData['chapters'] as List? ?? [];
    final alternativeScenes = planData['alternative_scenes'] as List? ?? [];
    
    return '''
사용자의 입력과 생성된 Plan 정보를 바탕으로 scenes 배열을 생성해주세요.

[사용자 입력]
${inputLines.isEmpty ? '- 모든 항목을 기본 설정으로 생성하세요' : inputLines.join('\n')}

[생성된 Plan 정보]
- 제목: $vlogTitle
- 요약: $planSummary
- 챕터 개수: ${chapters.length}개
- 대체 씬 개수: ${alternativeScenes.length}개

**[절대 중요] scenes 배열 생성 규칙:**
- **scenes 배열에는 반드시 최소 10개 이상의 씬을 생성해야 합니다.**
- 6개, 7개, 8개, 9개처럼 10개 미만은 절대 안 됩니다.
- chapters 배열의 개수와 동일한 수의 씬을 생성하세요.
- 각 씬에 alternative_scene_id를 할당하세요 (alt_1, alt_2, alt_3, alt_4 중 하나, 중복 허용)

다음 형식의 JSON 객체를 반환해주세요 (코드 펜스 없이 순수 JSON만):

{
  "scenes": [
    {
      "title": "씬 제목",
      "allocated_sec": 30,
      "trigger": "entrance",
      "summary": ["씬 설명 (한 두 문장)"],
      "steps": ["스텝 1", "스텝 2", "스텝 3"],
      "checklist": ["와이드 샷으로 전체 장면 포착", "주인공 클로즈업으로 표정 촬영", "주변 환경/분위기 촬영"],
      "fallback": "대안 방법",
      "start_hint": "시작 힌트",
      "stop_hint": "정지 힌트",
      "completion_criteria": "완료 기준",
      "tone": "밝고 경쾌",
      "style_vibe": "MZ",
      "target_audience": "20대 친구",
      "script": "",
      "shot_composition": ["와이드 샷으로 전체 장면 포착", "클로즈업으로 표정 강조"],
      "shooting_instructions": ["카메라를 안정적으로 고정", "자연광 활용", "흔들림 최소화"],
      "location": "메인 게이트 앞",
      "cost": 0,
      "people_count": 3,
      "shooting_time_min": 5,
      "storyboard_image_url": "",
      "reference_video_url": "",
      "reference_video_timestamp": 0,
      "pro": {
        "framing": ["프레이밍 팁"],
        "audio": ["오디오 팁"],
        "dialogue": ["대화 예시 1", "대화 예시 2"],
        "edit_hint": ["편집 힌트"],
        "safety": ["안전 주의사항"],
        "broll": ["B-roll 제안"]
      },
      "alternative_scene_id": "alt_1"
    }
  ]
}

**[중요] 위치 규칙:**
- 필수 촬영 장소가 명시된 경우, 모든 씬의 location은 필수 촬영 장소와 같은 지역이어야 합니다.
- 모든 씬에 반드시 location 정보가 있어야 합니다.
''';
  }

  // Fine-tuned model을 사용한 통합 스토리보드 생성 프롬프트 (하위 호환성 유지)
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

**[절대 중요] 씬 개수 규칙 (이 규칙을 위반하면 스토리보드가 무효화됩니다):**
- **scenes 배열에는 반드시 최소 10개 이상의 씬을 생성해야 합니다.**
- 6개, 7개, 8개, 9개처럼 10개 미만은 절대 안 됩니다.
- **JSON을 생성하기 전에 반드시 scenes 배열의 개수를 세어보고, 10개 미만이면 더 많은 씬을 추가하세요.**

[사용자 입력]
${inputLines.isEmpty ? '- 모든 항목을 기본 설정으로 생성하세요' : inputLines.join('\n')}

**[중요] scenes 배열 생성 전 확인사항:**
- scenes 배열에는 반드시 최소 10개 이상의 씬을 생성해야 합니다.
- 6개, 7개, 8개, 9개처럼 10개 미만은 절대 안 됩니다.
- 가능하면 12~15개 정도로 생성하세요.
- JSON을 생성하기 전에 반드시 scenes 배열의 개수를 세어보고, 10개 미만이면 더 많은 씬을 추가하세요.

다음 형식의 JSON 객체를 반환해주세요 (코드 펜스 없이 순수 JSON만):

{
  "summary": "전체 스토리보드의 요약입니다. 브이로그의 전체적인 흐름과 내용을 상세하게 설명합니다.\n\n총 2문단으로 작성하고, 각 문단은 2문장으로 구성하세요. 문단과 문단 사이에는 빈 줄 하나를 넣어 가독성을 높이세요. 브이로그의 시작부터 끝까지의 전체적인 흐름, 주요 장면들, 분위기와 톤을 구체적으로 포함하여 작성하세요.",
  "vlog_title": "매력적인 브이로그 제목 (예: 친구들과 오월드 나들이! 🎢)",
  "keywords": ["키워드1", "키워드2", "키워드3"],
  "goal_duration_min": 8,
  "equipment": "스마트폰",
  "total_people": 3,
  "buffer_rate": 0.12,
  "user_notes": "촬영 시 주의사항이나 특별한 메모",
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
      "emotional_expression": "• '메인 게이트 입장' 씬에서 친구들과의 기대감 넘치는 대화 포착\n• '롤러코스터 탑승' 씬에서 스릴 넘치는 표정과 환호성\n• '저녁 식사' 씬에서 하루를 돌아보며 나누는 솔직한 감정 공유",
      "movement": "• '입장 게이트' 씬의 워킹샷으로 자연스러운 이동감 표현\n• '놀이기구 탑승' 씬의 핸드헬드 촬영으로 역동적인 카메라 워크\n• '공원 산책' 씬의 팬/틸트를 활용한 환경 포착",
      "intensity": "• '롤러코스터' 씬의 빠른 컷과 클로즈업으로 긴장감 극대화\n• '퍼레이드 관람' 씬의 와이드샷으로 웅장한 분위기 연출\n• '저녁 모닥불' 씬의 따뜻한 조명과 차분한 리듬으로 대비",
      "location_diversity": "• 메인 게이트, 롤러코스터 존, 푸드코트, 포토존, 분수대 등 5개 이상의 다양한 공간 활용\n• 실내(푸드코트)와 실외(놀이기구 존) 장소를 적절히 배치\n• 각 장소마다 고유한 배경과 분위기 제공",
      "speed_rhythm": "• 오프닝과 놀이기구 씬의 빠른 편집으로 흥미 유발\n• 점심 식사와 휴식 씬의 여유로운 템포로 완급 조절\n• 클로징 씬의 감성적인 슬로우모션으로 여운 남김",
      "excitement_surprise": "• '롤러코스터 탑승' 씬의 예상치 못한 스릴과 반응\n• '캐릭터 만남' 씬의 깜짝 이벤트와 놀라움\n• '저녁 불꽃놀이' 씬의 감동적인 피날레"
    }
  },
  "shooting_route": {
    "locations": [
      {
        "name": "메인 게이트",
        "description": "입구에서 오프닝 촬영",
        "latitude": 36.8109,
        "longitude": 127.1498,
        "order": 1,
        "scene_ids": ["scene_1", "scene_2"]
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
      "summary": ["씬에 대한 간단한 설명입니다. 한 두 문장 정도로 씬의 내용과 목적을 상세하게 설명하세요.", "씬의 핵심 내용이나 주요 액션을 포함하여 작성하세요."],
      "steps": ["스텝 1", "스텝 2", "스텝 3"],
      "checklist": ["와이드 샷으로 전체 장면 포착", "주인공 클로즈업으로 표정 촬영", "주변 환경/분위기 촬영", "반응샷 또는 인터랙션 촬영"],
      "fallback": "대안 방법",
      "start_hint": "시작 힌트",
      "stop_hint": "정지 힌트",
      "completion_criteria": "완료 기준",
      "tone": "밝고 경쾌",
      "style_vibe": "MZ",
      "target_audience": "20대 친구",
      "script": "",
      "shot_composition": ["와이드 샷으로 전체 장면 포착", "클로즈업으로 표정 강조"],
      "shooting_instructions": ["카메라를 안정적으로 고정", "자연광 활용", "흔들림 최소화"],
      "location": "메인 게이트 앞",
      "cost": 0,
      "people_count": 3,
      "shooting_time_min": 5,
      "storyboard_image_url": "",
      "reference_video_url": "",
      "reference_video_timestamp": 0,
      "pro": {
        "framing": ["프레이밍 팁"],
        "audio": ["오디오 팁"],
        "dialogue": ["대화 예시 1", "대화 예시 2"],
        "edit_hint": ["편집 힌트"],
        "safety": ["안전 주의사항"],
        "broll": ["B-roll 제안"]
      },
      "alternative_scene_id": "alt_1"
    }
  ],
  "alternative_scenes": [
    {
      "id": "alt_1",
      "title": "친구들과 함께하는 저녁 식사",
      "allocated_sec": 30,
      "trigger": "entrance",
      "summary": ["대체 씬 1의 설명입니다. 원본 씬과 다른 관점이나 접근 방식을 제시하세요."],
      "steps": ["대체 스텝 1", "대체 스텝 2"],
      "checklist": ["와이드 샷으로 전체 장면 포착", "주인공 클로즈업으로 표정 촬영", "주변 환경/분위기 촬영"],
      "fallback": "대안 방법",
      "start_hint": "시작 힌트",
      "stop_hint": "정지 힌트",
      "completion_criteria": "완료 기준",
      "tone": "밝고 경쾌",
      "style_vibe": "MZ",
      "target_audience": "20대 친구",
      "script": "",
      "shot_composition": ["대체 구도 1", "대체 구도 2"],
      "shooting_instructions": ["대체 촬영 지시사항 1"],
      "location": "메인 게이트 앞",
      "cost": 0,
      "people_count": 3,
      "shooting_time_min": 5,
      "storyboard_image_url": "",
      "reference_video_url": "",
      "reference_video_timestamp": 0
    }
  ]
}

**[절대 중요] 위치 규칙 (이 규칙을 위반하면 스토리보드가 무효화됩니다):**
- 필수 촬영 장소(required_location)가 명시된 경우, **모든 씬(1번째부터 마지막 씬까지 100%)의 location과 GPS 좌표는 반드시 필수 촬영 장소와 같은 지역이어야 합니다.**
- 필수 촬영 장소의 GPS 좌표를 기준으로, **모든 씬의 GPS 좌표는 반경 10km 이내에 있어야 합니다.**
- **절대로 덕수궁, 경복궁, 서울시청, 부산, 인천 등 다른 지역의 좌표를 사용하지 마세요.**
- 각 씬을 생성할 때마다 GPS 좌표를 설정하기 전에 "이 좌표가 필수 촬영 장소로부터 10km 이내인가?"를 반드시 확인하세요.
- 위도 1도 ≈ 111km, 경도 1도 ≈ 88km (한국 기준)이므로, 10km 이내는 위도/경도로 약 0.09도 이내입니다.

중요 요구사항:
1. summary는 전체 브이로그 스토리보드의 흐름과 내용을 상세하게 요약 (2문단, 각 문단 2문장)
   - 총 2문단으로 작성하고, 각 문단은 정확히 2문장으로 구성하세요
   - 문단과 문단 사이에는 빈 줄 하나(\n\n)를 넣어 가독성을 높이세요
   - 브이로그의 시작부터 끝까지의 전체적인 흐름, 주요 장면들, 분위기와 톤을 구체적이고 상세하게 포함하여 작성하세요
2. vlog_title은 ${userInput['location']?.isNotEmpty ?? false ? userInput['location'] : '촬영 장소'} 맥락을 반영한 매력적인 제목
3. keywords는 정확히 3개 (예: "일상", "친구들과", "낮, 맑음")
4. equipment는 사용자가 입력한 촬영 장비 (예: "스마트폰", "DSLR", "미러리스")
5. total_people은 전체 촬영에 참여하는 인원 수 (사용자 입력 기반)
6. user_notes는 촬영 시 특별히 주의할 사항이나 메모 (선택사항, 없으면 빈 문자열)
7. **[절대 중요] chapters는 반드시 10개 이상의 씬을 생성해야 합니다** (opening, main scenes, ending 포함). 
    - **6개, 7개, 8개, 9개처럼 10개 미만은 절대 안 됩니다.**
    - **JSON을 생성하기 전에 반드시 chapters 배열의 개수를 세어보고, 10개 미만이면 더 많은 씬을 추가하세요.**
    - **씬 개수가 부족하면 스토리보드가 무효화됩니다.**
8. style_analysis의 점수들은 1-5 사이의 정수 (사용자 입력에 맞게)
9. **[절대 중요] style_analysis.rationale의 각 항목 작성 규칙:**
   - **반드시 scenes 배열을 먼저 완전히 생성한 후**, 그 씬들을 참조하여 rationale을 작성해야 함
   - **각 rationale 필드는 정확히 2~3개의 bullet point를 포함** (각 bullet point는 줄바꿈 문자 \n으로 구분)
   - **[매우 중요] 각 bullet point는 반드시 실제로 생성한 씬의 제목과 장소명을 구체적으로 언급해야 함**
   - **[절대 금지] 추상적이거나 일반적인 설명은 절대 사용 금지** (예: "카메라 이동이 자연스럽고 다양함", "장소가 다양함" 등)
   - **필수 포함 요소:** 씬 제목 (따옴표로 감싸기), 장소명, 구도/카메라 워크, 감정/분위기

   **올바른 예시 (O):**
   • "'성산일출봉 정상 도착' 씬에서 와이드샷으로 웅장한 일출을 포착하며 감탄하는 표정"
   • "'우도 해녀의 집 점심' 씬에서 친구들과 식사하며 나누는 자연스러운 대화와 웃음"
   • "'섭지코지 해안 산책' 씬에서 핸드헬드 촬영으로 바다를 바라보는 감동적인 반응샷"

   **잘못된 예시 (X):**
   • "카메라 이동이 자연스럽고 다양한 장면을 포착함" (씬 제목과 장소명 없음)
   • "제주도의 다양한 명소를 배경으로 함" (구체적 씬 언급 없음)
   • "여행 중 만나는 새로운 경험" (실제 씬 참조 없음)

   - **작성 순서:**
     1. scenes 배열을 먼저 완전히 생성
     2. 생성된 씬들의 제목과 장소를 정확히 확인
     3. 그 씬들을 바탕으로 rationale 작성
   - **각 bullet point는 "• '[씬 제목]' 씬에서..." 형식으로 시작**
   - **점수와 연관성:** 높은 점수일수록 더 강렬하고 역동적인 씬들을 언급
   - **모든 6개 필드(emotional_expression, movement, intensity, location_diversity, speed_rhythm, excitement_surprise)에 동일한 규칙 적용**
10. shooting_route.locations의 각 항목에 scene_ids 배열 추가 (해당 위치에서 촬영할 씬들의 ID)
11. shooting_route의 GPS 좌표는 ${userInput['location']?.isNotEmpty ?? false ? userInput['location'] : '테마파크'}의 실제 위치 기반
    - 오월드: (36.8109, 127.1498) 근처
    - 에버랜드: (37.2940, 127.2020) 근처
    - 롯데월드: (37.5111, 127.0980) 근처
12. budget.items에는 실제 촬영에 필요한 비용 내역을 상세히 포함 (입장료, 식사, 간식, 이동비 등)
13. shooting_checklist는 촬영 전 필요한 준비사항들을 실제적이고 구체적으로 제시 (배터리, 메모리, 장비 등). **난이도는 기본적으로 초보자 수준으로 가정하여, 초보자도 쉽게 따라할 수 있는 간단하고 명확한 체크리스트를 제공하세요.**
14. **[절대 중요] scenes는 chapters와 동일한 수이며, 반드시 10개 이상이어야 합니다.** 
    - **6개, 7개, 8개, 9개처럼 10개 미만은 절대 안 됩니다.**
    - **JSON을 생성하기 전에 반드시 scenes 배열의 개수를 세어보고, 10개 미만이면 더 많은 씬을 추가하세요.**
    - **씬 개수가 부족하면 스토리보드가 무효화됩니다.**
15. **촬영 난이도는 기본적으로 초보자 수준으로 가정합니다. 모든 씬의 steps, checklist, shooting_instructions는 초보자도 쉽게 따라할 수 있도록 간단하고 명확하게 작성하세요.**
16. **[매우 중요] 전체 스토리보드에 대한 대체 씬(alternative_scenes) 4개를 반드시 생성:**
    - **Plan 레벨에 정확히 4개의 대체 씬을 생성**해야 합니다 (alternative_scenes 배열에 정확히 4개의 씬 포함)
    - 각 대체 씬은 **고유한 id**를 가져야 합니다 (예: "alt_1", "alt_2", "alt_3", "alt_4")
    - 대체 씬은 **다양한 관점, 다른 촬영 방식, 다른 분위기**로 스토리보드의 주요 목적을 달성할 수 있는 씬입니다
    - **[절대 중요] 대체 씬의 title은 "대체 씬 제목 1" 같은 제네릭한 제목이 아닌, 실제 씬들처럼 구체적이고 의미 있는 제목으로 작성해야 합니다.**
      * 예시 (나쁜 예): "대체 씬 제목 1", "대체 씬 1", "Alternative Scene 1"
      * 예시 (좋은 예): "친구들과 함께하는 저녁 식사", "일몰을 배경으로 한 감성 샷", "카페에서의 여유로운 대화", "마지막 인사와 작별 인사"
      * 실제 scenes 배열의 씬 제목과 유사한 스타일로 작성하되, 다른 관점이나 접근 방식을 반영한 구체적인 제목을 작성하세요
      * 스토리보드의 주요 장면을 대체할 수 있는 실제적인 제목으로 작성하세요
    - 대체 씬의 summary, checklist, shot_composition, shooting_instructions는 실제 씬들과 유사한 수준으로 작성하세요
    - 대체 씬에는 pro 필드를 포함하지 마세요
    - **각 실제 씬(scenes 배열의 각 씬)에는 alternative_scene_id 필드를 추가**하여 4개 중 하나와 매칭하세요
    - alternative_scene_id는 "alt_1", "alt_2", "alt_3", "alt_4" 중 하나여야 하며, 여러 씬이 같은 ID를 가져도 됩니다 (중복 허용)
17. **[중요] 각 씬에 다음 필드들을 반드시 포함:**
    - shot_composition: 구도 정보 배열 (예: "와이드 샷으로 전체 장면", "클로즈업으로 표정 강조", "미디엄 샷으로 대화" 등)
    - shooting_instructions: 촬영 지시사항 배열 (예: "카메라 고정", "자연광 활용", "흔들림 최소화" 등). **초보자 수준에 맞게 간단하고 명확하게 작성하세요.**
    - **summary**: 씬에 대한 간단한 설명 배열. **각 항목은 한 두 문장 정도로 씬의 내용과 목적을 상세하게 설명하세요.** 현재 너무 짧으니 더 길고 구체적으로 작성하세요. (예: "오프닝 씬으로, 친구들과 함께 테마파크 입구에 도착한 모습을 보여줍니다. 설렘과 기대감이 느껴지는 밝고 경쾌한 분위기로 촬영합니다.")
    - **checklist**: 해당 씬에서 **반드시 찍어야 할 것들의 체크리스트 배열 (3~4개)**. 각 씬의 구도(shot_composition)와 촬영 지시사항(shooting_instructions)을 바탕으로, 실제 촬영 시 확인해야 할 구체적인 항목들을 작성하세요.
      * 예시: "와이드 샷으로 전체 장면 포착", "주인공 클로즈업으로 표정 촬영", "주변 환경/분위기 촬영", "반응샷 또는 인터랙션 촬영" 등
      * 각 항목은 촬영자가 "이것을 찍었는가?"를 확인할 수 있도록 구체적이고 명확해야 합니다
      * shot_composition과 연관되어야 하며, 씬의 목적과 내용에 맞는 필수 촬영 항목을 포함해야 합니다
      * 반드시 3~4개의 체크리스트 항목을 생성하세요
    - **location**: 씬의 구체적인 촬영 장소 (예: "메인 게이트 앞", "푸드코트 내부"). **모든 씬에 반드시 위치 정보가 있어야 합니다.**
      * **[절대 금지] 모든 씬의 location은 필수 촬영 장소(required_location)와 반드시 같은 지역/위치에 있어야 합니다.**
      * **[매우 중요] 씬 번호와 관계없이, 1번째 씬부터 마지막 씬까지, 100% 모든 씬의 location은 필수 촬영 장소와 같은 지역이어야 합니다.**
      * 필수 촬영 장소가 여행지/관광지(예: 제주도, 오월드, 에버랜드 등)인 경우: 
        - **모든 씬(1번째, 2번째, 3번째, 4번째, 5번째, 6번째, 7번째, 8번째, 9번째, 10번째... 마지막 씬까지, 100% 모든 씬)의 location은 해당 여행지/관광지 내부 또는 근처**에 있어야 합니다.
        - 예를 들어 제주도 여행이면 모든 씬(저녁 식사, 산책, 카페, 호텔 체크인, 체크아웃, 마지막 씬 등)이 제주도 내부에 있어야 합니다.
        - **7번째 씬, 8번째 씬, 9번째 씬, 10번째 씬 등 나중 씬들도 절대로 예외가 없습니다. 모두 필수 촬영 장소와 같은 지역이어야 합니다.**
        - 절대로 서울, 부산, 인천 등 다른 지역으로 설정하지 마세요.
        - 마지막 씬도 예외 없이 필수 촬영 장소와 같은 지역이어야 합니다.
      * 필수 촬영 장소 근처의 카페, 거리, 포토존, 식당, 호텔 등 실제 촬영 가능한 구체적인 위치를 지정하되, 반드시 필수 촬영 장소와 같은 지역에 있어야 합니다.
      * 특이 장소(헬스장, 집 등)인 경우: 사용자의 현재 GPS 위치를 기반으로 한 일반적인 위치명 사용 (예: "서울 강남구 헬스장", "서울 마포구 아파트")
      * **[매우 중요] 각 씬을 생성할 때마다 (특히 7번째 씬 이후부터) location을 설정하기 전에 "이 씬의 location이 필수 촬영 장소와 같은 지역인가?"를 반드시 확인하세요.**
      * **[절대 금지] 씬 번호가 커질수록 다른 지역으로 설정하는 것은 절대 안 됩니다. 모든 씬이 필수 촬영 장소와 같은 지역이어야 합니다.**
    - **cost**: 해당 씬의 예상 비용 (원 단위, **반드시 포함, 비용이 없으면 0으로 설정**). 모든 씬에 cost 필드가 있어야 하며, 0원이어도 명시적으로 0으로 설정해야 합니다.
    - people_count: 해당 씬에 필요한 촬영 인원 수
    - shooting_time_min: 해당 씬의 예상 촬영 시간 (분 단위)
    - storyboard_image_url: 빈 문자열로 유지 (앱에서 자동으로 스케치 이미지 생성)
    - **reference_video_url**: 해당 씬의 촬영 스타일/구도와 유사한 YouTube 레퍼런스 영상 URL (선택사항). 운동 브이로그의 경우 "https://www.youtube.com/watch?v=VIDEO_ID" 형식으로 제공. 적절한 레퍼런스가 없으면 빈 문자열. 예: 운동 브이로그 씬이라면 실제 운동 브이로그 YouTube URL 제공.
    - **reference_video_timestamp**: 레퍼런스 영상에서 해당 씬의 구도와 가장 유사한 부분의 시작 시점 (초 단위 정수). reference_video_url이 있을 때만 유효한 timestamp 제공 (예: 45초 지점이면 45). 레퍼런스 영상이 없으면 0으로 설정.
18. **script 필드는 빈 문자열("")로 유지하세요. 대본 생성은 필요하지 않습니다.**
19. **[절대 중요] shooting_route.locations에 모든 씬의 위치 정보를 포함:**
    - **모든 씬(1번째부터 마지막 씬까지 100%)의 location을 shooting_route.locations에 반드시 포함해야 합니다.**
    - 각 씬의 location 필드에 명시된 위치를 기반으로 shooting_route.locations에 마커를 추가
    - **중요: 씬이 10개면 shooting_route.locations에도 최소 10개의 위치가 있어야 합니다. 6개나 7개처럼 적은 개수는 절대 안 됩니다.**
    - 각 location의 scene_ids 배열에 해당 위치에서 촬영하는 모든 씬의 ID를 포함
    - **[절대 금지] 모든 씬의 GPS 좌표는 필수 촬영 장소(required_location)와 반드시 같은 지역에 있어야 합니다.**
    - **[매우 중요] 씬 번호와 관계없이, 1번째 씬부터 마지막 씬까지, 100% 모든 씬의 GPS 좌표는 필수 촬영 장소와 같은 지역이어야 합니다.**
    - 필수 촬영 장소가 여행지/관광지인 경우: 
      * **먼저 필수 촬영 장소의 실제 GPS 좌표를 확인하세요.**
      * 해당 장소의 실제 GPS 좌표를 기준으로, **모든 씬(1번째, 2번째, 3번째, 4번째, 5번째, 6번째, 7번째, 8번째, 9번째, 10번째... 마지막 씬까지, 100% 모든 씬)의 location이 그 주변(반경 10km 이내)에 있도록 GPS 좌표를 설정**
      * **중요: 반경 10km를 절대 초과하지 마세요. 10km를 넘어가면 다른 지역으로 간주됩니다.**
      * **7번째 씬, 8번째 씬, 9번째 씬, 10번째 씬 등 나중 씬들도 절대로 예외가 없습니다. 모두 필수 촬영 장소 주변 10km 이내에 있어야 합니다.**
      * 예: 제주도 여행이면 모든 씬(저녁 식사, 산책, 카페, 호텔 체크인, 체크아웃, 마지막 씬 등)이 제주도 내부 좌표(위도 33.4~33.6, 경도 126.4~126.8)에 있어야 함
      * **절대로 다른 지역(예: 서울 덕수궁, 경복궁, 부산, 인천 등)의 좌표를 사용하지 마세요. 마지막 씬도 예외 없이 필수 촬영 장소와 같은 지역이어야 합니다.**
      * **각 씬의 GPS 좌표를 설정하기 전에 반드시 다음을 확인하세요:**
        1. "이 좌표가 필수 촬영 장소의 GPS 좌표와 같은 지역인가?"
        2. "이 좌표가 필수 촬영 장소로부터 10km 이내인가?"
        3. "이 좌표가 덕수궁(37.5658, 126.9750), 경복궁(37.5796, 126.9770) 같은 다른 장소의 좌표가 아닌가?"
      * GPS 좌표 계산 시: 위도 1도 ≈ 111km, 경도 1도 ≈ 88km (한국 기준)이므로, 10km 이내는 위도/경도로 약 0.09도 이내입니다.
      * **필수 촬영 장소의 GPS 좌표를 기준으로 ±0.09도 범위 내에서만 좌표를 생성하세요.**
      * **[절대 금지] 씬 번호가 커질수록 다른 지역의 GPS 좌표를 사용하는 것은 절대 안 됩니다. 모든 씬이 필수 촬영 장소 주변 10km 이내에 있어야 합니다.**
    - 특이 장소(헬스장, 집 등)인 경우: 사용자의 현재 위치를 기반으로 한 GPS 좌표 사용 (서울 기준: 위도 37.5~37.6, 경도 126.9~127.1 범위 내에서 적절한 좌표 지정)
    - 모든 씬이 shooting_route.locations에 매핑되어야 하며, 각 location의 scene_ids 배열에 해당 씬의 ID를 포함
20. **[중요] budget 계산:**
    - budget.items에는 전체 스토리보드의 예산 항목을 포함
    - **budget.total_budget는 모든 씬의 cost 필드를 합산한 값이어야 합니다** (각 씬의 cost 합계)
    - 각 씬의 cost가 0원이 아닌 경우, 해당 비용을 적절한 budget.items 카테고리(입장료, 식사, 간식, 이동비 등)에 포함
21. 모든 텍스트는 한국어로 작성
22. 순수 JSON만 반환 (코드 펜스나 설명 없이)
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

  // 스토리보드 수정 프롬프트
  static String buildStoryboardModificationPrompt({
    required Map<String, dynamic> currentStoryboard,
    required String modificationRequest,
  }) {
    // 현재 스토리보드 정보
    final plan = currentStoryboard['plan'] as Map<String, dynamic>? ?? {};
    final scenes = currentStoryboard['scenes'] as List<dynamic>? ?? [];
    final userInput = currentStoryboard['user_input'] as Map<String, dynamic>? ?? {};
    
    // 모든 씬 정보를 간결하게 정리 (인덱스 포함)
    final allScenesInfo = scenes.asMap().entries.map((entry) {
      final index = entry.key;
      final scene = entry.value as Map<String, dynamic>;
      final title = scene['title'] ?? '씬 ${index + 1}';
      final summary = scene['summary'] is List 
          ? (scene['summary'] as List).join(' ')
          : (scene['summary'] ?? '');
      final location = scene['location'] ?? '';
      return '${index + 1}. $title (장소: $location) - ${summary.length > 60 ? summary.substring(0, 60) + '...' : summary}';
    }).join('\n');
    
    // 사용자 입력 정보 요약
    final userInputSummary = <String>[];
    if (userInput['location'] != null) {
      userInputSummary.add('장소: ${userInput['location']}');
    }
    if (userInput['target_duration'] != null) {
      userInputSummary.add('목표 길이: ${userInput['target_duration']}분');
    }
    if (userInput['equipment'] != null) {
      userInputSummary.add('장비: ${userInput['equipment']}');
    }

    return '''
기존 스토리보드를 수정해주세요. 사용자가 요청한 수정 사항을 **무조건적으로 반영**하되, **수정사항과 관련 없는 씬들은 그대로 유지**하고, **수정사항을 반영해야 하는 씬들만 새로 생성**하세요.

[현재 스토리보드 정보]
- 제목: ${plan['vlog_title'] ?? '브이로그'}
- 목표 길이: ${plan['goal_duration_min'] ?? 10}분
- 총 씬 수: ${scenes.length}개
- 모든 씬 목록:
${allScenesInfo}
${userInputSummary.isNotEmpty ? '\n- 원본 사용자 입력: ${userInputSummary.join(', ')}' : ''}

[사용자 수정 요청]
${modificationRequest}

**[절대 중요] 씬 유지/재생성 규칙:**
1. **수정사항과 관련 없는 씬들은 반드시 그대로 유지**해야 합니다. JSON 응답에서 기존 씬 데이터를 그대로 반환하세요.
2. **수정사항과 관련 있는 씬들만 새로 생성**하세요. 새로 생성된 씬은 수정 요청을 반영한 내용이어야 합니다.
3. 씬이 수정사항과 관련 있는지 판단하는 기준:
   - 수정 요청의 내용(장소, 시간, 내용, 톤 등)이 해당 씬의 제목, 장소, 요약, 체크리스트 등과 직접적으로 관련이 있는 경우
   - 수정 요청이 전체 스토리보드의 흐름을 바꾸는 경우, 관련된 모든 씬
   - 수정 요청이 특정 씬을 명시적으로 언급한 경우, 해당 씬 및 관련 씬
4. **유지할 씬의 경우**: 기존 씬의 모든 필드를 그대로 반환하세요 (storyboard_image_url, reference_video_url 등 포함).
5. **새로 생성할 씬의 경우**: 수정 요청을 반영하여 완전히 새로운 씬 데이터를 생성하세요.
6. 씬 순서는 기존 순서를 유지하되, 새로 생성된 씬은 기존 씬과 일관성 있게 배치하세요.

다음 형식의 JSON 객체를 반환해주세요 (코드 펜스 없이 순수 JSON만):

{
  "summary": "전체 스토리보드의 요약입니다. 브이로그의 전체적인 흐름과 내용을 상세하게 설명합니다.\n\n총 2문단으로 작성하고, 각 문단은 2문장으로 구성하세요. 문단과 문단 사이에는 빈 줄 하나를 넣어 가독성을 높이세요. 브이로그의 시작부터 끝까지의 전체적인 흐름, 주요 장면들, 분위기와 톤을 구체적으로 포함하여 작성하세요.",
  "vlog_title": "매력적인 브이로그 제목",
  "keywords": ["키워드1", "키워드2", "키워드3"],
  "goal_duration_min": 8,
  "equipment": "스마트폰",
  "total_people": 3,
  "buffer_rate": 0.12,
  "user_notes": "촬영 시 주의사항이나 특별한 메모",
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
      "emotional_expression": "• '메인 게이트 입장' 씬에서 친구들과의 기대감 넘치는 대화 포착\n• '롤러코스터 탑승' 씬에서 스릴 넘치는 표정과 환호성\n• '저녁 식사' 씬에서 하루를 돌아보며 나누는 솔직한 감정 공유",
      "movement": "• '입장 게이트' 씬의 워킹샷으로 자연스러운 이동감 표현\n• '놀이기구 탑승' 씬의 핸드헬드 촬영으로 역동적인 카메라 워크\n• '공원 산책' 씬의 팬/틸트를 활용한 환경 포착",
      "intensity": "• '롤러코스터' 씬의 빠른 컷과 클로즈업으로 긴장감 극대화\n• '퍼레이드 관람' 씬의 와이드샷으로 웅장한 분위기 연출\n• '저녁 모닥불' 씬의 따뜻한 조명과 차분한 리듬으로 대비",
      "location_diversity": "• 메인 게이트, 롤러코스터 존, 푸드코트, 포토존, 분수대 등 5개 이상의 다양한 공간 활용\n• 실내(푸드코트)와 실외(놀이기구 존) 장소를 적절히 배치\n• 각 장소마다 고유한 배경과 분위기 제공",
      "speed_rhythm": "• 오프닝과 놀이기구 씬의 빠른 편집으로 흥미 유발\n• 점심 식사와 휴식 씬의 여유로운 템포로 완급 조절\n• 클로징 씬의 감성적인 슬로우모션으로 여운 남김",
      "excitement_surprise": "• '롤러코스터 탑승' 씬의 예상치 못한 스릴과 반응\n• '캐릭터 만남' 씬의 깜짝 이벤트와 놀라움\n• '저녁 불꽃놀이' 씬의 감동적인 피날레"
    }
  },
  "shooting_route": {
    "locations": [
      {
        "name": "메인 게이트",
        "description": "입구에서 오프닝 촬영",
        "latitude": 36.8109,
        "longitude": 127.1498,
        "order": 1,
        "scene_ids": ["scene_1", "scene_2"]
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
      "summary": ["씬에 대한 간단한 설명입니다. 한 두 문장 정도로 씬의 내용과 목적을 상세하게 설명하세요.", "씬의 핵심 내용이나 주요 액션을 포함하여 작성하세요."],
      "steps": ["스텝 1", "스텝 2", "스텝 3"],
      "checklist": ["와이드 샷으로 전체 장면 포착", "주인공 클로즈업으로 표정 촬영", "주변 환경/분위기 촬영", "반응샷 또는 인터랙션 촬영"],
      "fallback": "대안 방법",
      "start_hint": "시작 힌트",
      "stop_hint": "정지 힌트",
      "completion_criteria": "완료 기준",
      "tone": "밝고 경쾌",
      "style_vibe": "MZ",
      "target_audience": "20대 친구",
      "script": "",
      "shot_composition": ["와이드 샷으로 전체 장면 포착", "클로즈업으로 표정 강조"],
      "shooting_instructions": ["카메라를 안정적으로 고정", "자연광 활용", "흔들림 최소화"],
      "location": "메인 게이트 앞",
      "cost": 0,
      "people_count": 3,
      "shooting_time_min": 5,
      "storyboard_image_url": "",
      "reference_video_url": "",
      "reference_video_timestamp": 0,
      "pro": {
        "framing": ["프레이밍 팁"],
        "audio": ["오디오 팁"],
        "dialogue": ["대화 예시 1", "대화 예시 2"],
        "edit_hint": ["편집 힌트"],
        "safety": ["안전 주의사항"],
        "broll": ["B-roll 제안"]
      },
      "alternative_scene_id": "alt_1"
    }
  ],
  "alternative_scenes": [
    {
      "id": "alt_1",
      "title": "친구들과 함께하는 저녁 식사",
      "allocated_sec": 30,
      "trigger": "entrance",
      "summary": ["대체 씬 1의 설명입니다. 원본 씬과 다른 관점이나 접근 방식을 제시하세요."],
      "steps": ["대체 스텝 1", "대체 스텝 2"],
      "checklist": ["와이드 샷으로 전체 장면 포착", "주인공 클로즈업으로 표정 촬영", "주변 환경/분위기 촬영"],
      "fallback": "대안 방법",
      "start_hint": "시작 힌트",
      "stop_hint": "정지 힌트",
      "completion_criteria": "완료 기준",
      "tone": "밝고 경쾌",
      "style_vibe": "MZ",
      "target_audience": "20대 친구",
      "script": "",
      "shot_composition": ["대체 구도 1", "대체 구도 2"],
      "shooting_instructions": ["대체 촬영 지시사항 1"],
      "location": "메인 게이트 앞",
      "cost": 0,
      "people_count": 3,
      "shooting_time_min": 5,
      "storyboard_image_url": "",
      "reference_video_url": "",
      "reference_video_timestamp": 0
    }
  ]
}

**[절대 중요] 위치 규칙 (이 규칙을 위반하면 스토리보드가 무효화됩니다):**
- 필수 촬영 장소(required_location)가 명시된 경우, **모든 씬(1번째부터 마지막 씬까지 100%)의 location과 GPS 좌표는 반드시 필수 촬영 장소와 같은 지역이어야 합니다.**
- 필수 촬영 장소의 GPS 좌표를 기준으로, **모든 씬의 GPS 좌표는 반경 10km 이내에 있어야 합니다.**
- **절대로 덕수궁, 경복궁, 서울시청, 부산, 인천 등 다른 지역의 좌표를 사용하지 마세요.**

**[중요] 수정 요청 반영 규칙:**
1. 사용자가 요청한 수정 사항을 **무조건적으로 반영**해야 합니다.
2. 수정 사항과 관련된 모든 씬, 장소, 내용을 일관성 있게 업데이트하세요.
3. 수정 사항이 전체 스토리보드의 흐름에 영향을 주는 경우, 관련된 모든 부분을 조정하세요.
4. 기존 스토리보드의 구조와 형식은 유지하되, 수정 요청에 맞게 내용을 변경하세요.

중요 요구사항:
1. summary는 전체 브이로그 스토리보드의 흐름과 내용을 상세하게 요약 (2문단, 각 문단 2문장). 수정 요청을 반영하여 업데이트하세요.
2. vlog_title은 수정 요청을 반영한 매력적인 제목
3. keywords는 정확히 3개
4. **chapters는 기존 씬 수와 동일하게 유지**하세요. 씬이 추가되거나 삭제되는 경우에만 변경하세요.
5. **scenes 배열에는 기존 씬 수와 동일한 개수가 포함되어야 합니다**:
   - 유지할 씬: 기존 씬 데이터를 그대로 반환 (모든 필드 포함)
   - 새로 생성할 씬: 수정 요청을 반영한 새로운 씬 데이터 생성
6. 모든 씬에 location, cost, people_count, shooting_time_min 필드 포함
7. **유지할 씬의 storyboard_image_url, reference_video_url 등 기존 필드도 그대로 유지**하세요.
8. 모든 텍스트는 한국어로 작성
9. 순수 JSON만 반환 (코드 펜스나 설명 없이)
''';
  }
}
