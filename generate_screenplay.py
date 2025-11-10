#!/usr/bin/env python3
"""
시나리오 생성 스크립트
script.json의 각 장면을 시니어 시나리오 형식으로 변환합니다.
"""

import json
from pathlib import Path
from typing import Dict, List, Any, Optional
import re

def generate_scene_title(activity: str, scene_type: str) -> str:
    """활동과 장면 유형으로부터 장면 제목 생성"""
    if activity:
        # 활동에서 키워드 추출
        keywords = activity.split(',')[0].split('(')[0].strip()
        if len(keywords) < 50:  # 너무 길면 줄임
            return keywords
    return scene_type if scene_type else "장면"

def parse_time_from_location(location: str) -> str:
    """장소로부터 시간 추론"""
    location_lower = location.lower()
    if 'morning' in location_lower or '아침' in location_lower:
        return "아침"
    elif 'night' in location_lower or '밤' in location_lower or 'evening' in location_lower:
        return "저녁"
    elif 'sunset' in location_lower or '일몰' in location_lower:
        return "황혼"
    elif 'noon' in location_lower or '정오' in location_lower:
        return "정오"
    return "낮"  # 기본값

def extract_visual_elements(activity: str, location: str, scene_type: str) -> str:
    """시각적 요소 생성"""
    elements = []
    
    # 장소 기반 카메라 워크
    if "indoor" in location.lower() or "실내" in location.lower():
        elements.append("실내 환경이 포착된다")
    if "outdoor" in location.lower() or "야외" in location.lower():
        elements.append("야외 풍경이 프레임을 채운다")
    
    # 활동 기반 동작 묘사
    if "walking" in activity.lower() or "걷는" in activity:
        elements.append("카메라가 걷는 인물을 따라간다")
    if "sitting" in activity.lower() or "앉아있는" in activity:
        elements.append("정적이고 편안한 구도")
    if "talking" in activity.lower() or "말하는" in activity:
        elements.append("대화가 오가는 클로즈업")
    if "working" in activity.lower() or "일하는" in activity:
        elements.append("업무에 집중하는 모습을 담는다")
    
    return ". ".join(elements) if elements else "장면이 펼쳐진다."

def format_dialogue(content: str, has_voice: bool, has_screen: bool) -> List[str]:
    """대사를 대본 형식으로 변환"""
    
    # content를 그대로 사용하여 모든 대사 포함
    if not content or len(content) < 2:
        return []
    
    # VOICE와 SCREEN 구분
    source_tag = ""
    if has_voice and has_screen:
        source_tag = "[VOICE]"
    elif has_voice:
        source_tag = "[VOICE]"
    elif has_screen:
        source_tag = "[SCREEN TEXT]"
    else:
        source_tag = "[NARRATOR]"
    
    # content를 줄바꿈으로 구분 (공백이 있으면 공백으로도 구분)
    # 두 칸 이상의 공백으로 분리
    parts = re.split(r'\s{2,}', content)
    
    # 각 부분을 대사로 추가
    dialogues = []
    for part in parts:
        part = part.strip()
        if len(part) > 0:
            # 너무 긴 대사는 줄바꿈 처리
            if len(part) > 100:
                # 100자마다 끊어서 여러 줄로
                words = part.split()
                current_line = []
                current_length = 0
                
                for word in words:
                    if current_length + len(word) + 1 > 100:
                        dialogues.append(f"{source_tag}\n{' '.join(current_line)}")
                        current_line = [word]
                        current_length = len(word)
                    else:
                        current_line.append(word)
                        current_length += len(word) + 1
                
                if current_line:
                    dialogues.append(f"{source_tag}\n{' '.join(current_line)}")
            else:
                dialogues.append(f"{source_tag}\n{part}")
    
    return dialogues

