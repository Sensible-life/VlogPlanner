import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/openai_service.dart';
import '../../services/vlog_data_service.dart';
import '../../services/image_service.dart';
import '../../services/weather_service.dart';
import '../../services/budget_service.dart';
import '../../widgets/loading_dialog.dart';
import 'tabs/concept_style_tab.dart';
import 'tabs/detail_plan_tab.dart';
import 'tabs/environment_tab.dart';
import '../../models/plan.dart';
import '../../models/cue_card.dart';
import '../storyboard/storyboard_page.dart';

class UserInputPage extends StatefulWidget {
  const UserInputPage({super.key});

  @override
  State<UserInputPage> createState() => _UserInputPageState();
}

class _UserInputPageState extends State<UserInputPage> {
  int _selectedSegment = 0;
  late PageController _pageController;
  double _dragStartX = 0;
  bool _isLoading = false;
  
  // 사용자 입력 데이터 저장
  final Map<String, String> _userInput = {
    'target_duration': '8',
    'difficulty': 'novice',
    'time_weather': 'daytime',
    'equipment': 'smartphone',
    'location': '',
    // 기본값 제거 - 화면에서 실제로 입력받는 값만 저장
  };

  // 사용자 입력 업데이트 메서드
  void _updateUserInput(String key, String value) {
    setState(() {
      _userInput[key] = value;
    });
    print('[USER_INPUT] 업데이트: $key = $value');
  }
  
