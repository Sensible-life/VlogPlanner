import 'take.dart';

/// 촬영 세션 (하나의 씬 촬영 정보)
class ShootingSession {
  final String sceneId;
  final String sceneName;
  final DateTime startTime;
  final DateTime? endTime;
  final List<Take> takes;
  final SceneStatus status;
  final Map<String, bool> checklist; // 체크리스트 항목별 완료 여부
  final String? weatherCondition;
  final String? locationNote;
  final int? targetTakeCount; // 목표 테이크 횟수
  final int? requiredCircleTakes; // 필요한 OK 컷 개수

  ShootingSession({
    required this.sceneId,
    required this.sceneName,
    required this.startTime,
    this.endTime,
    required this.takes,
    this.status = SceneStatus.notStarted,
    required this.checklist,
    this.weatherCondition,
    this.locationNote,
    this.targetTakeCount,
    this.requiredCircleTakes,
  });

  /// 총 촬영 시간 (분)
  int get totalDurationMinutes {
    if (endTime == null) {
      return DateTime.now().difference(startTime).inMinutes;
    }
    return endTime!.difference(startTime).inMinutes;
  }

  /// OK 컷 개수
  int get circleTakeCount {
    return takes.where((t) => t.isCircleTake).length;
  }

  /// 전체 테이크 개수
  int get totalTakeCount {
    return takes.length;
  }

  /// 체크리스트 완료율 (%)
  double get checklistProgress {
    if (checklist.isEmpty) return 100.0;
    final completed = checklist.values.where((v) => v).length;
    return (completed / checklist.length) * 100;
  }

  /// 촬영 완료 조건 충족 여부
  bool get isReadyToComplete {
    // 체크리스트 100% 완료
    if (checklistProgress < 100) return false;

    // 최소 OK 컷 개수 충족
    if (requiredCircleTakes != null && circleTakeCount < requiredCircleTakes!) {
      return false;
    }

    // 최소 1개 이상의 테이크 필요
    if (totalTakeCount == 0) return false;

    return true;
  }

  factory ShootingSession.fromJson(Map<String, dynamic> json) {
    return ShootingSession(
      sceneId: json['scene_id'] as String,
      sceneName: json['scene_name'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      takes: (json['takes'] as List<dynamic>?)
              ?.map((e) => Take.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: SceneStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => SceneStatus.notStarted,
      ),
      checklist: Map<String, bool>.from(json['checklist'] as Map? ?? {}),
      weatherCondition: json['weather_condition'] as String?,
      locationNote: json['location_note'] as String?,
      targetTakeCount: json['target_take_count'] as int?,
      requiredCircleTakes: json['required_circle_takes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scene_id': sceneId,
      'scene_name': sceneName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'takes': takes.map((t) => t.toJson()).toList(),
      'status': status.toString(),
      'checklist': checklist,
      'weather_condition': weatherCondition,
      'location_note': locationNote,
      'target_take_count': targetTakeCount,
      'required_circle_takes': requiredCircleTakes,
    };
  }

  ShootingSession copyWith({
    String? sceneId,
    String? sceneName,
    DateTime? startTime,
    DateTime? endTime,
    List<Take>? takes,
    SceneStatus? status,
    Map<String, bool>? checklist,
    String? weatherCondition,
    String? locationNote,
    int? targetTakeCount,
    int? requiredCircleTakes,
  }) {
    return ShootingSession(
      sceneId: sceneId ?? this.sceneId,
      sceneName: sceneName ?? this.sceneName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      takes: takes ?? this.takes,
      status: status ?? this.status,
      checklist: checklist ?? this.checklist,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      locationNote: locationNote ?? this.locationNote,
      targetTakeCount: targetTakeCount ?? this.targetTakeCount,
      requiredCircleTakes: requiredCircleTakes ?? this.requiredCircleTakes,
    );
  }
}

/// 씬 촬영 상태
enum SceneStatus {
  notStarted,  // 미시작
  inProgress,  // 촬영 중
  completed,   // 완료
  skipped,     // 건너뜀
}

/// 씬 상태를 한글로 변환
extension SceneStatusExtension on SceneStatus {
  String get displayName {
    switch (this) {
      case SceneStatus.notStarted:
        return '미시작';
      case SceneStatus.inProgress:
        return '촬영 중';
      case SceneStatus.completed:
        return '완료';
      case SceneStatus.skipped:
        return '건너뜀';
    }
  }

  String get emoji {
    switch (this) {
      case SceneStatus.notStarted:
        return '⏸️';
      case SceneStatus.inProgress:
        return '▶️';
      case SceneStatus.completed:
        return '✅';
      case SceneStatus.skipped:
        return '⏭️';
    }
  }
}
