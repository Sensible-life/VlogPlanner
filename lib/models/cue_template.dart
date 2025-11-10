class CueTemplate {
  final String sceneType;
  final String when;
  final List<int> lenSec;
  final List<String> camera;
  final List<String> action;
  final List<String> audio;
  final List<String> checklist;
  final String fallback;
  final List<String> placeholders;
  final String styleTone;
  final String styleVibe;

  CueTemplate({
    required this.sceneType,
    required this.when,
    required this.lenSec,
    required this.camera,
    required this.action,
    required this.audio,
    required this.checklist,
    required this.fallback,
    required this.placeholders,
    required this.styleTone,
    required this.styleVibe,
  });

  factory CueTemplate.fromJson(Map<String, dynamic> json) {
    return CueTemplate(
      sceneType: json['scene_type'] as String? ?? '',
      when: json['when'] as String? ?? '',
      lenSec: (json['len_sec'] as List<dynamic>?)
              ?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
              .toList() ??
          [0, 0],
      camera: (json['camera'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      action: (json['action'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      audio: (json['audio'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      checklist: (json['checklist'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      fallback: json['fallback'] as String? ?? '',
      placeholders: (json['placeholders'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      styleTone: json['style_tone'] as String? ?? '',
      styleVibe: json['style_vibe'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scene_type': sceneType,
      'when': when,
      'len_sec': lenSec,
      'camera': camera,
      'action': action,
      'audio': audio,
      'checklist': checklist,
      'fallback': fallback,
      'placeholders': placeholders,
      'style_tone': styleTone,
      'style_vibe': styleVibe,
    };
  }
}

