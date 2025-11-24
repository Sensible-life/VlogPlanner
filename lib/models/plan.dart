import 'chapter.dart';
import 'cue_card.dart';

class Plan {
  final String summary; // 전체 스토리보드 요약
  final String vlogTitle; // 브이로그 제목
  final List<String> keywords; // 브이로그 키워드 3개
  final int goalDurationMin; // 시나리오 전체 길이 (분)
  final String equipment; // 촬영 도구
  final int totalPeople; // 전체 촬영 인원
  final double bufferRate;
  final List<Chapter> chapters;
  final StyleAnalysis? styleAnalysis; // 톤앤매너
  final ShootingRoute? shootingRoute; // 촬영 동선 (Google Maps)
  final Budget? budget; // 전체 예산
  final List<CueCard> alternativeScenes; // 전체 스토리보드에 대한 4개의 대체 씬
  final List<String> shootingChecklist; // 촬영 체크리스트
  final String userNotes; // 사용자 메모

  // 기존 필드 (하위 호환성)
  final String? locationImage; // 대표 썸네일 이미지 URL
  final String? equipmentRecommendation; // 장비 추천 (deprecated)
  final Map<String, dynamic>? weatherInfo; // 날씨 정보

  // 계산 필드
  int get sceneCount => chapters.length; // 챕터 수를 씬 수로 사용
  int get totalBudget => budget?.totalBudget ?? 0;

  Plan({
    required this.summary,
    required this.vlogTitle,
    required this.keywords,
    required this.goalDurationMin,
    this.equipment = '스마트폰',
    this.totalPeople = 1,
    required this.bufferRate,
    required this.chapters,
    this.styleAnalysis,
    this.shootingRoute,
    this.budget,
    this.alternativeScenes = const [],
    required this.shootingChecklist,
    this.userNotes = '',
    this.locationImage,
    this.equipmentRecommendation,
    this.weatherInfo,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    // 안전한 String 파싱 헬퍼
    String _safeString(dynamic value, {String defaultValue = '', bool joinList = false}) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is List) {
        if (value.isEmpty) return defaultValue;
        if (joinList) {
          // List를 join하여 하나의 문자열로 만듦 (summary 같은 경우)
          return value.map((e) => e.toString()).join('\n\n');
        }
        return value[0].toString();
      }
      return value.toString();
    }
    