def create_screenplay_scene(scene: Dict, index: int) -> str:
    """단일 장면을 시나리오 형식으로 변환"""
    
    # 기본 정보 추출
    scene_id = scene.get('scene_id', index + 1)
    activity = scene.get('activity', '')
    location = scene.get('location', '')
    mood = scene.get('mood', '')
    scene_type = scene.get('scene_type', '')
    content = scene.get('content', '')
    has_voice = scene.get('has_voice', False)
    has_screen = scene.get('has_screen', False)
    
    # 시나리오 작성
    scene_title = generate_scene_title(activity, scene_type)
    time = parse_time_from_location(location)
    
    lines = []
    lines.append("---")
    lines.append(f"SCENE TITLE: {scene_title}")
    lines.append(f"LOCATION: {location}")
    lines.append(f"TIME: {time}")
    lines.append(f"MOOD: {mood}")
    lines.append("")
    
    # VISUAL DESCRIPTION
    lines.append("[ACTION / VISUAL DESCRIPTION]")
    visual_desc = extract_visual_elements(activity, location, scene_type)
    lines.append(visual_desc + ".")
    if scene_type:
        lines.append(f"장면 유형: {scene_type}")
    lines.append("")
    
    # DIALOGUE
    if content:
        lines.append("[DIALOGUE]")
        dialogues = format_dialogue(content, has_voice, has_screen)
        for dialogue in dialogues:
            lines.append(dialogue)
        lines.append("")
    
    # NARRATION
    lines.append("[NARRATION / VOICE-OVER]")
    if mood:
        lines.append(f"{mood} 분위기가 흐른다.")
    if activity:
        # 활동을 시적으로 표현
        lines.append(f"{activity}")
    lines.append("")
    
    lines.append("---")
    
    return "\n".join(lines)

def convert_script_to_screenplay(script_path: Path) -> Optional[str]:
    """script.json을 읽어서 시나리오 텍스트 생성"""
    
    print(f"\n🎬 {script_path.parent.name} 시나리오 생성 중...")
    
    # JSON 로드
    with open(script_path, 'r', encoding='utf-8') as f:
        script_data = json.load(f)
    
    template_name = script_data.get('template_name', '미제목')
    scenes = script_data.get('scenes', [])
    
    print(f"   장면 수: {len(scenes)}개")
    
    # 전체 시나리오 작성
    screenplay_lines = []
    
    # 헤더
    screenplay_lines.append("=" * 80)
    screenplay_lines.append(f"영화: {template_name}")
    screenplay_lines.append(f"카테고리: {script_data.get('category', '')}")
    screenplay_lines.append(f"총 {len(scenes)}개의 장면")
    screenplay_lines.append("=" * 80)
    screenplay_lines.append("")
    
    # 각 장면 추가
    for i, scene in enumerate(scenes):
        scene_text = create_screenplay_scene(scene, i)
        screenplay_lines.append(scene_text)
        screenplay_lines.append("")
    
    return "\n".join(screenplay_lines)

def main():
    """메인 실행 함수"""
    templates_dir = Path("assets/templates")
    
    if not templates_dir.exists():
        print(f"❌ 템플릿 디렉토리를 찾을 수 없습니다: {templates_dir}")
        return
    
    # 모든 script.json 파일 찾기
    script_files = list(templates_dir.rglob("script.json"))
    
    print(f"📁 총 {len(script_files)}개의 script.json 파일을 찾았습니다.")
    
    success_count = 0
    
    for script_path in sorted(script_files):
        try:
            # 시나리오 생성
            screenplay = convert_script_to_screenplay(script_path)
            
            if screenplay:
                # screenplay.txt 저장
                output_path = script_path.parent / "screenplay.txt"
                with open(output_path, 'w', encoding='utf-8') as f:
                    f.write(screenplay)
                
                print(f"   ✅ 저장 완료: {output_path}")
                success_count += 1
        except Exception as e:
            print(f"   ❌ 오류 발생: {e}")
    
    print(f"\n{'='*60}")
    print(f"✅ 성공: {success_count}개")
    print(f"{'='*60}")

if __name__ == "__main__":
    main()

