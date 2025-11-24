import '../models/cue_card.dart';
import '../models/plan.dart';
import '../services/vlog_data_service.dart';
import '../services/openai_service.dart';
import '../services/dalle_image_service.dart';
import '../services/image_service.dart';
import '../services/progress_notification_service.dart';

/// 스토리보드 생성 및 수정을 위한 통합 서비스
/// 진행 상황 관리를 중앙화하여 앱 전체에서 일관되게 표시
class StoryboardGenerationService {
  static const int batchSize = 5; // DALL-E 배치 크기

  /// 스토리보드 생성 (전체 프로세스)
  static Future<({Plan? plan, List<CueCard>? cueCards, String? storyboardId})?> generateStoryboard({
    required Map<String, String> userInput,
    required VlogDataService dataService,
  }) async {
    try {
      // 진행 상황 알림 시작
      ProgressNotificationService().show(progress: 0.0, task: '영상 계획을 세우는 중...');

      // 1단계: 스토리보드 생성 (0-40%)
      ProgressNotificationService().update(progress: 0.05, task: '영상 계획을 세우는 중...');
      final storyboard = await OpenAIService.generateStoryboardWithFineTunedModel(userInput);

      if (storyboard == null) {
        ProgressNotificationService().hide();
        return null;
      }

      // 2단계: 스토리보드 파싱
      ProgressNotificationService().update(progress: 0.45, task: '스토리보드 정보를 정리하는 중...');
      final result = await OpenAIService.parseStoryboard(storyboard);

      if (result == null || result.plan == null || result.cueCards == null) {
        ProgressNotificationService().hide();
        return null;
      }

      // 3단계: 썸네일 검색
      ProgressNotificationService().update(progress: 0.5, task: '대표 이미지를 찾는 중...');
      Plan? planWithThumbnail = result.plan;
      if (planWithThumbnail != null) {
        final plan = planWithThumbnail;
        final requiredLocation = userInput['required_locations'] as List<String>?;
        final mainLocation = (requiredLocation?.isNotEmpty ?? false)
            ? requiredLocation![0]
            : (userInput['location']?.toString() ?? '');

        if (mainLocation.isNotEmpty) {
          final thumbnailUrl = await ImageService.searchMainThumbnail(
            title: mainLocation,
            keywords: [mainLocation, ...plan.keywords],
            tone: plan.styleAnalysis?.tone ?? '밝고 경쾌',
          );

          if (thumbnailUrl != null) {
            planWithThumbnail = Plan(
              summary: plan.summary,
              vlogTitle: plan.vlogTitle,
              keywords: plan.keywords,
              goalDurationMin: plan.goalDurationMin,
              equipment: plan.equipment,
              totalPeople: plan.totalPeople,
              bufferRate: plan.bufferRate,
              chapters: plan.chapters,
              styleAnalysis: plan.styleAnalysis,
              shootingRoute: plan.shootingRoute,
              budget: plan.budget,
              alternativeScenes: plan.alternativeScenes,
              shootingChecklist: plan.shootingChecklist,
              userNotes: plan.userNotes,
              locationImage: thumbnailUrl,
            );
          }
        }
      }

      dataService.setPlan(planWithThumbnail ?? result.plan!);
      dataService.setCueCards(result.cueCards!);

      // 4단계: 씬 이미지 생성 (50-80%)
      ProgressNotificationService().update(progress: 0.55, task: '씬별 스케치를 그리는 중...');
      final updatedCueCards = await _generateSceneImages(result.cueCards!);

      dataService.setCueCards(updatedCueCards);

      // 5단계: 대체 씬 이미지 생성 (80-90%)
      ProgressNotificationService().update(progress: 0.8, task: '대체 씬 스케치를 그리는 중...');
      final currentPlan = dataService.plan;
      if (currentPlan != null && currentPlan.alternativeScenes.isNotEmpty) {
        final updatedAltScenes = await _generateAlternativeSceneImages(currentPlan.alternativeScenes);
        
        final updatedPlan = Plan(
          summary: currentPlan.summary,
          vlogTitle: currentPlan.vlogTitle,
          keywords: currentPlan.keywords,
          goalDurationMin: currentPlan.goalDurationMin,
          equipment: currentPlan.equipment,
          totalPeople: currentPlan.totalPeople,
          bufferRate: currentPlan.bufferRate,
          chapters: currentPlan.chapters,
          styleAnalysis: currentPlan.styleAnalysis,
          shootingRoute: currentPlan.shootingRoute,
          budget: currentPlan.budget,
          alternativeScenes: updatedAltScenes,
          shootingChecklist: currentPlan.shootingChecklist,
          userNotes: currentPlan.userNotes,
          locationImage: currentPlan.locationImage,
          equipmentRecommendation: currentPlan.equipmentRecommendation,
          weatherInfo: currentPlan.weatherInfo,
        );
        dataService.setPlan(updatedPlan);
      }

      // 6단계: 저장 (90-100%)
      ProgressNotificationService().update(progress: 0.9, task: '스토리보드를 저장하는 중...');
      final finalPlan = dataService.plan;
      String? mainThumbnail;
      if (finalPlan?.locationImage != null && finalPlan!.locationImage!.isNotEmpty) {
        mainThumbnail = finalPlan.locationImage;
      } else if (updatedCueCards.isNotEmpty &&
          updatedCueCards[0].storyboardImageUrl != null &&
          updatedCueCards[0].storyboardImageUrl!.isNotEmpty) {
        mainThumbnail = updatedCueCards[0].storyboardImageUrl;
      }

      final storyboardId = await dataService.saveCurrentStoryboard(mainThumbnail: mainThumbnail);

      ProgressNotificationService().update(progress: 1.0, task: '완료되었습니다!');
      await Future.delayed(const Duration(milliseconds: 500));
      ProgressNotificationService().hide();

      return (
        plan: dataService.plan,
        cueCards: dataService.cueCards,
        storyboardId: storyboardId,
      );
    } catch (e) {
      print('[STORYBOARD_GEN] 스토리보드 생성 오류: $e');
      ProgressNotificationService().hide();
      return null;
    }
  }

