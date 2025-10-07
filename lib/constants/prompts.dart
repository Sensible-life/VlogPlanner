class Prompts {
  // 템플릿 생성 프롬프트
  static String buildTemplatePrompt(List<String> urls) {
    return '''
You are building generalized shooting cue templates from multiple theme-park vlogs.

INPUT
URLs:
${urls.map((url) => '- $url').join('\n')}

TASK
Analyze the above videos and output ONLY a valid JSON array CueTemplate[] (no prose), 10–15 items.
Each object MUST use these keys (exact spelling) and KOREAN for all string values:

{
  "scene_type": "opening|move|main|food|reaction|rest|ending",
  "when": "POI or 상황 기준 (예: 입구 표지판 보일 때)",
  "len_sec": [min_int, max_int],
  "camera": ["와이드→미드", ...],
  "action": ["행동 한 줄", "대화/내레이션 한 줄"],
  "audio": ["나레이션/대화/현장음 비율 요지", "자막 톤(선택)"],
  "checklist": ["노출 고정", "마이크 확인", "포커스 락"],   // ≤3 items
  "fallback": "혼잡/소음/민망 시 대체 촬영법 1개",
  "placeholders": ["{동행자}", "{날씨}", "{장소}"],
  "style_tone": "밝고 경쾌 / 차분 등",
  "style_vibe": "MZ / 시네마틱 / 캐주얼 등"
}

CONSTRAINTS
- Keep sentences SHORT (each ≤ 15 Korean characters when possible).
- Separate STYLE (tone/vibe) from CONTENT (camera/action/audio/checklist).
- Favor common patterns across videos; downweight one-off quirks.
- Include at least one template per: opening, main(≥2), food or reaction, and ending.
- NO commentary, NO code fences—JSON array only.
''';
  }

  // 템플릿 정리 프롬프트
  static String buildCleaningPrompt(String templateResponse) {
    return '''
You are cleaning a set of CueTemplates.

INPUT
Paste the current CueTemplate[] JSON here.

TASK
- Merge near-duplicates (same scene_type & similar "when" phrasing).
- Keep 10–12 templates total.
- For merged items, intersect len_sec ranges; keep the tighter, realistic range.
- Ensure checklists have ≤3 items; shorten overly long Korean phrases (≤15 chars).
- Maintain KOREAN values; keys unchanged.

OUTPUT
Return ONLY the cleaned CueTemplate[] as valid JSON (no prose, no code fences).

$templateResponse
''';
  }

  // 계획 생성 프롬프트
  static String buildPlanPrompt(Map<String, String> userInput) {
    return '''
You are a plan compiler for a novice vlogger at a theme park.

CONTEXT
- Goal runtime: ${userInput['target_duration'] ?? '8'} minutes (final edit)
- User: ${userInput['difficulty'] ?? 'novice'}, ${userInput['visit_context'] ?? 'friends'}, ${userInput['time_weather'] ?? 'daytime'}, ${userInput['equipment'] ?? 'smartphone'}
- POI minimal set: ["entrance","queue","main_ride","snack","photo_spot","exit"]
- Style layer comes from CueTemplate[] (separate from content)
- Fallback scenes must be included for recovery

TASK
Create a Plan JSON object that distributes the total time into 8–12 scenes (chapters). 
Follow these rules:
- Must include opening and ending.
- Include at least one alternative (fallback) scene overall (prefer ≥1 for main scenes).
- Per-scene guardrails: 8–120 seconds.
- Add buffer_rate between 0.10 and 0.15 (to absorb delays).
- Prefer mapping scenes to the POIs above; allow 1–2 non-POI scenes (e.g., rest).
- Use concise, implementation-ready IDs.

OUTPUT
Return ONLY a valid JSON object with this exact shape:

{
  "goal_duration_min": 8,
  "buffer_rate": 0.1,
  "chapters": [
    {"id":"opening_gate","alloc_sec":30,"alternatives":[]},
    {"id":"move_in","alloc_sec":30,"alternatives":["move_cutaway"]},
    {"id":"main_A_queue","alloc_sec":25,"alternatives":["map_board_reaction"]},
    {"id":"main_A_ride_pov","alloc_sec":85,"alternatives":["main_A_vo"]},
    {"id":"reaction_post_ride","alloc_sec":20,"alternatives":["reaction_text_overlay"]},
    {"id":"food_snack","alloc_sec":40,"alternatives":["food_insert_only"]},
    {"id":"move_montage","alloc_sec":25,"alternatives":["long_take_walkthrough"]},
    {"id":"main_B_game_booth","alloc_sec":110,"alternatives":["main_B_light"]},
    {"id":"photo_spot_group","alloc_sec":35,"alternatives":["alt_background"]},
    {"id":"rest_bench","alloc_sec":35,"alternatives":["standing_rest"]},
    {"id":"ending_exit","alloc_sec":30,"alternatives":["sign_static_vo"]}
  ]
}

CONSTRAINTS
- The above JSON is an EXAMPLE OF SHAPE ONLY. Recompute alloc_sec to fit the ${userInput['target_duration'] ?? '8'}-minute goal with ±15% tolerance.
- Keep scene IDs concise and aligned with POIs or activities.
- Do NOT include any prose, comments, or code fences. JSON only.
''';
  }

  // 큐카드 생성 프롬프트
  static String buildCueCardPrompt(String templatesJson, String planJson) {
    return '''
You are a renderer that converts CueCard[] JSON into on-site shooting cards for novice vloggers, and you MUST include a "더보기(Pro)" section for EVERY card by synthesizing concise best-practice tips from the card context.

INPUT (JSON array named CUECARDS):
Templates: $templatesJson
Plan: $planJson

GOAL
Render ALL cue cards from the Plan chapters as compact MARKDOWN for 5-second readability, PLUS a mandatory "더보기(Pro)" block with expert tips even if the source has no `pro` object.

IMPORTANT: Generate ONE cue card for EACH chapter in the Plan. The Plan contains ${planJson.contains('chapters') ? 'multiple' : 'several'} chapters, so you must generate the SAME NUMBER of cue cards.

CONTENT LANGUAGE
- All user-facing text is KOREAN. Keep keys/labels exactly as specified in the OUTPUT FORMAT.
- Keep phrases concise, imperative, jargon-free. Target ≤14 Korean characters per bullet when possible; trim while preserving meaning.

STRICT RULES
- Output MARKDOWN ONLY. No prose before/after. No code fences.
- For each card:
  - Title = use summary[0] if short; else id.
  - Always produce: 2-line summary, 3 steps, 3 checklist items, 1 fallback, trigger badge, allocated seconds, start/stop hints, completion criteria, style line.
  - steps = exactly 3; checklist = exactly 3. If source differs, compress or minimally synthesize to reach 3.
  - fallback = 1 short line (혼잡/소음/촬영금지/민망 대응 중 하나).
  - allocated_sec: show with a timer emoji.
  - trigger: show POI value as a badge.
  - completion_criteria: join with " · ".
  - Style line: tone / style_vibe / target_audience.

MANDATORY "Pro" SYNTHESIS (even if missing in source)
- Always include a "더보기(Pro)" block.
- Synthesize short, device-agnostic, smartphone-novice tips using ONLY the card's own context (summary, steps, checklist, fallback, trigger, allocated_sec, tone, style_vibe).
- DO NOT invent brand names, model-specific settings, or illegal/unsafe behaviors.
- Prefer conservative best practices suitable for theme-park, daytime, handheld shooting.
- Tailor tips to trigger & scene intent:
  - entrance / photo_spot → 프레이밍·포즈·배경 정리
  - queue / rest_area → 소음·프라이버시·동선
  - main_ride / ride_exit → 안전·고정·대체(촬영금지 시 VO/컷어웨이)
  - snack → 화이트밸런스·인서트·한입 리액션
- Generate ALL of these Pro sub-sections (short, actionable):
  - 촬영(Pro): 프레이밍, 무브먼트, 노출/포커스
  - 오디오(Pro): 마이크 거리/레벨, 바람/소음 대응
  - 대화/나레이션: scene에 맞는 한줄 프롬프트 3개
  - 편집 힌트: 컷 포인트, 인서트, 리듬/전환 1줄
  - 안전/권한: 혼잡/촬영금지/보행 방해 회피 1줄
  - B-roll 제안: 2–3컷 (아이콘 없이 짧은 라벨)
- Keep each bullet ≤14 Korean chars when feasible (e.g., "AE/AF 고정", "손떨림 최소").

OUTPUT FORMAT (repeat for EACH card, exactly this structure):

## {Title}
> ⏱ {allocated_sec}s | 🏷 {trigger}

**요약**
- {summary[0]}
- {summary[1]}

**스텝 (3)**
1) {steps[0]}
2) {steps[1]}
3) {steps[2]}

**체크 (3)**
- {checklist[0]}
- {checklist[1]}
- {checklist[2]}

**대안**
- {fallback}

**힌트**
- ▶ 시작: {start_hint}
- ⏹ 정지: {stop_hint}
- 🎯 완료: {completion_criteria}

**스타일**
- 톤: {tone} / 바이브: {style_vibe} / 타깃: {target_audience}

<details><summary>더보기 (Pro)</summary>

**촬영(Pro)**
- 프레이밍: 상1/3 구도
- 무브먼트: 워킹 최소
- 노출/포커스: AE/AF 고정

**오디오(Pro)**
- 입 30~40cm

**대화/나레이션**
- "드디어 도착했어요!"
- "오늘 날씨 완전 좋네요"
- "기대돼요!"

**편집 힌트**
- 인서트→점프컷

**안전/권한**
- 통행 방해 금지

**B-roll 제안**
- 표지판 클로즈업
- 하늘 촬영
- 발걸음
</details>
''';
  }

  // 큐카드 생성 프롬프트 (분할용)
  static String buildCueCardPromptBatch(String templatesJson, List<Map<String, dynamic>> chapters, int batchNumber, int totalBatches) {
    final chaptersJson = chapters.map((chapter) => chapter.toString()).join(',');
    
    return '''
You are a renderer that converts CueCard[] JSON into on-site shooting cards for novice vloggers, and you MUST include a "더보기(Pro)" section for EVERY card by synthesizing concise best-practice tips from the card context.

INPUT (JSON array named CUECARDS):
Templates: $templatesJson
Plan Chapters (Batch $batchNumber of $totalBatches): [$chaptersJson]

GOAL
Render ALL cue cards from the provided Plan chapters as compact MARKDOWN for 5-second readability, PLUS a mandatory "더보기(Pro)" block with expert tips even if the source has no `pro` object.

IMPORTANT: Generate ONE cue card for EACH chapter provided. This is batch $batchNumber of $totalBatches.

CONTENT LANGUAGE
- All user-facing text is KOREAN. Keep keys/labels exactly as specified in the OUTPUT FORMAT.
- Keep phrases concise, imperative, jargon-free. Target ≤14 Korean characters per bullet when possible; trim while preserving meaning.

STRICT RULES
- Output MARKDOWN ONLY. No prose before/after. No code fences.
- For each card:
  - Title = use summary[0] if short; else id.
  - Always produce: 2-line summary, 3 steps, 3 checklist items, 1 fallback, trigger badge, allocated seconds, start/stop hints, completion criteria, style line.
  - steps = exactly 3; checklist = exactly 3. If source differs, compress or minimally synthesize to reach 3.
  - fallback = 1 short line (혼잡/소음/촬영금지/민망 대응 중 하나).
  - allocated_sec: show with a timer emoji.
  - trigger: show POI value as a badge.
  - completion_criteria: join with " · ".
  - Style line: tone / style_vibe / target_audience.

MANDATORY "Pro" SYNTHESIS (even if missing in source)
- Always include a "더보기(Pro)" block.
- Synthesize short, device-agnostic, smartphone-novice tips using ONLY the card's own context (summary, steps, checklist, fallback, trigger, allocated_sec, tone, style_vibe).
- DO NOT invent brand names, model-specific settings, or illegal/unsafe behaviors.
- Prefer conservative best practices suitable for theme-park, daytime, handheld shooting.
- Tailor tips to trigger & scene intent:
  - entrance / photo_spot → 프레이밍·포즈·배경 정리
  - queue / rest_area → 소음·프라이버시·동선
  - main_ride / ride_exit → 안전·고정·대체(촬영금지 시 VO/컷어웨이)
  - snack → 화이트밸런스·인서트·한입 리액션
- Generate ALL of these Pro sub-sections (short, actionable):
  - 촬영(Pro): 프레이밍, 무브먼트, 노출/포커스
  - 오디오(Pro): 마이크 거리/레벨, 바람/소음 대응
  - 대화/나레이션: scene에 맞는 한줄 프롬프트 3개
  - 편집 힌트: 컷 포인트, 인서트, 리듬/전환 1줄
  - 안전/권한: 혼잡/촬영금지/보행 방해 회피 1줄
  - B-roll 제안: 2–3컷 (아이콘 없이 짧은 라벨)
- Keep each bullet ≤14 Korean chars when feasible (e.g., "AE/AF 고정", "손떨림 최소").

OUTPUT FORMAT (repeat for EACH card, exactly this structure):

## {Title}
> ⏱ {allocated_sec}s | 🏷 Trigger: `{trigger.value}`

**요약**
- {summary[0]}
- {summary[1]}

**스텝 (3)**
1) {steps[0]}
2) {steps[1]}
3) {steps[2]}

**체크 (3)**
- {checklist[0]}
- {checklist[1]}
- {checklist[2]}

**대안**
- {fallback}

**힌트**
- ▶ 시작: {start_hint}
- ⏹ 정지: {stop_hint}
- 🎯 완료: {completion_criteria joined by " · "}

**스타일**
- 톤: {tone} / 바이브: {style_vibe} / 타깃: {target_audience}

<details><summary>더보기 (Pro)</summary>

**촬영(Pro)**
- 프레이밍: {synthesized framing tip, e.g., "상1/3 구도"}
- 무브먼트: {synthesized movement tip, e.g., "워킹 최소"}
- 노출/포커스: {synthesized exposure/focus tip, e.g., "AE/AF 고정"}

**오디오(Pro)**
- {synthesized audio tip, e.g., "입 30~40cm"}

**대화/나레이션**
- {prompt 1 tailored to scene}
- {prompt 2 tailored to scene}
- {prompt 3 tailored to scene}

**편집 힌트**
- {synthesized edit tip, e.g., "인서트→점프컷"}

**안전/권한**
- {synthesized safety note, e.g., "통행 방해 금지"}

**B-roll 제안**
- {b-roll 1}
- {b-roll 2}
- {b-roll 3 (optional)}
</details>

QUALITY CHECKS
- Keep all Pro bullets grounded in the card context (trigger/scene intent). No brand names or advanced jargon.
- If unsure, choose conservative defaults: "AE/AF 고정", "수평 유지", "바람 가리기", "표정 1컷", "컷어웨이 1컷".

CRITICAL: You MUST generate the EXACT SAME NUMBER of cue cards as there are chapters provided in this batch. Do not stop after generating just one card. Generate ALL cards for ALL chapters in this batch.
''';
  }
}
