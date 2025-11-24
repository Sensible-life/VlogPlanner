class CueCard {
  final String title;
  final int allocatedSec;
  final String trigger;
  final List<String> summary;
  final List<String> steps;
  final List<String> checklist;
  final String fallback;
  final String startHint;
  final String stopHint;
  final String completionCriteria;
  final String tone;
  final String styleVibe;
  final String targetAudience;
  final String script; // 간단한 대본 (deprecated - shotComposition, shootingInstructions 사용)
  final CueCardPro? pro;
  final String rawMarkdown;

  // 새로운 촬영 정보 (리뉴얼)
  final List<String> shotComposition; // 구도 정보 (예: "와이드샷으로 전체 풍경", "클로즈업으로 표정 강조")
  final List<String> shootingInstructions; // 촬영 지시사항 (예: "천천히 패닝", "손떨림 주의")
  final String? storyboardImageUrl; // 스토리보드 스타일 이미지 (졸라맨/연필스케치)
  final String? referenceVideoUrl; // YouTube 레퍼런스 영상 URL
  final int? referenceVideoTimestamp; // 레퍼런스 영상의 시작 시점 (초 단위)

  // 씬 세부 정보
  final String location; // 촬영 장소
  final int cost; // 씬별 비용
  final int peopleCount; // 씬별 촬영 인원
  final int shootingTimeMin; // 예상 촬영 시간 (분)

  // 하위 호환성
  final String? thumbnailUrl; // 씬별 이미지 URL (deprecated - storyboardImageUrl 사용)

  // 체크리스트 구도 이미지 (체크리스트 인덱스 -> 이미지 URL)
  final Map<int, String>? compositionImages;

  // 체크리스트 완료 상태 (완료된 항목의 인덱스 집합)
  final Set<int>? checkedChecklistIndices;

  // 대체 씬 ID (전체 스토리보드의 4개 대체 씬 중 하나와 매칭)
  final String? alternativeSceneId;

  CueCard({
    required this.title,
    required this.allocatedSec,
    required this.trigger,
    required this.summary,
    required this.steps,
    required this.checklist,
    required this.fallback,
    required this.startHint,
    required this.stopHint,
    required this.completionCriteria,
    required this.tone,
    required this.styleVibe,
    required this.targetAudience,
    this.script = '',
    this.pro,
    required this.rawMarkdown,
    this.shotComposition = const [],
    this.shootingInstructions = const [],
    this.storyboardImageUrl,
    this.referenceVideoUrl,
    this.referenceVideoTimestamp,
    this.location = '',
    this.cost = 0,
    this.peopleCount = 1,
    this.shootingTimeMin = 30,
    this.thumbnailUrl,
    this.compositionImages,
    this.checkedChecklistIndices,
    this.alternativeSceneId,
  });

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'allocated_sec': allocatedSec,
      'trigger': trigger,
      'summary': summary,
      'steps': steps,
      'checklist': checklist,
      'fallback': fallback,
      'start_hint': startHint,
      'stop_hint': stopHint,
      'completion_criteria': completionCriteria,
      'tone': tone,
      'style_vibe': styleVibe,
      'target_audience': targetAudience,
      'script': script,
      'raw_markdown': rawMarkdown,
      'shot_composition': shotComposition,
      'shooting_instructions': shootingInstructions,
      if (storyboardImageUrl != null) 'storyboard_image_url': storyboardImageUrl,
      if (referenceVideoUrl != null) 'reference_video_url': referenceVideoUrl,
      if (referenceVideoTimestamp != null) 'reference_video_timestamp': referenceVideoTimestamp,
      'location': location,
      'cost': cost,
      'people_count': peopleCount,
      'shooting_time_min': shootingTimeMin,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (compositionImages != null && compositionImages!.isNotEmpty)
        'composition_images': compositionImages!.map((key, value) => MapEntry(key.toString(), value)),
      if (checkedChecklistIndices != null && checkedChecklistIndices!.isNotEmpty)
        'checked_checklist_indices': checkedChecklistIndices!.toList(),
      if (pro != null) 'pro': pro!.toJson(),
      if (alternativeSceneId != null) 'alternative_scene_id': alternativeSceneId,
    };
  }

  // JSON 역직렬화
  factory CueCard.fromJson(Map<String, dynamic> json) {
    // 안전한 String 파싱 헬퍼
    String _safeString(dynamic value, {String defaultValue = ''}) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is List && value.isNotEmpty) return value[0].toString();
      return value.toString();
    }
    
    return CueCard(
      title: _safeString(json['title']),
      allocatedSec: json['allocated_sec'] as int? ?? 0,
      trigger: _safeString(json['trigger']),
      summary: json['summary'] != null
          ? List<String>.from((json['summary'] as List<dynamic>).map((e) => e.toString()))
          : [],
      steps: json['steps'] != null
          ? List<String>.from((json['steps'] as List<dynamic>).map((e) => e.toString()))
          : [],
      checklist: json['checklist'] != null
          ? List<String>.from((json['checklist'] as List<dynamic>).map((e) => e.toString()))
          : [],
      fallback: _safeString(json['fallback']),
      startHint: _safeString(json['start_hint']),
      stopHint: _safeString(json['stop_hint']),
      completionCriteria: _safeString(json['completion_criteria']),
      tone: _safeString(json['tone']),
      styleVibe: _safeString(json['style_vibe']),
      targetAudience: _safeString(json['target_audience']),
      script: _safeString(json['script']),
      rawMarkdown: _safeString(json['raw_markdown']),
      shotComposition: json['shot_composition'] != null
          ? List<String>.from((json['shot_composition'] as List<dynamic>).map((e) => e.toString()))
          : [],
      shootingInstructions: json['shooting_instructions'] != null
          ? List<String>.from((json['shooting_instructions'] as List<dynamic>).map((e) => e.toString()))
          : [],
          storyboardImageUrl: json['storyboard_image_url'] != null ? _safeString(json['storyboard_image_url']) : null,
          referenceVideoUrl: json['reference_video_url'] != null ? _safeString(json['reference_video_url']) : null,
          referenceVideoTimestamp: json['reference_video_timestamp'] as int?,
          location: _safeString(json['location']),
      cost: json['cost'] as int? ?? 0,
      peopleCount: json['people_count'] as int? ?? 1,
      shootingTimeMin: json['shooting_time_min'] as int? ?? 30,
      thumbnailUrl: json['thumbnail_url'] as String?,
      compositionImages: json['composition_images'] != null
          ? (json['composition_images'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(int.parse(key), value.toString()),
            )
          : null,
      checkedChecklistIndices: json['checked_checklist_indices'] != null
          ? Set<int>.from((json['checked_checklist_indices'] as List<dynamic>).map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0))
          : null,
      pro: json['pro'] != null ? CueCardPro.fromJson(json['pro'] as Map<String, dynamic>) : null,
      alternativeSceneId: json['alternative_scene_id'] as String?,
    );
  }

  // 마크다운 텍스트에서 CueCard 파싱
  factory CueCard.fromMarkdown(String markdown) {
    final lines = markdown.split('\n');
    String title = '';
    int allocatedSec = 0;
    String trigger = '';
    List<String> summary = [];
    List<String> steps = [];
    List<String> checklist = [];
    String fallback = '';
    String startHint = '';
    String stopHint = '';
    String completionCriteria = '';
    String tone = '';
    String styleVibe = '';
    String targetAudience = '';
    String script = '';
    CueCardPro? pro;

    String currentSection = '';
    String proSection = '';
    List<String> proFraming = [];
    List<String> proAudio = [];
    List<String> proDialogue = [];
    List<String> proEditHint = [];
    List<String> proSafety = [];
    List<String> proBroll = [];

    for (var line in lines) {
      line = line.trim();
      
      // 제목 파싱
      if (line.startsWith('##') && !line.contains('(Pro)')) {
        title = line.replaceFirst('##', '').trim();
      }
      // 시간과 트리거 파싱
      else if (line.startsWith('>')) {
        final match = RegExp(r'⏱\s*(\d+)s.*🏷\s*(.+)').firstMatch(line);
        if (match != null) {
          allocatedSec = int.tryParse(match.group(1) ?? '0') ?? 0;
          trigger = match.group(2)?.trim() ?? '';
          // Trigger: `value` 형태에서 값만 추출
          if (trigger.contains('`')) {
            trigger = trigger.replaceAll('`', '').replaceAll('Trigger:', '').trim();
          }
        }
      }
      // 섹션 파악
      else if (line.startsWith('**')) {
        currentSection = line.replaceAll('*', '').trim();
        proSection = '';
      }
      // Pro 섹션 파악
      else if (line.contains('**') && line.contains('(Pro)')) {
        proSection = line.replaceAll('*', '').replaceAll('(Pro)', '').trim();
      }
      // 내용 파싱
      else if (line.startsWith('-') && line.length > 1) {
        final content = line.substring(1).trim();
        
        if (proSection.isNotEmpty) {
          // Pro 섹션 내용
          switch (proSection) {
            case '촬영':
              proFraming.add(content);
              break;
            case '오디오':
              proAudio.add(content);
              break;
            case '대화/나레이션':
              proDialogue.add(content);
              break;
            case '편집 힌트':
              proEditHint.add(content);
              break;
            case '안전/권한':
              proSafety.add(content);
              break;
            case 'B-roll 제안':
              proBroll.add(content);
              break;
          }
        } else {
          // 일반 섹션 내용
          switch (currentSection) {
            case '요약':
              summary.add(content);
              break;
            case '체크 (3)':
            case '체크':
              checklist.add(content);
              break;
            case '대안':
              fallback = content;
              break;
            case '힌트':
              if (content.contains('▶ 시작:')) {
                startHint = content.replaceFirst('▶ 시작:', '').trim();
              } else if (content.contains('⏹ 정지:')) {
                stopHint = content.replaceFirst('⏹ 정지:', '').trim();
              } else if (content.contains('🎯 완료:')) {
                completionCriteria = content.replaceFirst('🎯 완료:', '').trim();
              }
              break;
            case '스타일':
              if (content.contains('톤:')) {
                final parts = content.split('/');
                if (parts.isNotEmpty) {
                  tone = parts[0].replaceFirst('톤:', '').trim();
                }
                if (parts.length > 1) {
                  styleVibe = parts[1].replaceFirst('바이브:', '').trim();
                }
                if (parts.length > 2) {
                  targetAudience = parts[2].replaceFirst('타깃:', '').trim();
                }
              }
              break;
            case '대본':
            case 'script':
              script = content;
              break;
          }
        }
      }
      // 스텝 번호로 시작
      else if (RegExp(r'^\d+\)').hasMatch(line)) {
        steps.add(line.replaceFirst(RegExp(r'^\d+\)\s*'), ''));
      }
    }

    // Pro 정보가 있으면 생성
    if (proFraming.isNotEmpty || proAudio.isNotEmpty || proDialogue.isNotEmpty) {
      pro = CueCardPro(
        framing: proFraming,
        audio: proAudio,
        dialogue: proDialogue,
        editHint: proEditHint,
        safety: proSafety,
        broll: proBroll,
      );
    }

    return CueCard(
      title: title,
      allocatedSec: allocatedSec,
      trigger: trigger,
      summary: summary,
      steps: steps,
      checklist: checklist,
      fallback: fallback,
      startHint: startHint,
      stopHint: stopHint,
      completionCriteria: completionCriteria,
      tone: tone,
      styleVibe: styleVibe,
      targetAudience: targetAudience,
      script: script,
      pro: pro,
      rawMarkdown: markdown,
    );
  }

  // 마크다운 텍스트를 여러 개의 CueCard로 분리
  static List<CueCard> parseMultipleFromMarkdown(String markdown) {
    final cards = <CueCard>[];
    final sections = markdown.split(RegExp(r'^##\s+', multiLine: true));
    
    for (var i = 1; i < sections.length; i++) {
      final cardMarkdown = '## ${sections[i]}';
      try {
        cards.add(CueCard.fromMarkdown(cardMarkdown));
      } catch (e) {
        print('큐카드 파싱 오류: $e');
      }
    }
    
    return cards;
  }

  // 체크리스트 완료 상태를 업데이트하는 copyWith 메서드
  CueCard copyWith({
    String? title,
    int? allocatedSec,
    String? trigger,
    List<String>? summary,
    List<String>? steps,
    List<String>? checklist,
    String? fallback,
    String? startHint,
    String? stopHint,
    String? completionCriteria,
    String? tone,
    String? styleVibe,
    String? targetAudience,
    String? script,
    CueCardPro? pro,
    String? rawMarkdown,
    List<String>? shotComposition,
    List<String>? shootingInstructions,
    String? storyboardImageUrl,
    String? referenceVideoUrl,
    int? referenceVideoTimestamp,
    String? location,
    int? cost,
    int? peopleCount,
    int? shootingTimeMin,
    String? thumbnailUrl,
    Map<int, String>? compositionImages,
    Set<int>? checkedChecklistIndices,
    String? alternativeSceneId,
  }) {
    return CueCard(
      title: title ?? this.title,
      allocatedSec: allocatedSec ?? this.allocatedSec,
      trigger: trigger ?? this.trigger,
      summary: summary ?? this.summary,
      steps: steps ?? this.steps,
      checklist: checklist ?? this.checklist,
      fallback: fallback ?? this.fallback,
      startHint: startHint ?? this.startHint,
      stopHint: stopHint ?? this.stopHint,
      completionCriteria: completionCriteria ?? this.completionCriteria,
      tone: tone ?? this.tone,
      styleVibe: styleVibe ?? this.styleVibe,
      targetAudience: targetAudience ?? this.targetAudience,
      script: script ?? this.script,
      pro: pro ?? this.pro,
      rawMarkdown: rawMarkdown ?? this.rawMarkdown,
      shotComposition: shotComposition ?? this.shotComposition,
      shootingInstructions: shootingInstructions ?? this.shootingInstructions,
      storyboardImageUrl: storyboardImageUrl ?? this.storyboardImageUrl,
      referenceVideoUrl: referenceVideoUrl ?? this.referenceVideoUrl,
      referenceVideoTimestamp: referenceVideoTimestamp ?? this.referenceVideoTimestamp,
      location: location ?? this.location,
      cost: cost ?? this.cost,
      peopleCount: peopleCount ?? this.peopleCount,
      shootingTimeMin: shootingTimeMin ?? this.shootingTimeMin,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      compositionImages: compositionImages ?? this.compositionImages,
      checkedChecklistIndices: checkedChecklistIndices ?? this.checkedChecklistIndices,
      alternativeSceneId: alternativeSceneId ?? this.alternativeSceneId,
    );
  }
}