    return Plan(
      summary: _safeString(json['summary'], joinList: true), // List인 경우 join
      vlogTitle: _safeString(json['vlog_title']),
      keywords: json['keywords'] != null
          ? List<String>.from((json['keywords'] as List<dynamic>).map((e) => e.toString()))
          : [],
      goalDurationMin: (json['goal_duration_min'] as num?)?.toInt() ?? 0,
      equipment: _safeString(json['equipment'], defaultValue: _safeString(json['equipment_recommendation'], defaultValue: '스마트폰')),
      totalPeople: (json['total_people'] as num?)?.toInt() ?? 1,
      bufferRate: (json['buffer_rate'] as num?)?.toDouble() ?? 0.0,
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((e) => Chapter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      styleAnalysis: json['style_analysis'] != null && json['style_analysis'] is Map<String, dynamic>
          ? StyleAnalysis.fromJson(json['style_analysis'] as Map<String, dynamic>)
          : null,
      shootingRoute: json['shooting_route'] != null && json['shooting_route'] is Map<String, dynamic>
          ? ShootingRoute.fromJson(json['shooting_route'] as Map<String, dynamic>)
          : null,
      budget: json['budget'] != null && json['budget'] is Map<String, dynamic>
          ? Budget.fromJson(json['budget'] as Map<String, dynamic>)
          : null,
      alternativeScenes: () {
        final altScenesJson = json['alternative_scenes'];
        print('[PLAN_MODEL] alternative_scenes 파싱 시작');
        print('[PLAN_MODEL]   - alternative_scenes 타입: ${altScenesJson.runtimeType}');
        if (altScenesJson == null) {
          print('[PLAN_MODEL]   - ⚠️ alternative_scenes가 null입니다');
          return <CueCard>[];
        }
        if (altScenesJson is! List) {
          print('[PLAN_MODEL]   - ⚠️ alternative_scenes가 List가 아닙니다: $altScenesJson');
          return <CueCard>[];
        }
        print('[PLAN_MODEL]   - alternative_scenes 개수: ${altScenesJson.length}');
        final altScenes = <CueCard>[];
        for (var i = 0; i < altScenesJson.length; i++) {
          final e = altScenesJson[i];
          if (e is! Map<String, dynamic>) {
            print('[PLAN_MODEL]   - ⚠️ 대체 씬 #${i + 1}이 Map이 아닙니다: ${e.runtimeType}');
            continue;
          }
          try {
            final sceneJson = e as Map<String, dynamic>;
            print('[PLAN_MODEL]   - 대체 씬 #${i + 1} 파싱: id=${sceneJson['id']}, title=${sceneJson['title']}');
            // 대체 씬의 id 필드를 alternativeSceneId로 매핑
            final cueCard = CueCard.fromJson(sceneJson);
            // id 필드가 있으면 alternativeSceneId로 설정
            if (sceneJson['id'] != null) {
              final altSceneId = sceneJson['id'] as String;
              print('[PLAN_MODEL]   - 대체 씬 #${i + 1} alternativeSceneId 설정: $altSceneId');
              altScenes.add(cueCard.copyWith(alternativeSceneId: altSceneId));
            } else {
              print('[PLAN_MODEL]   - ⚠️ 대체 씬 #${i + 1}에 id 필드가 없습니다');
              altScenes.add(cueCard);
            }
          } catch (e, stackTrace) {
            print('[PLAN_MODEL]   - ⚠️ 대체 씬 #${i + 1} 파싱 오류: $e');
            print('[PLAN_MODEL]   - 스택 트레이스: $stackTrace');
          }
        }
        print('[PLAN_MODEL] alternative_scenes 파싱 완료: ${altScenes.length}개');
        return altScenes;
      }(),
      shootingChecklist: json['shooting_checklist'] != null
          ? List<String>.from((json['shooting_checklist'] as List<dynamic>).map((e) => e.toString()))
          : [],
      userNotes: _safeString(json['user_notes']),
      locationImage: json['location_image'] != null ? _safeString(json['location_image']) : null,
      equipmentRecommendation: json['equipment_recommendation'] != null ? _safeString(json['equipment_recommendation']) : null,
      weatherInfo: json['weather_info'] != null && json['weather_info'] is Map<String, dynamic>
          ? json['weather_info'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'vlog_title': vlogTitle,
      'keywords': keywords,
      'goal_duration_min': goalDurationMin,
      'equipment': equipment,
      'total_people': totalPeople,
      'scene_count': sceneCount,
      'total_budget': totalBudget,
      'buffer_rate': bufferRate,
      'chapters': chapters.map((c) => c.toJson()).toList(),
      if (styleAnalysis != null) 'style_analysis': styleAnalysis!.toJson(),
      if (shootingRoute != null) 'shooting_route': shootingRoute!.toJson(),
      if (budget != null) 'budget': budget!.toJson(),
      'alternative_scenes': alternativeScenes.map((c) => c.toJson()).toList(),
      'shooting_checklist': shootingChecklist,
      'user_notes': userNotes,
      if (locationImage != null) 'location_image': locationImage,
      if (equipmentRecommendation != null) 'equipment_recommendation': equipmentRecommendation,
      if (weatherInfo != null) 'weather_info': weatherInfo,
    };
  }
}

// 스타일 분석 (레이더 차트용)
class StyleAnalysis {
  final String tone;
  final String vibe;
  final String pacing;
  final List<String> visualStyle;
  final List<String> audioStyle;
  // 레이더 차트를 위한 점수 (1-5)
  final int emotionalExpression; // 감정 표현
  final int movement; // 동작
  final int intensity; // 강도
  final int locationDiversity; // 장소 다양성
  final int speedRhythm; // 속도/리듬
  final int excitementSurprise; // 흥분/놀람
  final StyleRationale? rationale; // 점수에 대한 이유

  StyleAnalysis({
    required this.tone,
    required this.vibe,
    required this.pacing,
    required this.visualStyle,
    required this.audioStyle,
    this.emotionalExpression = 3,
    this.movement = 3,
    this.intensity = 3,
    this.locationDiversity = 3,
    this.speedRhythm = 3,
    this.excitementSurprise = 3,
    this.rationale,
  });

  factory StyleAnalysis.fromJson(Map<String, dynamic> json) {
    // 안전한 String 파싱 헬퍼
    String _safeString(dynamic value, {String defaultValue = ''}) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is List && value.isNotEmpty) return value[0].toString();
      return value.toString();
    }
    
    return StyleAnalysis(
      tone: _safeString(json['tone']),
      vibe: _safeString(json['vibe']),
      pacing: _safeString(json['pacing']),
      visualStyle: json['visual_style'] != null
          ? List<String>.from((json['visual_style'] as List<dynamic>).map((e) => e.toString()))
          : [],
      audioStyle: json['audio_style'] != null
          ? List<String>.from((json['audio_style'] as List<dynamic>).map((e) => e.toString()))
          : [],
      emotionalExpression: json['emotional_expression'] as int? ?? 3,
      movement: json['movement'] as int? ?? 3,
      intensity: json['intensity'] as int? ?? 3,
      locationDiversity: json['location_diversity'] as int? ?? 3,
      speedRhythm: json['speed_rhythm'] as int? ?? 3,
      excitementSurprise: json['excitement_surprise'] as int? ?? 3,
      rationale: json['rationale'] != null && json['rationale'] is Map<String, dynamic>
          ? StyleRationale.fromJson(json['rationale'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tone': tone,
      'vibe': vibe,
      'pacing': pacing,
      'visual_style': visualStyle,
      'audio_style': audioStyle,
      'emotional_expression': emotionalExpression,
      'movement': movement,
      'intensity': intensity,
      'location_diversity': locationDiversity,
      'speed_rhythm': speedRhythm,
      'excitement_surprise': excitementSurprise,
      if (rationale != null) 'rationale': rationale!.toJson(),
    };
  }
}

// 스타일 분석 이유
class StyleRationale {
  final String emotionalExpression;
  final String movement;
  final String intensity;
  final String locationDiversity;
  final String speedRhythm;
  final String excitementSurprise;

