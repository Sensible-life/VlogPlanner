/// 개별 테이크 정보
class Take {
  final String id;
  final int takeNumber;
  final String sceneId;
  final DateTime timestamp;
  final String? filePath;
  final int durationSeconds;
  final TakeQuality quality;
  final String? notes;
  final bool isCircleTake; // OK 컷 여부

  Take({
    required this.id,
    required this.takeNumber,
    required this.sceneId,
    required this.timestamp,
    this.filePath,
    required this.durationSeconds,
    this.quality = TakeQuality.neutral,
    this.notes,
    this.isCircleTake = false,
  });

  factory Take.fromJson(Map<String, dynamic> json) {
    return Take(
      id: json['id'] as String,
      takeNumber: json['take_number'] as int,
      sceneId: json['scene_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      filePath: json['file_path'] as String?,
      durationSeconds: json['duration_seconds'] as int,
      quality: TakeQuality.values.firstWhere(
        (e) => e.toString() == json['quality'],
        orElse: () => TakeQuality.neutral,
      ),
      notes: json['notes'] as String?,
      isCircleTake: json['is_circle_take'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'take_number': takeNumber,
      'scene_id': sceneId,
      'timestamp': timestamp.toIso8601String(),
      'file_path': filePath,
      'duration_seconds': durationSeconds,
      'quality': quality.toString(),
      'notes': notes,
      'is_circle_take': isCircleTake,
    };
  }

  Take copyWith({
    String? id,
    int? takeNumber,
    String? sceneId,
    DateTime? timestamp,
    String? filePath,
    int? durationSeconds,
    TakeQuality? quality,
    String? notes,
    bool? isCircleTake,
  }) {
    return Take(
      id: id ?? this.id,
      takeNumber: takeNumber ?? this.takeNumber,
      sceneId: sceneId ?? this.sceneId,
      timestamp: timestamp ?? this.timestamp,
      filePath: filePath ?? this.filePath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
      isCircleTake: isCircleTake ?? this.isCircleTake,
    );
  }
}

/// 테이크 품질 평가
enum TakeQuality {
  good,    // 좋음
  neutral, // 보통
  bad,     // 나쁨
}

/// 테이크 품질을 한글로 변환
extension TakeQualityExtension on TakeQuality {
  String get displayName {
    switch (this) {
      case TakeQuality.good:
        return '좋음';
      case TakeQuality.neutral:
        return '보통';
      case TakeQuality.bad:
        return '나쁨';
    }
  }

  String get emoji {
    switch (this) {
      case TakeQuality.good:
        return '👍';
      case TakeQuality.neutral:
        return '👌';
      case TakeQuality.bad:
        return '👎';
    }
  }
}
