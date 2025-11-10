#!/usr/bin/env python3
"""
통합 대본 생성 스크립트
scene_contexts.json, extracted_template.json, merged_text_content.json을 이용하여
대본을 생성하고, 10개 세그먼트씩 묶어서 장면으로 만듭니다.
"""

import json
import os
from pathlib import Path
from typing import Dict, List, Any, Union, Optional

def load_json_file(file_path: Path) -> Optional[Dict]:
    """JSON 파일 로드"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"⚠️  파일을 찾을 수 없습니다: {file_path}")
        return None
    except json.JSONDecodeError as e:
        print(f"⚠️  JSON 파싱 오류: {file_path} - {e}")
        return None

def parse_timestamp(timestamp_str: str) -> float:
    """타임스탬프 문자열을 초 단위로 변환"""
    try:
        if timestamp_str.startswith('['):
            timestamp_str = timestamp_str[1:-1]  # [00:01:23] -> 00:01:23
        
        parts = timestamp_str.split(':')
        if len(parts) == 3:
            hours, minutes, seconds = map(float, parts)
            return hours * 3600 + minutes * 60 + seconds
        elif len(parts) == 2:
            minutes, seconds = map(float, parts)
            return minutes * 60 + seconds
        else:
            return float(parts[0])
    except:
        return 0.0

def find_closest_scene(timestamp: float, scene_contexts: List[Dict]) -> Optional[Dict]:
    """주어진 타임스탬프에 가장 가까운 장면을 찾습니다"""
    if not scene_contexts:
        return None
    
    closest_scene = None
    min_diff = float('inf')
    
    for scene in scene_contexts:
        scene_timestamp = scene.get('timestamp', 0)
        diff = abs(timestamp - scene_timestamp)
        
        if diff < min_diff:
            min_diff = diff
            closest_scene = scene
    
    return closest_scene if min_diff < 5.0 else None  # 5초 이내의 장면만 매칭

def merge_segments(segments: List[Dict], scene_info_segments: List[Dict], chunk_size: int = 10) -> List[Dict]:
    """세그먼트를 chunk_size개씩 묶어서 하나의 장면으로 만듭니다"""
    merged_scenes = []
    
    # dialogue 타입의 세그먼트만 필터링
    dialogue_segments = [s for s in segments if s.get('type') == 'dialogue']
    
    for i in range(0, len(dialogue_segments), chunk_size):
        chunk = dialogue_segments[i:i + chunk_size]
        
        if not chunk:
            continue
        
        # 장면 정보 생성
        first_segment = chunk[0]
        last_segment = chunk[-1]
        
        # 해당 시간대의 scene_info 찾기
        first_timestamp = first_segment.get('timestamp_seconds', 0)
        scene_info = None
        for s in scene_info_segments:
            if abs(s.get('timestamp_seconds', 0) - first_timestamp) < 5.0:
                scene_info = s
                break
        
        # 텍스트 합치기
        combined_text = ' '.join([s.get('text', '') for s in chunk if s.get('text')])
        
        # 소스 타입 추출
        sources = [s.get('source', '') for s in chunk]
        unique_sources = list(set(sources))
        
        # 장면 생성
        scene = {
            "scene_id": i // chunk_size + 1,
            "start_timestamp": first_segment.get('timestamp', ''),
            "end_timestamp": last_segment.get('timestamp', ''),
            "start_seconds": first_segment.get('timestamp_seconds', 0),
            "end_seconds": last_segment.get('timestamp_seconds', 0),
            "duration_seconds": last_segment.get('timestamp_seconds', 0) - first_segment.get('timestamp_seconds', 0),
            "dialogue_count": len(chunk),
            "content": combined_text,
            "has_voice": 'VOICE' in unique_sources or 'BOTH' in unique_sources,
            "has_screen": 'SCREEN' in unique_sources or 'BOTH' in unique_sources,
        }
        
        # 장면 정보 추가 (있으면)
        if scene_info:
            scene.update({
                "activity": scene_info.get('activity', ''),
                "location": scene_info.get('location', ''),
                "mood": scene_info.get('mood', ''),
                "scene_type": scene_info.get('scene_type', '')
            })
        
        merged_scenes.append(scene)
    
    return merged_scenes

def generate_merged_script(template_folder: Path, template_name: str) -> Optional[Dict]:
    """병합된 대본 생성"""
    print(f"\n📝 {template_name} 대본 생성 중...")
    
    # 필요한 파일 경로
    scene_contexts_path = template_folder / "scene_contexts.json"
    extracted_template_path = template_folder / "extracted_template.json"
    merged_text_path = template_folder / "merged_text_content.json"
    
    # 파일 존재 확인 및 로드
    scene_contexts_data = load_json_file(scene_contexts_path)
    extracted_template_data = load_json_file(extracted_template_path)
    merged_text_data = load_json_file(merged_text_path)
    
    if not all([scene_contexts_data, extracted_template_data, merged_text_data]):
        print(f"❌ {template_name}에 필요한 파일이 없습니다.")
        return None
    
    # merged_text_content의 세그먼트 가져오기
    merged_segments = merged_text_data.get('merged_segments', [])
    scenes = scene_contexts_data.get('scenes', [])
    
    # 대본 세그먼트 생성
    script_segments = []
    current_scene_info = None
    
    for segment in merged_segments:
        timestamp_str = segment.get('timestamp', '[00:00:00]')
        source = segment.get('source', 'UNKNOWN')
        text = segment.get('text', '')
        
        # 타임스탬프 파싱
        timestamp_seconds = parse_timestamp(timestamp_str)
        
        # 가장 가까운 장면 정보 찾기
        scene_info = find_closest_scene(timestamp_seconds, scenes)
        
        # 장면이 바뀌었으면 새로운 정보 추가
        if scene_info and scene_info != current_scene_info:
            current_scene_info = scene_info
            
            script_segments.append({
                "type": "scene_info",
                "timestamp": timestamp_str,
                "timestamp_seconds": timestamp_seconds,
                "activity": scene_info.get('activity', ''),
                "location": scene_info.get('location', ''),
                "mood": scene_info.get('mood', ''),
                "scene_type": scene_info.get('scene_type', '')
            })
        
        # 텍스트 추가
        script_segments.append({
            "type": "dialogue",
            "timestamp": timestamp_str,
            "timestamp_seconds": timestamp_seconds,
            "source": source,
            "text": text,
            "activity": current_scene_info.get('activity', '') if current_scene_info else '',
            "location": current_scene_info.get('location', '') if current_scene_info else '',
            "mood": current_scene_info.get('mood', '') if current_scene_info else ''
        })
    
    # 세그먼트를 10개씩 묶어서 장면으로 병합
    scene_info_segments = [s for s in script_segments if s.get('type') == 'scene_info']
    dialogue_segments = [s for s in script_segments if s.get('type') == 'dialogue']
    
    merged_scenes = merge_segments(dialogue_segments, scene_info_segments, chunk_size=10)
    
    print(f"   원본 세그먼트: {len(dialogue_segments)}개")
    print(f"   병합된 장면: {len(merged_scenes)}개")
    
    # 최종 대본 구조
    script = {
        "template_name": extracted_template_data.get('template_name', template_name),
        "category": extracted_template_data.get('category', ''),
        "metadata": {
            "total_segments": len(merged_scenes),
            "voice_segments": len([s for s in dialogue_segments if s.get('source') == 'VOICE' or s.get('source') == 'BOTH']),
            "screen_segments": len([s for s in dialogue_segments if s.get('source') == 'SCREEN' or s.get('source') == 'BOTH']),
            "scene_count": scene_contexts_data.get('total_scenes', 0),
            "original_segments": len(dialogue_segments)
        },
        "template_info": {
            "visual_signature": extracted_template_data.get('visual_signature', {}),
            "audio_signature": extracted_template_data.get('audio_signature', {}),
            "emotion_tone": extracted_template_data.get('emotion_tone', {})
        },
        "scenes": merged_scenes
    }
    
    return script

def save_script(script: Dict, output_path: Path):
    """대본 저장"""
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(script, f, ensure_ascii=False, indent=2)
    print(f"   ✅ 저장 완료: {output_path}")

def main():
    """메인 실행 함수"""
    # 템플릿 디렉토리
    templates_dir = Path("assets/templates")
    
    if not templates_dir.exists():
        print(f"❌ 템플릿 디렉토리를 찾을 수 없습니다: {templates_dir}")
        return
    
    # 모든 템플릿 폴더 찾기
    template_folders = [d for d in templates_dir.iterdir() if d.is_dir()]
    
    print(f"📁 총 {len(template_folders)}개의 템플릿 폴더를 찾았습니다.")
    
    success_count = 0
    fail_count = 0
    
    for template_folder in sorted(template_folders):
        template_name = template_folder.name
        
        # 대본 생성
        script = generate_merged_script(template_folder, template_name)
        
        if script:
            # script.json 저장
            script_path = template_folder / "script.json"
            save_script(script, script_path)
            success_count += 1
        else:
            print(f"❌ {template_name} 대본 생성 실패")
            fail_count += 1
    
    print(f"\n{'='*60}")
    print(f"✅ 성공: {success_count}개")
    print(f"❌ 실패: {fail_count}개")
    print(f"{'='*60}")

if __name__ == "__main__":
    main()