  StyleRationale({
    required this.emotionalExpression,
    required this.movement,
    required this.intensity,
    required this.locationDiversity,
    required this.speedRhythm,
    required this.excitementSurprise,
  });

  factory StyleRationale.fromJson(Map<String, dynamic> json) {
    // 안전한 String 파싱 헬퍼
    String _safeString(dynamic value, {String defaultValue = ''}) {
      if (value == null) {
        print('[PLAN_MODEL] rationale 필드가 null입니다');
        return defaultValue;
      }
      if (value is String) {
        print('[PLAN_MODEL] rationale 필드 타입: String, 길이: ${value.length}');
        return value;
      }
      if (value is List && value.isNotEmpty) {
        // List인 경우 각 항목을 bullet point로 조인
        print('[PLAN_MODEL] rationale 필드 타입: List, 항목 수: ${value.length}');
        return value.map((e) => e.toString()).join('\n');
      }
      print('[PLAN_MODEL] rationale 필드 타입: ${value.runtimeType}, toString() 사용');
      return value.toString();
    }
    
    print('[PLAN_MODEL] StyleRationale.fromJson 시작');
    final result = StyleRationale(
      emotionalExpression: _safeString(json['emotional_expression']),
      movement: _safeString(json['movement']),
      intensity: _safeString(json['intensity']),
      locationDiversity: _safeString(json['location_diversity']),
      speedRhythm: _safeString(json['speed_rhythm']),
      excitementSurprise: _safeString(json['excitement_surprise']),
    );
    print('[PLAN_MODEL] StyleRationale.fromJson 완료');
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'emotional_expression': emotionalExpression,
      'movement': movement,
      'intensity': intensity,
      'location_diversity': locationDiversity,
      'speed_rhythm': speedRhythm,
      'excitement_surprise': excitementSurprise,
    };
  }
}

// 촬영 동선
class ShootingRoute {
  final List<LocationPoint> locations;
  final String routeDescription;
  final int estimatedWalkingMinutes;

  ShootingRoute({
    required this.locations,
    required this.routeDescription,
    required this.estimatedWalkingMinutes,
  });

  factory ShootingRoute.fromJson(Map<String, dynamic> json) {
    // 안전한 String 파싱 헬퍼
    String _safeString(dynamic value, {String defaultValue = ''}) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is List && value.isNotEmpty) return value[0].toString();
      return value.toString();
    }
    
    return ShootingRoute(
      locations: (json['locations'] as List<dynamic>?)
              ?.map((e) => LocationPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      routeDescription: _safeString(json['route_description']),
      estimatedWalkingMinutes: json['estimated_walking_minutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locations': locations.map((l) => l.toJson()).toList(),
      'route_description': routeDescription,
      'estimated_walking_minutes': estimatedWalkingMinutes,
    };
  }
}

// 위치 포인트 (씬과 매핑)
class LocationPoint {
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final int order;
  final List<String> sceneIds; // 이 위치에서 촬영할 씬들의 ID

  LocationPoint({
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.order,
    this.sceneIds = const [],
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    // 안전한 String 파싱 헬퍼
    String _safeString(dynamic value, {String defaultValue = ''}) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is List && value.isNotEmpty) return value[0].toString();
      return value.toString();
    }
    
    return LocationPoint(
      name: _safeString(json['name']),
      description: _safeString(json['description']),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      order: json['order'] as int? ?? 0,
      sceneIds: json['scene_ids'] != null
          ? List<String>.from((json['scene_ids'] as List<dynamic>).map((e) => e.toString()))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'order': order,
      'scene_ids': sceneIds,
    };
  }
}

// 예산
class Budget {
  final int totalBudget;
  final List<BudgetItem> items;
  final String currency;

  Budget({
    required this.totalBudget,
    required this.items,
    required this.currency,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      totalBudget: json['total_budget'] as int? ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => BudgetItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currency: json['currency'] as String? ?? 'KRW',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_budget': totalBudget,
      'items': items.map((i) => i.toJson()).toList(),
      'currency': currency,
    };
  }
}

// 예산 항목
class BudgetItem {
  final String category;
  final String description;
  final int amount;

  BudgetItem({
    required this.category,
    required this.description,
    required this.amount,
  });

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    // 안전한 String 파싱 헬퍼
    String _safeString(dynamic value, {String defaultValue = ''}) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is List && value.isNotEmpty) return value[0].toString();
      return value.toString();
    }
    
    return BudgetItem(
      category: _safeString(json['category']),
      description: _safeString(json['description']),
      amount: json['amount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'description': description,
      'amount': amount,
    };
  }
}

