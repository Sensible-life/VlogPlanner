import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../services/vlog_data_service.dart';
import '../../widgets/style_radar_chart.dart';
import '../scene/scene_list_page.dart';

class StoryboardPage extends StatefulWidget {
  const StoryboardPage({super.key});

  @override
  State<StoryboardPage> createState() => _StoryboardPageState();
}

class _StoryboardPageState extends State<StoryboardPage> {
  bool _isEditMode = false;
  final TextEditingController _editController = TextEditingController();
  final VlogDataService _dataService = VlogDataService();

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _editController.clear();
      }
    });
  }

  // 스토리보드 재생성 실행
  void _regenerateStoryboard(String feedback) async {
    // 편집 모드 종료
    _toggleEditMode();

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('스토리보드를 재생성하고 있습니다...'),
                SizedBox(height: 8),
                Text(
                  '이 작업은 20-30초 정도 소요됩니다',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // VlogDataService에서 필요한 데이터 가져오기
      final plan = _dataService.plan;
      final cueCards = _dataService.cueCards;
      final userInput = _dataService.userInput;

      if (plan == null || cueCards == null) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('스토리보드 데이터를 찾을 수 없습니다')),
        );
        return;
      }

      // 스토리보드 재생성
      final result = await OpenAIService.regenerateStoryboard(
        originalPlan: plan,
        originalCueCards: cueCards,
        userFeedback: feedback,
        userInput: userInput,
      );

      if (mounted) Navigator.pop(context); // 로딩 다이얼로그 닫기

      if (result != null && result.plan != null && result.cueCards != null) {
        // VlogDataService 업데이트
        _dataService.setPlan(result.plan!);
        _dataService.setCueCards(result.cueCards!);
        
        // 저장된 스토리보드도 업데이트
        _dataService.updateCurrentStoryboard();

        // 추가 기능들 재실행 (script, 이미지 등)
        _regenerateAdditionalFeatures(result.plan!, result.cueCards!);

        // UI 업데이트
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('스토리보드가 성공적으로 재생성되었습니다')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('스토리보드 재생성에 실패했습니다')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  // 추가 기능 재생성 (script, 이미지 등)
  void _regenerateAdditionalFeatures(Plan plan, List<CueCard> cueCards) async {
    try {
      // 여기서는 간단히 로그만 출력
      // 실제로는 user_input_page.dart의 로직을 재사용하거나
      // 백그라운드에서 script/이미지를 다시 생성할 수 있습니다
      debugPrint('[STORYBOARD] 추가 기능 재생성 필요: ${cueCards.length}개 씬');

      // TODO: 필요시 script, 이미지, 장비 추천 등을 다시 생성
      // 현재는 스토리보드 구조만 재생성하고 나머지는 나중에 처리
    } catch (e) {
      debugPrint('[STORYBOARD] 추가 기능 재생성 오류: $e');
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.textPrimary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
      child: Text(
        title,
        style: AppTextStyles.heading3.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Text(
        content,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: Stack(
        children: [
          // 배경 고정 이미지
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight / 2,
            child: _dataService.plan?.locationImage != null && _dataService.plan!.locationImage!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: _dataService.plan!.locationImage!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.cardBackground,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.cardBackground,
                      child: Center(
                        child: Icon(
                          Icons.image,
                          size: 80,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.cardBackground,
                    child: Center(
                      child: Icon(
                        Icons.image,
                        size: 80,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
          ),
          
          // 스크롤 가능한 콘텐츠
          Positioned.fill(
            child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 투명 공간 (이미지 보이도록)
                SizedBox(height: screenHeight / 2 - 120),
                
                // 그라데이션 + 제목 (이미지와 겹침)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withOpacity(0.6),
                        AppColors.background,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 60.0, left: 18.0, right: 18.0, bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dataService.getVlogTitle(),
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _dataService.getKeywordsString(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 나머지 콘텐츠 (검은 배경)
                Container(
                  color: AppColors.background,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                const SizedBox(height: 16),
                
                // 특징 나열
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.camera_alt, '촬영 장비', _dataService.getEquipment()),
                      Divider(color: AppColors.grey.withOpacity(0.3)),
                      _buildInfoRow(Icons.timer, '촬영 길이', _dataService.getDuration()),
                      Divider(color: AppColors.grey.withOpacity(0.3)),
                      _buildInfoRow(Icons.movie, '씬 갯수', _dataService.getSceneCount()),
                      Divider(color: AppColors.grey.withOpacity(0.3)),
                      _buildInfoRow(Icons.attach_money, '촬영 예산', _dataService.getTotalBudget()),
                      Divider(color: AppColors.grey.withOpacity(0.3)),
                      _buildInfoRow(Icons.people, '등장 인물', _dataService.getPeople()),
                      Divider(color: AppColors.grey.withOpacity(0.3)),
                      _buildInfoRow(Icons.palette, '영상 톤', _dataService.getTone()),
                      Divider(color: AppColors.grey.withOpacity(0.3)),
                      if (_dataService.getWeatherInfo() != null)
                        _buildInfoRow(Icons.wb_sunny, '날씨', _dataService.getWeatherTemperature() != null 
                          ? '${_dataService.getWeatherTemperature()}°C, ${_dataService.getWeatherDescription()}'
                          : _dataService.getWeatherDescription()),
                      if (_dataService.getWeatherInfo() != null)
                        Divider(color: AppColors.grey.withOpacity(0.3)),
                    ],
                  ),
                ),
                
                // 날씨 추천사항
                if (_dataService.getWeatherRecommendation().isNotEmpty) ...[
                  _buildSectionTitle('날씨 기반 촬영 추천'),
                  _buildSectionContent(_dataService.getWeatherRecommendation()),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Divider(color: AppColors.grey.withOpacity(0.3)),
                  ),
                  const SizedBox(height: 16),
                ],
                
                const SizedBox(height: 40),
                
                // 시나리오 요약
                _buildSectionTitle('시나리오 요약'),
                _buildSectionContent(
                  _dataService.getSummary()
                ),
                
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Divider(color: AppColors.grey.withOpacity(0.3)),
                ),
                const SizedBox(height: 16),
                
                // 스타일/톤 분석
                _buildSectionTitle('스타일/톤 분석'),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.0),
                  child: StyleRadarChart(),
                ),
                
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Divider(color: AppColors.grey.withOpacity(0.3)),
                ),
                const SizedBox(height: 16),
                
                // 촬영 동선
                _buildSectionTitle('촬영 동선'),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.0),
                  child: ShootingRouteMap(),
                ),
                
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Divider(color: AppColors.grey.withOpacity(0.3)),
                ),
                const SizedBox(height: 16),
                
                // 예산 상세
                if (_dataService.getBudgetItems().isNotEmpty) ...[
                  _buildSectionTitle('예산 상세'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Column(
                      children: _dataService.getBudgetItems().map((item) {
                        return Column(
                          children: [
                            _buildInfoRow(
                              Icons.monetization_on,
                              item.category,
                              '${item.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                            ),
                            if (item.description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 40, bottom: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    item.description,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            Divider(color: AppColors.grey.withOpacity(0.3)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Divider(color: AppColors.grey.withOpacity(0.3)),
                  ),
                  const SizedBox(height: 16),
                ],

                // 장비 추천
                if (_dataService.getEquipmentRecommendation() != null) ...[
                  _buildSectionTitle('장비 추천'),
                  _buildSectionContent(_dataService.getEquipmentRecommendation()!),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Divider(color: AppColors.grey.withOpacity(0.3)),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // 촬영 준비 체크리스트
                _buildSectionTitle('촬영 준비 체크리스트'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _dataService.getChecklist().isEmpty
                        ? [_buildChecklistItem('데이터를 생성 중입니다...')]
                        : _dataService.getChecklist().map((item) => _buildChecklistItem(item)).toList(),
                  ),
                ),
                
                      const SizedBox(height: 120),  // 하단 버튼 공간 확보
                    ],
                  ),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              // 슬라이드 방향: 편집 모드는 오른쪽에서, 일반 모드는 왼쪽에서
              final offset = child.key == const ValueKey('edit')
                  ? const Offset(1.0, 0.0)  // 오른쪽에서 왼쪽으로
                  : const Offset(-1.0, 0.0); // 왼쪽에서 오른쪽으로
              
              return SlideTransition(
                position: Tween<Offset>(
                  begin: offset,
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            child: _isEditMode
                ? _buildEditModeButtons()
                : _buildNormalModeButtons(),
          ),
        ),
      ),
    );
  }

  // 일반 모드 버튼 (촬영하기 + 세부 씬 + 편집 아이콘)
  Widget _buildNormalModeButtons() {
    return Row(
      key: const ValueKey('normal'),
      children: [
        // 촬영하기 버튼
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // TODO: 촬영하기 로직
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: Text(
              '촬영하기',
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 세부 씬 버튼
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SceneListPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightGrey,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: Text(
              '세부 씬',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 편집 아이콘 버튼 (맨 오른쪽)
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(13),
          ),
          child: IconButton(
            icon: const Icon(Icons.edit),
            color: AppColors.textPrimary,
            onPressed: _toggleEditMode,
          ),
        ),
      ],
    );
  }

  // 편집 모드 버튼 (입력창 + 취소 + 완료)
  Widget _buildEditModeButtons() {
    return Row(
      key: const ValueKey('edit'),
      children: [
        // 입력창
        Expanded(
          child: TextField(
            controller: _editController,
            decoration: InputDecoration(
              hintText: '수정 내용을 입력하세요',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.lightGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 취소 버튼 (X)
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.lightGrey,
          child: IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            onPressed: _toggleEditMode,
          ),
        ),
        const SizedBox(width: 8),
        // 완료 버튼 (✓)
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary,
          child: IconButton(
            icon: const Icon(Icons.check, size: 20),
            color: Colors.white,
            padding: EdgeInsets.zero,
            onPressed: () {
              final feedback = _editController.text.trim();
              if (feedback.isNotEmpty) {
                _regenerateStoryboard(feedback);
              } else {
                _toggleEditMode();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

