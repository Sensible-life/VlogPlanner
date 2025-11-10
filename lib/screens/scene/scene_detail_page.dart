import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/cue_card.dart';
import '../../models/plan.dart';
import '../../services/openai_service.dart';
import '../../services/vlog_data_service.dart';

class SceneDetailPage extends StatefulWidget {
  final List<dynamic> scenes; // Map 또는 CueCard 모두 허용
  final int initialIndex;

  const SceneDetailPage({
    super.key,
    required this.scenes,
    required this.initialIndex,
  });

  @override
  State<SceneDetailPage> createState() => _SceneDetailPageState();
}

class _SceneDetailPageState extends State<SceneDetailPage> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showProTips = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    
    // 속도 기반: 빠르게 스와이프하면 작은 거리여도 넘어감
    if (velocity < -100 && _currentIndex < widget.scenes.length - 1) {
      // 왼쪽으로 빠르게 스와이프 -> 다음 페이지
      _pageController.jumpToPage(_currentIndex + 1);
    } else if (velocity > 100 && _currentIndex > 0) {
      // 오른쪽으로 빠르게 스와이프 -> 이전 페이지
      _pageController.jumpToPage(_currentIndex - 1);
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
    return Scaffold(
      body: Stack(
        children: [
          // PageView로 좌우 스와이프 가능하게 구현
          GestureDetector(
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.scenes.length,
              physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildSceneDetail(context, widget.scenes[index]);
              },
            ),
          ),
          
          // 상단 뒤로가기 버튼과 페이지 인디케이터
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 뒤로가기 버튼
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // 페이지 인디케이터
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.scenes.length}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  // 씬 수정 다이얼로그 표시
  void _showEditDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    final currentScene = widget.scenes[_currentIndex];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '씬 수정',
          style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '현재 씬: ${currentScene is CueCard ? currentScene.title : currentScene['title']}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '수정하고 싶은 내용을 입력하세요\n예: "더 밝고 경쾌한 톤으로 변경", "음식 설명을 더 자세하게"',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.filmBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final feedback = feedbackController.text.trim();
              if (feedback.isNotEmpty) {
                Navigator.pop(context);
                _regenerateScene(feedback);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('수정하기'),
          ),
        ],
      ),
    );
  }

  // 씬 재생성 실행
  void _regenerateScene(String feedback) async {
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
                Text('씬을 재생성하고 있습니다...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // VlogDataService에서 필요한 데이터 가져오기
      final vlogService = VlogDataService();
      final plan = vlogService.plan;
      final cueCards = vlogService.cueCards;

      if (plan == null || cueCards == null) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('스토리보드 데이터를 찾을 수 없습니다')),
        );
        return;
      }

      // 현재 씬 가져오기
      final currentScene = widget.scenes[_currentIndex] as CueCard;

      // 씬 재생성
      final regeneratedScene = await OpenAIService.regenerateScene(
        originalScene: currentScene,
        userFeedback: feedback,
        plan: plan,
      );

      if (mounted) Navigator.pop(context); // 로딩 다이얼로그 닫기

      if (regeneratedScene != null) {
        // VlogDataService 업데이트
        vlogService.updateCueCard(_currentIndex, regeneratedScene);
        
        // 저장된 스토리보드도 업데이트
        vlogService.updateCurrentStoryboard();

        // UI 업데이트
        setState(() {
          widget.scenes[_currentIndex] = regeneratedScene;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('씬이 성공적으로 수정되었습니다')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('씬 수정에 실패했습니다')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  // 개별 씬 세부 정보를 빌드하는 메서드
  Widget _buildSceneDetail(BuildContext context, dynamic sceneData) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    // CueCard 타입인 경우와 Map 타입인 경우를 구분
    final bool isCueCard = sceneData is CueCard;
    final CueCard? cueCard = isCueCard ? sceneData : null;
    final Map<String, dynamic>? scene = isCueCard ? null : sceneData;
    
    return Stack(
      children: [
        // 배경 고정 이미지
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: screenHeight / 2,
          child: isCueCard && cueCard?.thumbnailUrl != null && cueCard!.thumbnailUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: cueCard.thumbnailUrl!,
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
                      child: Text(
                        '씬 ${_currentIndex + 1}',
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
              : Container(
                  color: AppColors.cardBackground,
                  child: Center(
                    child: isCueCard
                        ? Text(
                            '씬 ${_currentIndex + 1}',
                            style: AppTextStyles.heading1.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          )
                        : Icon(
                            scene?['thumbnail'] ?? Icons.movie,
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
                        isCueCard ? cueCard!.title : (scene?['title'] ?? '씬 제목'),
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isCueCard 
                            ? '${cueCard!.allocatedSec}초 | ${cueCard.trigger} | ${cueCard.targetAudience}'
                            : '${scene?['duration'] ?? '0분'} | ${scene?['location'] ?? '미정'} | ${scene?['people'] ?? '1명'}',
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
                      
                      // 촬영 세부 정보
                      if (isCueCard)
                        _buildCueCardInfo(cueCard!)
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: Column(
                            children: [
                              _buildInfoRow(Icons.timer, '촬영 시간', scene?['duration'] ?? '0분'),
                              Divider(color: AppColors.grey.withOpacity(0.3)),
                              _buildInfoRow(Icons.location_on, '촬영 장소', scene?['location'] ?? '미정'),
                              Divider(color: AppColors.grey.withOpacity(0.3)),
                              _buildInfoRow(Icons.people, '등장 인물', scene?['people'] ?? '1명'),
                              Divider(color: AppColors.grey.withOpacity(0.3)),
                              _buildInfoRow(Icons.camera_alt, '카메라 앵글', scene?['cameraAngle'] ?? '중간샷'),
                              Divider(color: AppColors.grey.withOpacity(0.3)),
                              _buildInfoRow(Icons.wb_sunny, '조명', scene?['lighting'] ?? '자연광'),
                              Divider(color: AppColors.grey.withOpacity(0.3)),
                            ],
                          ),
                        ),
                      
                      if (!isCueCard) ...[
                        const SizedBox(height: 40),
                        
                        // 씬 요약/추천 이유
                        _buildSectionTitle('씬 요약 / 추천 이유'),
                        _buildSectionContent(
                          scene?['summary'] ?? '씬에 대한 요약 정보가 없습니다.'
                        ),
                        
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: Divider(color: AppColors.grey.withOpacity(0.3)),
                        ),
                        const SizedBox(height: 16),
                        
                        // 대본 섹션 (매우 중요!)
                        _buildSectionTitle('대본'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              scene?['script'] ?? _getDefaultScript(scene?['title']),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.8,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 120),  // 하단 여백
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 큐카드 정보를 빌드하는 메서드
  Widget _buildCueCardInfo(CueCard cueCard) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요약
          if (cueCard.summary.isNotEmpty) ...[
            _buildSectionTitle('요약'),
            ...cueCard.summary.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                  Expanded(
                    child: Text(
                      s,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 20),
          ],
          
          // 스텝
          if (cueCard.steps.isNotEmpty) ...[
            _buildSectionTitle('촬영 스텝'),
            ...cueCard.steps.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 20),
          ],
          
          // 체크리스트
          if (cueCard.checklist.isNotEmpty) ...[
            _buildSectionTitle('촬영 전 체크'),
            ...cueCard.checklist.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 20),
          ],
          
          // 힌트
          _buildSectionTitle('촬영 힌트'),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cueCard.startHint.isNotEmpty)
                  _buildHintRow('▶ 시작', cueCard.startHint),
                if (cueCard.stopHint.isNotEmpty)
                  _buildHintRow('⏹ 정지', cueCard.stopHint),
                if (cueCard.completionCriteria.isNotEmpty)
                  _buildHintRow('🎯 완료', cueCard.completionCriteria),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // 대본
          if (cueCard.script.isNotEmpty) ...[
            _buildSectionTitle('촬영 대본'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  cueCard.script,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.8,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // 대안
          if (cueCard.fallback.isNotEmpty) ...[
            _buildSectionTitle('촬영이 어려울 때'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                cueCard.fallback,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Pro 팁
          if (cueCard.pro != null) ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  _showProTips = !_showProTips;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '💡 Pro 팁 보기',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      _showProTips ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            if (_showProTips) ...[
              const SizedBox(height: 16),
              _buildProTipsSection(cueCard.pro!),
            ],
          ],
        ],
      ),
    );
  }
  
  Widget _buildHintRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProTipsSection(CueCardPro pro) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pro.framing.isNotEmpty) ...[
            Text(
              '📷 촬영 (Pro)',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...pro.framing.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text('• $f', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
            )),
            const SizedBox(height: 12),
          ],
          if (pro.audio.isNotEmpty) ...[
            Text(
              '🎤 오디오 (Pro)',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...pro.audio.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text('• $a', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
            )),
            const SizedBox(height: 12),
          ],
          if (pro.dialogue.isNotEmpty) ...[
            Text(
              '💬 대화/나레이션',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...pro.dialogue.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text('• "$d"', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontStyle: FontStyle.italic)),
            )),
            const SizedBox(height: 12),
          ],
          if (pro.editHint.isNotEmpty) ...[
            Text(
              '✂️ 편집 힌트',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...pro.editHint.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text('• $e', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
            )),
            const SizedBox(height: 12),
          ],
          if (pro.safety.isNotEmpty) ...[
            Text(
              '⚠️ 안전/권한',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...pro.safety.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text('• $s', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
            )),
            const SizedBox(height: 12),
          ],
          if (pro.broll.isNotEmpty) ...[
            Text(
              '🎬 B-roll 제안',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...pro.broll.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text('• $b', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
            )),
          ],
        ],
      ),
    );
  }
  
  // 기본 대본 생성 함수
  String _getDefaultScript(String? title) {
    switch (title) {
      case '카페 입구에서 만남':
        return '''[씬 1: 카페 입구]

나레이션: "오늘은 친구들이랑 오랜만에 만나는 날!"

주인공: (카페 입구에 도착하며) "안녕! 오랜만이다!"
친구1: "어! 왔어? 진짜 오랜만이네!"
친구2: "벌써 두 달 만인 것 같아. 어서 들어가자!"

주인공: (카메라를 향해) "오늘 여기 분위기가 정말 좋대요. 같이 들어가 볼게요!"''';

      case '자리 잡고 메뉴 선택':
        return '''[씬 2: 카페 내부 테이블]

친구1: "여기 자리 괜찮다! 창가 쪽이네."
주인공: (메뉴판을 펼치며) "우와, 메뉴가 진짜 많다. 뭐 먹을까?"

친구2: "나는 아메리카노랑 케이크 먹을래."
주인공: "나도 비슷한 거 먹어야지. 오늘 신메뉴도 있네?"

나레이션: "메뉴 고르는 재미도 쏠쏠하네요~"''';

      case '주문 및 대화':
        return '''[씬 3: 주문 후 대화]

주인공: (직원에게) "아메리카노 두 잔이랑 카페라떼 하나, 티라미수 케이크 주세요!"
직원: "네, 알겠습니다!"

친구1: "그래, 요즘 어떻게 지내?"
주인공: "나? 요즘 프로젝트 때문에 바빴어. 너는?"
친구2: "나도 비슷해. 근데 오늘 이렇게 나오니까 진짜 좋다!"

주인공: (카메라를 향해) "역시 친구들이랑 있으면 힐링이에요."''';

      default:
        return '''[대본]

나레이션: "${title ?? '이 씬'}에 대한 상세 대본입니다."

등장인물: "대사 내용이 여기에 들어갑니다."
등장인물2: "자연스러운 대화를 이어가세요."

나레이션: "각 씬의 목적에 맞게 대본을 작성하세요."''';
    }
  }
}

