import 'chapter.dart';

class Plan {
  final String summary; // 전체 스토리보드 요약
  final String vlogTitle; // 브이로그 제목
  final List<String> keywords; // 브이로그 키워드 3개
  final int goalDurationMin;
  final double bufferRate;
  final List<Chapter> chapters;
  final StyleAnalysis? styleAnalysis;
  final ShootingRoute? shootingRoute;
  final Budget? budget;
  final List<String> shootingChecklist; // 촬영 준비 체크리스트

  // 새로 추가된 필드들
  final String? locationImage; // 대표 썸네일 이미지 URL
  final String? equipmentRecommendation; // 장비 추천
  final Map<String, dynamic>? weatherInfo; // 날씨 정보

  Plan({
    required this.summary,
    required this.vlogTitle,
    required this.keywords,
    required this.goalDurationMin,
    required this.bufferRate,
    required this.chapters,
    this.styleAnalysis,
    this.shootingRoute,
    this.budget,
    required this.shootingChecklist,
    this.locationImage,
    this.equipmentRecommendation,
    this.weatherInfo,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      summary: json['summary'] as String? ?? '',
      vlogTitle: json['vlog_title'] as String? ?? '',
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      goalDurationMin: json['goal_duration_min'] as int? ?? 0,
      bufferRate: (json['buffer_rate'] as num?)?.toDouble() ?? 0.0,
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((e) => Chapter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      styleAnalysis: json['style_analysis'] != null
          ? StyleAnalysis.fromJson(json['style_analysis'] as Map<String, dynamic>)
          : null,
      shootingRoute: json['shooting_route'] != null
          ? ShootingRoute.fromJson(json['shooting_route'] as Map<String, dynamic>)
          : null,
      budget: json['budget'] != null
          ? Budget.fromJson(json['budget'] as Map<String, dynamic>)
          : null,
      shootingChecklist: (json['shooting_checklist'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      locationImage: json['location_image'] as String?,
      equipmentRecommendation: json['equipment_recommendation'] as String?,
      weatherInfo: json['weather_info'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'vlog_title': vlogTitle,
      'keywords': keywords,
      'goal_duration_min': goalDurationMin,
      'buffer_rate': bufferRate,
      'chapters': chapters.map((c) => c.toJson()).toList(),
      if (styleAnalysis != null) 'style_analysis': styleAnalysis!.toJson(),
      if (shootingRoute != null) 'shooting_route': shootingRoute!.toJson(),
      if (budget != null) 'budget': budget!.toJson(),
      'shooting_checklist': shootingChecklist,
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
    return StyleAnalysis(
      tone: json['tone'] as String? ?? '',
      vibe: json['vibe'] as String? ?? '',
      pacing: json['pacing'] as String? ?? '',
      visualStyle: (json['visual_style'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      audioStyle: (json['audio_style'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      emotionalExpression: json['emotional_expression'] as int? ?? 3,
      movement: json['movement'] as int? ?? 3,
      intensity: json['intensity'] as int? ?? 3,
      locationDiversity: json['location_diversity'] as int? ?? 3,
      speedRhythm: json['speed_rhythm'] as int? ?? 3,
      excitementSurprise: json['excitement_surprise'] as int? ?? 3,
      rationale: json['rationale'] != null
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
    return StyleRationale(
      emotionalExpression: json['emotional_expression'] as String? ?? '',
      movement: json['movement'] as String? ?? '',
      intensity: json['intensity'] as String? ?? '',
      locationDiversity: json['location_diversity'] as String? ?? '',
      speedRhythm: json['speed_rhythm'] as String? ?? '',
      excitementSurprise: json['excitement_surprise'] as String? ?? '',
    );
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
    return ShootingRoute(
      locations: (json['locations'] as List<dynamic>?)
              ?.map((e) => LocationPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      routeDescription: json['route_description'] as String? ?? '',
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

// 위치 포인트
class LocationPoint {
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final int order;

  LocationPoint({
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.order,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'order': order,
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
    return BudgetItem(
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
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