  /// 씬 이미지 생성
  static Future<List<CueCard>> _generateSceneImages(List<CueCard> cueCards) async {
    final scenesNeedingSketch = <int, CueCard>{};
    for (int i = 0; i < cueCards.length; i++) {
      final cueCard = cueCards[i];
      if (cueCard.storyboardImageUrl == null || cueCard.storyboardImageUrl!.isEmpty) {
        scenesNeedingSketch[i] = cueCard;
      }
    }

    if (scenesNeedingSketch.isEmpty) {
      return cueCards;
    }

    final imageUrlMap = <int, String?>{};
    final scenesList = scenesNeedingSketch.entries.toList();
    final totalBatches = (scenesList.length / batchSize).ceil();

    for (int batchStart = 0; batchStart < scenesList.length; batchStart += batchSize) {
      final batchEnd = (batchStart + batchSize < scenesList.length)
          ? batchStart + batchSize
          : scenesList.length;
      final batch = scenesList.sublist(batchStart, batchEnd);
      final currentBatch = (batchStart ~/ batchSize) + 1;

      ProgressNotificationService().update(
        progress: 0.55 + (currentBatch / totalBatches) * 0.25,
        task: '씬별 스케치를 그리는 중... (${currentBatch}/$totalBatches)',
      );

      final futures = batch.map((entry) async {
        final index = entry.key;
        final cueCard = entry.value;

        try {
          final imageUrl = await DalleImageService.generateStoryboardImage(
            sceneTitle: cueCard.title,
            shotComposition: cueCard.shotComposition,
            shootingInstructions: cueCard.shootingInstructions,
            location: cueCard.location,
            summary: cueCard.summary.isNotEmpty ? cueCard.summary.join(' ') : cueCard.title,
            checklist: cueCard.checklist,
          );
          return MapEntry(index, imageUrl);
        } catch (e) {
          print('[STORYBOARD_GEN] 씬 ${index + 1} 스케치 생성 오류: $e');
          return MapEntry(index, null as String?);
        }
      });

      final batchResults = await Future.wait(futures);
      imageUrlMap.addAll(Map.fromEntries(batchResults));

      if (batchEnd < scenesList.length) {
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    }

    // 결과를 바탕으로 CueCard 업데이트
    final updatedCueCards = <CueCard>[];
    for (int i = 0; i < cueCards.length; i++) {
      final cueCard = cueCards[i];
      if (imageUrlMap.containsKey(i) && imageUrlMap[i] != null) {
        final updatedCard = cueCard.copyWith(
          storyboardImageUrl: imageUrlMap[i],
        );
        updatedCueCards.add(updatedCard);
      } else {
        updatedCueCards.add(cueCard);
      }
    }

    return updatedCueCards;
  }

  /// 대체 씬 이미지 생성
  static Future<List<CueCard>> _generateAlternativeSceneImages(List<CueCard> alternativeScenes) async {
    if (alternativeScenes.isEmpty) {
      return alternativeScenes;
    }

    final altImageUrlMap = <int, String?>{};
    final altScenesList = alternativeScenes.asMap().entries.toList();
    final altTotalBatches = (altScenesList.length / batchSize).ceil();

    for (int batchStart = 0; batchStart < altScenesList.length; batchStart += batchSize) {
      final batchEnd = (batchStart + batchSize < altScenesList.length)
          ? batchStart + batchSize
          : altScenesList.length;
      final batch = altScenesList.sublist(batchStart, batchEnd);
      final currentBatch = (batchStart ~/ batchSize) + 1;

      ProgressNotificationService().update(
        progress: 0.8 + (currentBatch / altTotalBatches) * 0.1,
        task: '대체 씬 스케치를 그리는 중... (${currentBatch}/$altTotalBatches)',
      );

      final futures = batch.map((entry) async {
        final index = entry.key;
        final altScene = entry.value;

        try {
          final imageUrl = await DalleImageService.generateStoryboardImage(
            sceneTitle: altScene.title,
            shotComposition: altScene.shotComposition,
            shootingInstructions: altScene.shootingInstructions,
            location: altScene.location,
            summary: altScene.summary.isNotEmpty ? altScene.summary.join(' ') : altScene.title,
            checklist: altScene.checklist,
          );
          return MapEntry(index, imageUrl);
        } catch (e) {
          print('[STORYBOARD_GEN] 대체 씬 ${index + 1} 스케치 생성 오류: $e');
          return MapEntry(index, null as String?);
        }
      });

      final batchResults = await Future.wait(futures);
      altImageUrlMap.addAll(Map.fromEntries(batchResults));

      if (batchEnd < altScenesList.length) {
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    }

    // 결과를 바탕으로 CueCard 업데이트
    final updatedAltScenes = <CueCard>[];
    for (int i = 0; i < alternativeScenes.length; i++) {
      final altScene = alternativeScenes[i];
      if (altImageUrlMap.containsKey(i) && altImageUrlMap[i] != null) {
        final updatedAltScene = altScene.copyWith(
          storyboardImageUrl: altImageUrlMap[i],
        );
        updatedAltScenes.add(updatedAltScene);
      } else {
        updatedAltScenes.add(altScene);
      }
    }

    return updatedAltScenes;
  }

  /// 스토리보드 수정
  static Future<({Plan? plan, List<CueCard>? cueCards})?> modifyStoryboard({
    required Map<String, dynamic> currentStoryboard,
    required String modificationRequest,
    required VlogDataService dataService,
  }) async {
    try {
      // 진행 상황 알림 시작
      ProgressNotificationService().show(progress: 0.1, task: '스토리보드 수정 중...');

      // 스토리보드 수정 API 호출
      final modifiedStoryboard = await OpenAIService.modifyStoryboardWithFineTunedModel(
        currentStoryboard: currentStoryboard,
        modificationRequest: modificationRequest,
      );

      if (modifiedStoryboard == null) {
        ProgressNotificationService().hide();
        return null;
      }

      // 수정된 스토리보드 파싱
      ProgressNotificationService().update(progress: 0.85, task: '수정된 스토리보드 정보를 정리하는 중...');
      final result = await OpenAIService.parseStoryboard(modifiedStoryboard);

      if (result == null || result.plan == null || result.cueCards == null) {
        ProgressNotificationService().hide();
        return null;
      }

      // 데이터 서비스 업데이트
      ProgressNotificationService().update(progress: 0.9, task: '스토리보드를 저장하는 중...');
      dataService.plan = result.plan;
      dataService.cueCards = result.cueCards;

      // Firebase에 저장
      await dataService.updateCurrentStoryboard();

      ProgressNotificationService().update(progress: 1.0, task: '완료되었습니다!');
      await Future.delayed(const Duration(milliseconds: 500));
      ProgressNotificationService().hide();

      return (
        plan: result.plan,
        cueCards: result.cueCards,
      );
    } catch (e) {
      print('[STORYBOARD_GEN] 스토리보드 수정 오류: $e');
      ProgressNotificationService().hide();
      return null;
    }
  }
}