  // 모든 사용자 입력 업데이트 (key, value 형태)
  void _updateUserInputFromTab(String key, String value) {
    setState(() {
      _userInput[key] = value;
    });
    print('[USER_INPUT] 탭에서 업데이트: $key = $value');
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedSegment = index;
    });
  }

  void _onSegmentTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 150),
      curve: Curves.linear,
    );
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    
    // 속도 기반: 빠르게 스와이프하면 작은 거리여도 넘어감
    if (velocity < -100 && _selectedSegment < 2) {
      // 왼쪽으로 빠르게 스와이프 -> 다음 페이지
      _pageController.jumpToPage(_selectedSegment + 1);
    } else if (velocity > 100 && _selectedSegment > 0) {
      // 오른쪽으로 빠르게 스와이프 -> 이전 페이지
      _pageController.jumpToPage(_selectedSegment - 1);
    }
  }

  // 브이로그 계획 생성 (Fine-tuned Model + 추가 기능들)
  Future<void> _generateVlogPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dataService = VlogDataService();

      // 0. 템플릿 캐시 초기화 (새로운 스토리보드 생성 시)
      OpenAIService.clearTemplateCache();

      // 1. 사용자 입력 저장
      dataService.setUserInput(_userInput);

      // 2. Fine-tuned Model로 스토리보드 생성
      if (mounted) {
        showLoadingDialog(
          context,
          title: '스토리보드 생성 중',
          message: 'AI가 당신만의 브이로그 스토리보드를\n작성하고 있습니다...\n\n⚠️ 앱을 백그라운드로 전환하지 마세요\n잠시만 기다려주세요 (약 15-30초)',
          progress: 0.2,
        );
      }

      print('[USER_INPUT] Fine-tuned model로 스토리보드 생성 시작');
      print('[USER_INPUT] 사용자 입력: $_userInput');

      final storyboard = await OpenAIService.generateStoryboardWithFineTunedModel(_userInput);

      if (storyboard == null) {
        if (mounted) Navigator.pop(context);
        _showErrorDialog('스토리보드 생성에 실패했습니다.\nAPI 키를 확인하거나 네트워크 연결을 확인해주세요.');
        return;
      }

      print('[USER_INPUT] 스토리보드 생성 완료, 파싱 시작');

      // 3. Plan과 CueCards 파싱
      final result = await OpenAIService.parseStoryboard(storyboard);

      if (result == null || result.plan == null || result.cueCards == null) {
        if (mounted) Navigator.pop(context);
        _showErrorDialog('스토리보드 파싱에 실패했습니다.\n응답 형식을 확인해주세요.');
        return;
      }

      print('[USER_INPUT] 파싱 완료: Plan과 ${result.cueCards!.length}개의 CueCard');

      // VlogDataService에 저장 (Script 생성 전에 필수!)
      final vlogService = VlogDataService();
      vlogService.setPlan(result.plan!);
      vlogService.setCueCards(result.cueCards!);
      print('[USER_INPUT] VlogDataService에 Plan과 CueCards 저장 완료');
      print('[USER_INPUT] 저장 확인: plan=${vlogService.plan != null ? "존재" : "null"}, cueCards=${vlogService.cueCards?.length ?? 0}개');

      // 4. 추가 기능 실행 (병렬 처리)
      if (mounted) {
        Navigator.pop(context);
        showLoadingDialog(
          context,
          title: '세부 정보 생성 중',
          message: 'Script, 이미지, 장비 추천 등을\n생성하고 있습니다...\n\n⚠️ 앱을 백그라운드로 전환하지 마세요',
          progress: 0.6,
        );
      }

      print('[USER_INPUT] 추가 기능 실행 시작');

      // 병렬로 실행할 작업들
      final futures = <Future>[];

      // 4-1. 씬별 스크립트 (병렬, 타임아웃 포함)
      final scriptFutures = result.cueCards!.asMap().entries.map((entry) {
        final index = entry.key;
        final cueCard = entry.value;
        return OpenAIService.generateScriptForScene(
          sceneLocation: cueCard.title,
          sceneSummary: cueCard.summary.join(' '),
          tone: result.plan!.styleAnalysis?.tone ?? '',
          vibe: result.plan!.styleAnalysis?.vibe ?? '',
          durationSec: cueCard.allocatedSec,
          sceneIndex: index + 1,
          totalScenes: result.cueCards!.length,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('[USER_INPUT] 씬 #${index + 1} 스크립트 생성 타임아웃');
            return '${cueCard.title}에 대한 멋진 장면입니다.';
          },
        );
      }).toList();

      // 4-2. 시나리오 요약 (SEO용, 타임아웃 포함)
      final scenarioSummaryFuture = OpenAIService.generateScenarioSummary(
        sceneSummaries: result.cueCards!.map((c) => c.summary.join(' ')).toList(),
        location: _userInput['location'] ?? '',
        tone: result.plan!.styleAnalysis?.tone ?? '',
        durationMin: result.plan!.goalDurationMin ?? 10,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('[USER_INPUT] 시나리오 요약 생성 타임아웃');
          return '${result.plan!.vlogTitle} 브이로그';
        },
      );

      // 4-3. 대표 썸네일 (타임아웃 포함)
      final mainThumbnailFuture = ImageService.searchMainThumbnail(
        title: result.plan!.vlogTitle ?? '브이로그',
        keywords: result.plan!.keywords,
        tone: result.plan!.styleAnalysis?.tone ?? '',
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('[USER_INPUT] 대표 썸네일 검색 타임아웃');
          return null;
        },
      );

      // 4-4. 씬별 이미지 (병렬, 타임아웃 포함)
      final sceneImageFutures = result.cueCards!.asMap().entries.map((entry) {
        final index = entry.key;
        final cueCard = entry.value;
        return ImageService.searchSceneImage(
          location: cueCard.title,
          summary: cueCard.summary.join(' '),
          tone: result.plan!.styleAnalysis?.tone ?? '',
          globalLocation: _userInput['location'],  // 전체 촬영 장소 (예: "바르셀로나")
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('[USER_INPUT] 씬 #${index + 1} 이미지 검색 타임아웃');
            return null;
          },
        );
      }).toList();

      // 4-5. 장비 추천
      final equipmentFuture = OpenAIService.recommendEquipment(
        location: _userInput['location'] ?? '',
        tone: result.plan!.styleAnalysis?.tone ?? '',
        equipment: _userInput['equipment'] ?? 'smartphone',
        difficulty: _userInput['difficulty'] ?? 'novice',
      );

      // 4-6. 날씨 정보 (촬영 장소 기반)
      final weatherFuture = WeatherService.getWeatherInfo(_userInput['location'] ?? 'Seoul');

      // 4-7. 예산 정보
      final budgetFuture = BudgetService.getBudgetEstimate(
        location: _userInput['location'] ?? '',
        categories: ['입장료', '식사', '교통', '간식'],
      );

      // 모든 작업 병렬 실행
      print('[USER_INPUT] 병렬 작업 시작 (${scriptFutures.length} 스크립트 + ${sceneImageFutures.length} 이미지 + 4개 추가 작업)');

      final results = await Future.wait<dynamic>([
        ...scriptFutures,
        scenarioSummaryFuture,
        mainThumbnailFuture,
        ...sceneImageFutures,
        equipmentFuture.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('[USER_INPUT] 장비 추천 타임아웃');
            return null;
          },
        ),
        weatherFuture.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('[USER_INPUT] 날씨 정보 타임아웃');
            return null;
          },
        ),
        budgetFuture.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('[USER_INPUT] 예산 정보 타임아웃');
            return <Map<String, dynamic>>[];
          },
        ),
      ]);

      print('[USER_INPUT] 병렬 작업 완료');

      // 결과 적용
      final numScenes = result.cueCards!.length;

      // Scripts 적용
      for (int i = 0; i < numScenes; i++) {
        final script = results[i] as String?;
        if (script != null) {
          result.cueCards![i] = CueCard(
            title: result.cueCards![i].title,
            allocatedSec: result.cueCards![i].allocatedSec,
            trigger: result.cueCards![i].trigger,
            summary: result.cueCards![i].summary,
            steps: result.cueCards![i].steps,
            checklist: result.cueCards![i].checklist,
            fallback: result.cueCards![i].fallback,
            startHint: result.cueCards![i].startHint,
            stopHint: result.cueCards![i].stopHint,
            completionCriteria: result.cueCards![i].completionCriteria,
            tone: result.cueCards![i].tone,
            styleVibe: result.cueCards![i].styleVibe,
            targetAudience: result.cueCards![i].targetAudience,
            script: script,
            pro: result.cueCards![i].pro,
            rawMarkdown: result.cueCards![i].rawMarkdown,
            thumbnailUrl: null,  // 나중에 적용
          );
        }
      }

      // 시나리오 요약 적용
      final scenarioSummary = results[numScenes] as String?;

      // 대표 썸네일 적용
      final mainThumbnail = results[numScenes + 1] as String?;

      // 씬별 이미지 적용
      for (int i = 0; i < numScenes; i++) {
        final sceneImage = results[numScenes + 2 + i] as String?;
        if (sceneImage != null) {
          result.cueCards![i] = CueCard(
            title: result.cueCards![i].title,
            allocatedSec: result.cueCards![i].allocatedSec,
            trigger: result.cueCards![i].trigger,
            summary: result.cueCards![i].summary,
            steps: result.cueCards![i].steps,
            checklist: result.cueCards![i].checklist,
            fallback: result.cueCards![i].fallback,
            startHint: result.cueCards![i].startHint,
            stopHint: result.cueCards![i].stopHint,
            completionCriteria: result.cueCards![i].completionCriteria,
            tone: result.cueCards![i].tone,
            styleVibe: result.cueCards![i].styleVibe,
            targetAudience: result.cueCards![i].targetAudience,
            script: result.cueCards![i].script,
            pro: result.cueCards![i].pro,
            rawMarkdown: result.cueCards![i].rawMarkdown,
            thumbnailUrl: sceneImage,
          );
        }
      }

      // 장비 추천 적용
      final equipment = results[numScenes + 2 + numScenes] as String?;

      // 날씨 정보 적용
      final weather = results[numScenes + 2 + numScenes + 1] as Map<String, dynamic>?;

      // 예산 정보 적용
      final budgetItems = results[numScenes + 2 + numScenes + 2] as List<Map<String, dynamic>>?;

      // 예산 객체 생성 (BudgetService의 결과를 Budget 모델로 변환)
      Budget? updatedBudget;
      if (budgetItems != null && budgetItems.isNotEmpty) {
        final totalBudget = BudgetService.calculateTotalBudget(budgetItems);
        final budgetItemObjects = budgetItems.map((item) {
          return BudgetItem(
            category: item['category'] as String? ?? '',
            description: item['description'] as String? ?? '',
            amount: item['amount'] as int? ?? 0,
          );
        }).toList();
        
        updatedBudget = Budget(
          totalBudget: totalBudget,
          items: budgetItemObjects,
          currency: 'KRW',
        );
        print('[USER_INPUT] 예산 정보 생성 완료: 총 ${totalBudget.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원');
      }

      // Plan 업데이트
      final updatedPlan = Plan(
        summary: scenarioSummary ?? result.plan!.summary,
        vlogTitle: result.plan!.vlogTitle,
        keywords: result.plan!.keywords,
        goalDurationMin: result.plan!.goalDurationMin,
        bufferRate: result.plan!.bufferRate,
        chapters: result.plan!.chapters,
        styleAnalysis: result.plan!.styleAnalysis,
        shootingRoute: result.plan!.shootingRoute,
        budget: updatedBudget ?? result.plan!.budget,  // 새로 가져온 예산 사용
        shootingChecklist: result.plan!.shootingChecklist,
        locationImage: mainThumbnail,
        equipmentRecommendation: equipment,
        weatherInfo: weather,
      );

      print('[USER_INPUT] 모든 추가 기능 적용 완료');

      // 5. VlogDataService에 저장
      dataService.setPlan(updatedPlan);
      dataService.setCueCards(result.cueCards!);

      print('[USER_INPUT] VlogDataService에 저장 완료');
      print('[USER_INPUT] 브이로그 제목: ${updatedPlan.vlogTitle}');
      print('[USER_INPUT] 키워드: ${updatedPlan.keywords.join(", ")}');
      print('[USER_INPUT] 씬 개수: ${result.cueCards!.length}');

      // 현재 스토리보드 저장
      final storyboardId = dataService.saveCurrentStoryboard(mainThumbnail: mainThumbnail);
      print('[USER_INPUT] 스토리보드 저장 완료: ID=$storyboardId');

      // 완료
      if (mounted) {
        Navigator.pop(context);
        showLoadingDialog(
          context,
          title: '완료!',
          message: '브이로그 촬영 계획이 준비되었습니다.\n\n제목: ${updatedPlan.vlogTitle}\n씬 개수: ${result.cueCards!.length}개',
          progress: 1.0,
        );

        // 잠시 후 스토리보드 페이지로 이동
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.pop(context);
          // 스토리보드 페이지로 이동 (뒤로가기 가능하도록 pushReplacement 대신 push 사용)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const StoryboardPage(),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('[USER_INPUT] 에러 발생: $e');
      print('[USER_INPUT] 스택 트레이스: $stackTrace');

      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog('오류가 발생했습니다:\n$e\n\n콘솔을 확인해주세요.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          '오류',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '확인',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
  
  // 세그먼트 버튼 생성 헬퍼 메서드
  Widget _buildSegmentButton(int index, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onSegmentTapped(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          color: Colors.transparent,
          child: Text(
            label,
            style: AppTextStyles.segmentButton.copyWith(
              color: _selectedSegment == index
                  ? Colors.white
                  : AppColors.textPrimary,
              fontWeight: _selectedSegment == index
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 헤더 영역 (타이틀 + 세그먼티드 컨트롤)
          Container(
            color: AppColors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // 페이지 타이틀
                  Padding(
                    padding: const EdgeInsets.only(top: 18.0, left: 5.0, right: 18.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: AppColors.textPrimary,
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            '브이로그 기획',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 35),  // 오른쪽 여백 (화살표 버튼 크기만큼)
                      ],
                    ),
                  ),
                  
                  // 세그먼티드 컨트롤 (iOS 스타일)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 8.0, left: 18.0, right: 18.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final segmentWidth = (constraints.maxWidth - 6) / 3;  // padding all(3) = 좌우 6
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Stack(
                            children: [
                              // 애니메이션되는 선택 표시
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeInOut,
                                left: _selectedSegment * segmentWidth,
                                top: 0,
                                bottom: 0,
                                width: segmentWidth,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              // 버튼들
                              Row(
                                children: [
                                  _buildSegmentButton(0, '컨셉&스타일'),
                                  _buildSegmentButton(1, '상세 기획'),
                                  _buildSegmentButton(2, '환경&제약'),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 페이지뷰 (스와이프 가능)
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
                children: [
                  ConceptStyleTab(
                    onDurationChanged: (value) => _updateUserInput('target_duration', value),
                    onInputChanged: (key, value) => _updateUserInputFromTab(key, value),
                    initialValues: _userInput,
                  ),
                  DetailPlanTab(
                    onLocationChanged: (value) => _updateUserInput('location', value),
                    onInputChanged: (key, value) => _updateUserInputFromTab(key, value),
                    initialValues: _userInput,
                  ),
                  EnvironmentTab(
                    onEquipmentChanged: (value) => _updateUserInput('equipment', value),
                    onTimeWeatherChanged: (value) => _updateUserInput('time_weather', value),
                    onDifficultyChanged: (value) => _updateUserInput('difficulty', value),
                    onInputChanged: (key, value) => _updateUserInputFromTab(key, value),
                    initialValues: _userInput,
                  ),
                ],
              ),
            ),
          ),
          
          // 완료 버튼 (bottomNavigationBar 위에 위치)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: SizedBox(
                width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _generateVlogPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          '완료',
                          style: AppTextStyles.button.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