class CueCardPro {
  final List<String> framing;
  final List<String> audio;
  final List<String> dialogue;
  final List<String> editHint;
  final List<String> safety;
  final List<String> broll;

  CueCardPro({
    required this.framing,
    required this.audio,
    required this.dialogue,
    required this.editHint,
    required this.safety,
    required this.broll,
  });

  Map<String, dynamic> toJson() {
    return {
      'framing': framing,
      'audio': audio,
      'dialogue': dialogue,
      'edit_hint': editHint,
      'safety': safety,
      'broll': broll,
    };
  }

  factory CueCardPro.fromJson(Map<String, dynamic> json) {
    return CueCardPro(
      framing: json['framing'] != null
          ? List<String>.from((json['framing'] as List<dynamic>).map((e) => e.toString()))
          : [],
      audio: json['audio'] != null
          ? List<String>.from((json['audio'] as List<dynamic>).map((e) => e.toString()))
          : [],
      dialogue: json['dialogue'] != null
          ? List<String>.from((json['dialogue'] as List<dynamic>).map((e) => e.toString()))
          : [],
      editHint: json['edit_hint'] != null
          ? List<String>.from((json['edit_hint'] as List<dynamic>).map((e) => e.toString()))
          : [],
      safety: json['safety'] != null
          ? List<String>.from((json['safety'] as List<dynamic>).map((e) => e.toString()))
          : [],
      broll: json['broll'] != null
          ? List<String>.from((json['broll'] as List<dynamic>).map((e) => e.toString()))
          : [],
    );
  }
}

