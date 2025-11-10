import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../constants/app_colors.dart';
import '../../services/vlog_data_service.dart';
import '../../widgets/style_radar_chart.dart';
import '../scene/scene_list_page.dart';
import '../../models/cue_card.dart';

class StoryboardPage extends StatefulWidget {
  const StoryboardPage({super.key});

  @override
  State<StoryboardPage> createState() => _StoryboardPageState();
}

class _StoryboardPageState extends State<StoryboardPage> {
  final VlogDataService _dataService = VlogDataService();
  String _selectedTab = 'STRUCTURE'; // STRUCTURE or PRODUCTION
  Color _textColor = Colors.white; // 기본값은 흰색
  late PageController _pageController;
  int _selectedSceneIndex = 0; // 선택된 씬 인덱스

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _calculateTextColor();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 배경 이미지의 밝기를 계산하여 텍스트 색상 결정
  Future<void> _calculateTextColor() async {
    final plan = _dataService.plan;
    if (plan == null) return;

    final imageUrl = plan.locationImage ?? 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800';
    
    try {
      final imageProvider = CachedNetworkImageProvider(imageUrl);
      final imageStream = imageProvider.resolve(const ImageConfiguration());
      
      final completer = Completer<ui.Image>();
      imageStream.addListener(ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info.image);
      }));
      
      final image = await completer.future;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      
      if (byteData == null) return;
      
      final bytes = byteData.buffer.asUint8List();
      int totalR = 0, totalG = 0, totalB = 0;
      int pixelCount = 0;
      
      // 상단 30% 영역만 샘플링 (제목이 표시되는 영역)
      final samplingHeight = (image.height * 0.3).toInt();
      
      for (int y = 0; y < samplingHeight; y += 10) {
        for (int x = 0; x < image.width; x += 10) {
          final index = (y * image.width + x) * 4;
          if (index + 2 < bytes.length) {
            totalR += bytes[index];
            totalG += bytes[index + 1];
            totalB += bytes[index + 2];
            pixelCount++;
          }
        }
      }
      
      if (pixelCount > 0) {
        final avgR = totalR / pixelCount;
        final avgG = totalG / pixelCount;
        final avgB = totalB / pixelCount;
        
        // 밝기 계산 (0-255)
        final brightness = (avgR * 0.299 + avgG * 0.587 + avgB * 0.114);
        
        setState(() {
          // 밝기가 128 이상이면 검은색, 미만이면 흰색
          _textColor = brightness > 128 ? Colors.black : Colors.white;
        });
      }
    } catch (e) {
      print('이미지 밝기 계산 오류: $e');
      // 오류 발생 시 기본값(흰색) 유지
    }
  }

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
          // 배경 이미지
          Positioned.fill(
            child: _buildBackgroundImage(locationImage),
          ),
          
          // 메인 컨텐츠 - 하단 고정
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더 섹션 (제목 + 키워드) - 고정
                _buildHeaderSection(plan, userInput, keywords),
                
                // 탭 섹션 - 고정
                _buildTabSection(),
                
                // 컨텐츠 섹션 - PageView로 슬라이드 전환
                SizedBox(
                  height: _calculateStructureContentHeight(),
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedTab = index == 0 ? 'STRUCTURE' : 'PRODUCTION';
                      });
                    },
                    physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
                    children: [
                      // STRUCTURE 탭
                      _buildStructureContent(plan),
                      // PRODUCTION 탭
                      SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: _buildProductionContent(plan, cueCards),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 플로팅 액션 버튼 (촬영 시작) - 오른쪽 하단
          Positioned(
            right: 24,
            bottom: 40,
            child: _buildStartShootingButton(),
          ),
        ],
      ),
    );
  }

  // 배경 이미지 (그라데이션 포함)
  Widget _buildBackgroundImage(String imageUrl) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // 배경 이미지 (확대)
        Positioned(
          left: -200,
          right: -200,
          top: 0,
          height: screenHeight * 0.6,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[300]),
            errorWidget: (context, url, error) => Container(color: Colors.grey[300]),
          ),
        ),
        
                // 그라데이션 오버레이 (아래로 갈수록 검은색)
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: screenHeight * 0.6,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFC8C8C8).withOpacity(0.0),
                  Color(0xFFFFFFFF).withOpacity(1.0),
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 헤더 섹션 (제목 + 키워드)
  Widget _buildHeaderSection(Plan plan, Map<String, String> userInput, List<String> keywords) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 제목 (중앙 정렬)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 54),
            child: Text(
              plan.vlogTitle.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '').trim(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard Variable',
                fontWeight: FontWeight.w700,
                fontSize: 28,
                height: 1.2,
                color: _textColor,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 키워드 (4개, dot으로 구분)
          _buildKeywords(keywords, userInput),
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
    
    final timeWeather = userInput['time_weather'];
    final weatherParts = timeWeather?.split(',') ?? [];
    items.add(weatherParts.isNotEmpty ? weatherParts[0].trim() : '낮');
    items.add(weatherParts.length > 1 ? weatherParts[1].trim() : '맑음');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Text(
            items[i],
            style: TextStyle(
              fontFamily: 'Pretendard Variable',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: _textColor,
            ),
          ),
          if (i < items.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: _textColor,
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
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // 슬라이딩 하얀 배경
          AnimatedAlign(
            duration: const Duration(milliseconds: 200), // 300 -> 200으로 속도 증가
            curve: Curves.easeInOut,
            alignment: _selectedTab == 'STRUCTURE' ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: (MediaQuery.of(context).size.width - 48 - 13) / 2, // 전체 너비에서 margin과 padding 제외
              height: 37,
              margin: const EdgeInsets.all(6.5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          // 탭 버튼들
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedTab = 'STRUCTURE');
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      'STRUCTURE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: _selectedTab == 'STRUCTURE' ? Colors.black : const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedTab = 'PRODUCTION');
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      'PRODUCTION',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: _selectedTab == 'PRODUCTION' ? Colors.black : const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // STRUCTURE 컨텐츠
  Widget _buildStructureContent(Plan plan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // 시나리오 요약 제목
          const Text(
            '시나리오 요약',
            style: TextStyle(
              fontFamily: 'Pretendard Variable',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 시나리오 요약 내용
          Text(
            plan.summary,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 1.2,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 구분선
          Container(
            height: 1,
            color: AppColors.brandBlue,
          ),
          
          const SizedBox(height: 24),
          
          // 톤 & 분위기 제목 + 세부 내용 링크
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '톤 & 분위기',
                style: TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
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
                    decorationColor: AppColors.brandBlue,
                    color: AppColors.brandBlue,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 레이더 차트
          SizedBox(
            height: 190,
            child: StyleRadarChart(),
          ),
          
          const SizedBox(height: 32), // 버튼 공간 확보 (56 -> 32로 줄임)
        ],
      ),
    );
  }

  // STRUCTURE 컨텐츠 영역의 높이 계산
  double _calculateStructureContentHeight() {
    // 16 (상단) + 20 (제목 높이 추정) + 16 + 요약 (가변) + 24 + 1 (구분선) + 24 + 20 (톤&분위기 제목) + 24 + 190 (차트) + 56 (하단)
    // 대략적으로 고정 높이 합계: 16 + 16 + 24 + 1 + 24 + 24 + 190 + 56 = 351
    // 요약 텍스트는 평균 60px 정도로 가정
    return 430.0; // 약간 여유를 둔 높이
  }

  // PRODUCTION 컨텐츠 (촬영 동선, 예산, 체크리스트)
  Widget _buildProductionContent(Plan plan, List<CueCard> cueCards) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // 촬영 동선
          const Text(
            '촬영 동선',
            style: TextStyle(
              fontFamily: 'Pretendard Variable',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Google Maps
          _buildGoogleMap(plan),
          
          const SizedBox(height: 14),
          
          // 씬 선택 인디케이터
          _buildSceneIndicator(cueCards.length),
          
          const SizedBox(height: 14),
          
          // 선택된 씬의 위치 정보
          if (_selectedSceneIndex < cueCards.length)
            _buildSelectedSceneLocation(cueCards[_selectedSceneIndex]),
          
          const SizedBox(height: 24),
          
          // 구분선
          Container(
            height: 1,
            color: AppColors.brandBlue,
          ),
          
          const SizedBox(height: 24),
          
          // 예산
          const Text(
            '예산',
            style: TextStyle(
              fontFamily: 'Pretendard Variable',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 14),
          
          // 예산 항목
          if (plan.budget?.items != null)
            ...plan.budget!.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.brandBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.attach_money, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item.description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Text(
                    '${plan.budget!.currency} ${item.amount}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            )).toList(),
          
          const SizedBox(height: 8),
          
          // 합계
          if (plan.budget != null)
            Row(
              children: [
                const Text(
                  '합계',
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  '${plan.budget!.currency} ${plan.budget!.totalBudget}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 24),
          
          // 구분선
          Container(
            height: 1,
            color: AppColors.brandBlue,
          ),
          
          const SizedBox(height: 24),
          
          // 촬영 체크리스트
          const Text(
            '촬영 체크리스트',
            style: TextStyle(
              fontFamily: 'Pretendard Variable',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 14),
          
          // 체크리스트 항목
          if (plan.shootingChecklist != null)
            ...plan.shootingChecklist!.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: item.contains('✓') ? AppColors.brandBlue : const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.replaceAll('✓', '').trim(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          
          const SizedBox(height: 32), // 버튼 공간 확보
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
        icon: const Icon(Icons.play_arrow, color: Color(0xFFFFFFFF), size: 30),
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

  // Google Maps 위젯
  Widget _buildGoogleMap(Plan plan) {
    final locations = _dataService.getShootingLocations();
    
    if (locations.isEmpty) {
      return Container(
        height: 243,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                '촬영 장소 정보 없음',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 마커 생성
    final markers = locations.asMap().entries.map((entry) {
      int index = entry.key;
      final location = entry.value;
      
      return Marker(
        markerId: MarkerId('marker_${location.order}'),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: '${location.order}. ${location.name}',
          snippet: location.description,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          index == 0 
              ? BitmapDescriptor.hueGreen  // 시작점은 초록색
              : index == locations.length - 1
                  ? BitmapDescriptor.hueBlue  // 끝점은 파란색
                  : BitmapDescriptor.hueRed,  // 중간은 빨간색
        ),
      );
    }).toSet();

    // 폴리라인 생성
    final polylineCoordinates = locations
        .map((location) => LatLng(location.latitude, location.longitude))
        .toList();

    final polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: polylineCoordinates,
        color: AppColors.brandBlue,
        width: 4,
      ),
    };

    // 카메라 위치 (첫 번째 위치 중심)
    final cameraPosition = LatLng(
      locations.first.latitude,
      locations.first.longitude,
    );

    return Container(
      height: 243,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: cameraPosition,
          zoom: 15,
        ),
        markers: markers,
        polylines: polylines,
        mapType: MapType.normal,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: true,
        // 제스처 인식기 설정 - 지도가 터치를 우선적으로 처리
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(
            () => EagerGestureRecognizer(),
          ),
        },
      ),
    );
  }

  // 씬 인디케이터 (동그라미 + 라인)
  Widget _buildSceneIndicator(int sceneCount) {
    if (sceneCount == 0) return const SizedBox.shrink();
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 가로 라인
          Positioned(
            left: 20,
            right: 20,
            child: Container(
              height: 2,
              color: AppColors.brandBlue.withOpacity(0.3),
            ),
          ),
          // 동그라미들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(sceneCount, (index) {
              final isSelected = index == _selectedSceneIndex;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSceneIndex = index;
                  });
                },
                child: Container(
                  width: isSelected ? 16 : 12,
                  height: isSelected ? 16 : 12,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.brandGreen : AppColors.brandBlue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.brandGreen : AppColors.brandBlue,
                      width: isSelected ? 3 : 2,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // 선택된 씬의 위치 정보
  Widget _buildSelectedSceneLocation(CueCard cueCard) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.brandGreen,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 21,
            height: 21,
            decoration: const BoxDecoration(
              color: AppColors.brandGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${_selectedSceneIndex + 1}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cueCard.title,
                  style: const TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                if (cueCard.summary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      cueCard.summary.first,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
