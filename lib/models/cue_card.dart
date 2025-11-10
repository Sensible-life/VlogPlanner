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
  final String script; // 간단한 대본
  final CueCardPro? pro;
  final String rawMarkdown;

  // 새로 추가된 필드
  final String? thumbnailUrl; // 씬별 이미지 URL

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
    this.thumbnailUrl,
  });

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
}

