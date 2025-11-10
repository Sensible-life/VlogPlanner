import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../services/vlog_data_service.dart';
import '../../widgets/style_radar_chart.dart';
import '../scene/scene_list_page.dart';

class StoryboardPageNew extends StatefulWidget {
  const StoryboardPageNew({super.key});

  @override
  State<StoryboardPageNew> createState() => _StoryboardPageNewState();
}

class _StoryboardPageNewState extends State<StoryboardPageNew> {
  final VlogDataService _dataService = VlogDataService();
  String _selectedTab = 'STRUCTURE'; // STRUCTURE or PRODUCTION

  @override
  Widget build(BuildContext context) {
    final plan = _dataService.plan;
    final cueCards = _dataService.cueCards;
    final userInput = _dataService.userInput;

    if (plan == null || cueCards == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('스토리보드')),
        body: const Center(child: Text('스토리보드 데이터를 불러올 수 없습니다')),
      );
    }

    final locationImage = plan.locationImage ?? 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800';
    final keywords = plan.keywords.take(4).toList();

    return Scaffold(
      body: Stack(
        children: [
          // 메인 스크롤 컨텐츠
          CustomScrollView(
            slivers: [
              // 헤더 이미지 섹션
              SliverToBoxAdapter(
                child: _buildHeaderSection(locationImage, plan, userInput, keywords),
              ),
              
              // 탭 섹션 (STRUCTURE / PRODUCTION)
              SliverToBoxAdapter(
                child: _buildTabSection(),
              ),
              
              // 컨텐츠 섹션
              SliverToBoxAdapter(
                child: _selectedTab == 'STRUCTURE'
                    ? _buildStructureContent(plan)
                    : _buildProductionContent(),
              ),
            ],
          ),
          
          // 플로팅 액션 버튼 (촬영 시작)
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(
              child: _buildStartShootingButton(),
            ),
          ),
        ],
      ),
    );
  }

  // 헤더 이미지 섹션
  Widget _buildHeaderSection(String imageUrl, Plan plan, Map<String, String> userInput, List<String> keywords) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 2 / 3;

    return SizedBox(
      height: imageHeight,
      child: Stack(
        children: [
          // 배경 이미지 (확대)
          Positioned(
            left: -200,
            right: -200,
            top: 0,
            height: imageHeight,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[300]),
              errorWidget: (context, url, error) => Container(color: Colors.grey[300]),
            ),
          ),
          
          // 그라데이션 오버레이
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: imageHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.3),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),
          
          // 뒤로가기 버튼
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // 제목 (중앙 정렬)
          Positioned(
            left: 54,
            right: 54,
            top: imageHeight * 0.36,
            child: Text(
              plan.vlogTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Pretendard Variable',
                fontWeight: FontWeight.w600,
                fontSize: 32,
                height: 1.2,
                color: Colors.white,
              ),
            ),
          ),
          
          // 키워드 (4개, dot으로 구분)
          Positioned(
            left: 0,
            right: 0,
            top: imageHeight * 0.54,
            child: _buildKeywords(keywords, userInput),
          ),
        ],
      ),
    );
  }

  // 키워드 섹션
  Widget _buildKeywords(List<String> keywords, Map<String, String> userInput) {
    final items = <String>[];
    
    // 최대 4개 항목
    if (keywords.isNotEmpty) items.add(keywords[0]);
    items.add(userInput['target_duration'] != null ? '${userInput['target_duration']}분' : '10분');
    items.add(userInput['time_weather']?.split(',')[0].trim() ?? '낮');
    items.add(userInput['time_weather']?.split(',').length > 1 
        ? userInput['time_weather']!.split(',')[1].trim() 
        : '맑음');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Text(
            items[i],
            style: const TextStyle(
              fontFamily: 'Pretendard Variable',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          if (i < items.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ],
    );
  }

  // 탭 섹션 (STRUCTURE / PRODUCTION)
  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 'STRUCTURE'),
              child: Container(
                margin: const EdgeInsets.all(6.5),
                decoration: BoxDecoration(
                  color: _selectedTab == 'STRUCTURE' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  'STRUCTURE',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: _selectedTab == 'STRUCTURE' ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 'PRODUCTION'),
              child: Container(
                margin: const EdgeInsets.all(6.5),
                decoration: BoxDecoration(
                  color: _selectedTab == 'PRODUCTION' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  'PRODUCTION',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: _selectedTab == 'PRODUCTION' ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STRUCTURE 컨텐츠
  Widget _buildStructureContent(Plan plan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // 시나리오 요약 제목
          const Text(
            '시나리오 요약',
            style: TextStyle(
              fontFamily: 'Pretendard Variable',
              fontWeight: FontWeight.w600,
              fontSize: 24,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 15),
          
          // 시나리오 요약 내용
          Text(
            plan.summary,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 1.25,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // 구분선
          Container(
            height: 1,
            color: AppColors.brandBlue,
          ),
          
          const SizedBox(height: 30),
          
          // 톤 & 분위기 제목 + 세부 내용 링크
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '톤 & 분위기',
                style: TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () => _showToneDetailDialog(),
                child: const Text(
                  '세부 내용',
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    color: AppColors.brandBlue,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 레이더 차트
          SizedBox(
            height: 300,
            child: StyleRadarChart(),
          ),
          
          const SizedBox(height: 120), // 버튼 공간 확보
        ],
      ),
    );
  }

  // PRODUCTION 컨텐츠 (씬 리스트)
  Widget _buildProductionContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          const Text(
            'PRODUCTION 탭은 씬 리스트를 보여줍니다',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SceneListPage()),
              );
            },
            child: const Text('씬 리스트 보기'),
          ),
          const SizedBox(height: 120), // 버튼 공간 확보
        ],
      ),
    );
  }

  // 촬영 시작 버튼
  Widget _buildStartShootingButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -0.9),
          end: Alignment(0.5, 0.9),
          colors: [Color(0xFF1DBBB1), Color(0xFF64BF79)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SceneListPage()),
          );
        },
      ),
    );
  }

  // 톤 & 분위기 세부 내용 다이얼로그
  void _showToneDetailDialog() {
    final plan = _dataService.plan;
    if (plan?.styleAnalysis == null) return;

    final style = plan!.styleAnalysis!;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '톤 & 분위기 세부 내용',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem('톤', style.tone),
                      _buildDetailItem('분위기', style.vibe),
                      _buildDetailItem('페이싱', style.pacing),
                      _buildDetailItem('시각 스타일', style.visualStyle.join(', ')),
                      _buildDetailItem('오디오 스타일', style.audioStyle.join(', ')),
                      const SizedBox(height: 20),
                      const Text(
                        '레이더 차트 점수',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildScoreItem('감정 표현', style.emotionalExpression),
                      _buildScoreItem('동작', style.movement),
                      _buildScoreItem('강도', style.intensity),
                      _buildScoreItem('장소 다양성', style.locationDiversity),
                      _buildScoreItem('속도/리듬', style.speedRhythm),
                      _buildScoreItem('흥분/놀람', style.excitementSurprise),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, int score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              for (int i = 0; i < 5; i++)
                Icon(
                  i < score ? Icons.star : Icons.star_border,
                  size: 16,
                  color: AppColors.brandBlue,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
