import 'package:flutter/material.dart';
import '../ui/styles.dart';
import '../services/vlog_data_service.dart';
import 'user_input/user_input_page.dart';
import 'home/user_drawer.dart';
import 'home/user_info_page.dart';
import 'storyboard/storyboard_page.dart';
import 'camera/camera_mode_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  void initState() {
    super.initState();

    // 샘플 데이터 초기화
    VlogDataService().initializeSampleData();

    // Firestore에서 스토리보드 로드
    _loadStoryboards();
  }

  Future<void> _loadStoryboards() async {
    await VlogDataService().loadStoryboardsFromFirestore();
    // Firestore 로드 완료 후 UI 업데이트
    if (mounted) {
      setState(() {});
    }
  }

  void _navigateToStoryboard() {
    // 키보드 닫기
    FocusScope.of(context).unfocus();

    // 샘플 스토리보드 로드
    final storyboards = VlogDataService().getSavedStoryboards();
    if (storyboards.isNotEmpty) {
      VlogDataService().loadStoryboard(storyboards[0].id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const StoryboardPage(),
        ),
      );
    }
  }

  void _navigateToUserInput() {
    // 키보드 닫기
    FocusScope.of(context).unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserInputPage(),
      ),
    );
  }

  void _navigateToCamera() {
    // 키보드 닫기
    FocusScope.of(context).unfocus();

    // 샘플 스토리보드 로드 후 촬영 모드로 이동
    final storyboards = VlogDataService().getSavedStoryboards();
    if (storyboards.isNotEmpty) {
      VlogDataService().loadStoryboard(storyboards[0].id);
      final cueCards = VlogDataService().cueCards;
      if (cueCards != null && cueCards.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CameraModePage(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildMainContent();
  }

  Widget _buildMainContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFCEDCD3),
      resizeToAvoidBottomInset: false,
      drawer: const UserDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            // 왼쪽 상단 사이드바 버튼
            Positioned(
              left: 17,
              top: 23,
              child: GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Image.asset(
                  'assets/images/button_sidebar.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            // 오른쪽 상단 사용자 정보 버튼
            Positioned(
              right: 17,
              top: 23,
              child: GestureDetector(
                onTap: () {
                  // 키보드 닫기
                  FocusScope.of(context).unfocus();
                  
                  // 사용자 정보 페이지를 drawer로 표시
                  Navigator.push(
                    context,
                    UserInfoPage.route(),
                  );
                },
                child: Image.asset(
                  'assets/images/button_user.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            // 로고 (상단 바 아래 중앙)
            Positioned(
              top: 90, // 상단 버튼 아래 위치
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: screenWidth * 0.6, // 화면 너비의 60% (더 크게)
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            // 가장 최근 스토리보드 카드
            _buildRecentStoryboardCard(screenWidth, screenHeight),

            // 펀치 구멍과 연결선
            _buildPunchHolesAndConnectors(screenWidth, screenHeight),
            
            // 새 스토리보드 생성 버튼
            _buildNewStoryboardButton(screenWidth, screenHeight),
          ],
        ),
      ),
    );
  }

  // 펀치 구멍과 연결선
  Widget _buildPunchHolesAndConnectors(double screenWidth, double screenHeight) {
    // CSS 기준: 402px 기준으로 계산
    final baseWidth = 402.0;
    final baseHeight = 904.0;
    
    // 전체 오프셋: 카드 높이 감소(35px)만큼 아래로 내리기 (30px + 35px = 65px)
    final verticalOffset = 65.0 * (screenHeight / baseHeight);
    
    // 펀치 구멍 크기: 12px
    final holeDiameter = 12.0 * (screenWidth / baseWidth);
    final holeRadius = holeDiameter / 2;
    
    // 연결선 크기: 6px 너비, 78px 높이 -> 60px로 줄임
    final connectorWidth = 6.0 * (screenWidth / baseWidth);
    final connectorHeight = 60.0 * (screenHeight / baseHeight);
    
    // 펀치 구멍 위치 (calc(50% - 12px/2 ± 74px))
    final centerX = screenWidth / 2;
    final offsetX = 74.0 * (screenWidth / baseWidth);
    
    // 상단 펀치 구멍 위치: top: 369px -> 269px -> 299px
    final topHoleY = 269.0 * (screenHeight / baseHeight) + verticalOffset;
    // 하단 펀치 구멍 위치: top: 445.34px -> 345.34px -> 375.34px
    final bottomHoleY = 345.34 * (screenHeight / baseHeight) + verticalOffset;
    
    // 연결선 위치: left: 124px, 272px, top: 373px -> 273px -> 303px
    final connector1X = 124.0 * (screenWidth / baseWidth);
    final connector2X = 272.0 * (screenWidth / baseWidth);
    final connectorTopY = 273.0 * (screenHeight / baseHeight) + verticalOffset;
    
    return Stack(
      children: [
        // 왼쪽 상단 펀치 구멍
        Positioned(
          left: centerX - offsetX - holeRadius,
          top: topHoleY - holeRadius,
          child: Container(
            width: holeDiameter,
            height: holeDiameter,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        // 왼쪽 하단 펀치 구멍
        Positioned(
          left: centerX - offsetX - holeRadius,
          top: bottomHoleY - holeRadius,
          child: Container(
            width: holeDiameter,
            height: holeDiameter,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        // 오른쪽 상단 펀치 구멍
        Positioned(
          left: centerX + offsetX - holeRadius,
          top: topHoleY - holeRadius,
          child: Container(
            width: holeDiameter,
            height: holeDiameter,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        // 오른쪽 하단 펀치 구멍
        Positioned(
          left: centerX + offsetX - holeRadius,
          top: bottomHoleY - holeRadius,
          child: Container(
            width: holeDiameter,
            height: holeDiameter,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        // 왼쪽 연결선
        Positioned(
          left: connector1X - connectorWidth / 2 + holeDiameter / 4,
          top: connectorTopY - holeDiameter / 3,
          child: Container(
            width: connectorWidth,
            height: connectorHeight + holeDiameter * 1.5,
            decoration: BoxDecoration(
              color: const Color(0xFFB2B2B2),
              borderRadius: BorderRadius.circular(connectorWidth / 2),
            ),
          ),
        ),
        
        // 오른쪽 연결선
        Positioned(
          left: connector2X - connectorWidth / 2 + holeDiameter / 4,
          top: connectorTopY - holeDiameter / 3,
          child: Container(
            width: connectorWidth,
            height: connectorHeight + holeDiameter * 1.5,
            decoration: BoxDecoration(
              color: const Color(0xFFB2B2B2),
              borderRadius: BorderRadius.circular(connectorWidth / 2),
            ),
          ),
        ),
      ],
    );
  }

  // 가장 최근 스토리보드 카드
  Widget _buildRecentStoryboardCard(double screenWidth, double screenHeight) {
    final baseWidth = 402.0;
    final baseHeight = 904.0;
    final dataService = VlogDataService();
    
    // 전체 오프셋: 카드 높이 감소(35px)만큼 아래로 내리기 (30px + 35px = 65px)
    final verticalOffset = 65.0 * (screenHeight / baseHeight);
    
    // 카드 크기: 371px 너비
    final cardWidth = 371.0 * (screenWidth / baseWidth);
    final cardTopHeight = 71.0 * (screenHeight / baseHeight); // 상단 카드
    final cardBottomHeight = 315.0 * (screenHeight / baseHeight); // 하단 카드 높이 조정: 350 -> 310
    
    // 카드 위치
    final cardLeft = (screenWidth - cardWidth) / 2;
    final cardTopY = 224.0 * (screenHeight / baseHeight) + verticalOffset; // 상단 카드: 324 -> 224 -> 254
    final cardBottomY = 333.0 * (screenHeight / baseHeight) + verticalOffset; // 하단 카드: 433 -> 333 -> 363
    
    // StreamBuilder로 실시간 업데이트
    return StreamBuilder<List<SavedStoryboard>>(
      stream: dataService.getStoryboardsStream(),
      builder: (context, snapshot) {
        // 최근 스토리보드 가져오기 (생성일 기준 내림차순 정렬, 샘플 데이터 제외)
        final allStoryboards = snapshot.hasData 
            ? snapshot.data! 
            : List<SavedStoryboard>.from(dataService.getSavedStoryboards());
        // 샘플 데이터 제외 (id가 'sample_'로 시작하는 것들)
        final userStoryboards = allStoryboards.where((sb) => !sb.id.startsWith('sample_')).toList();
        userStoryboards.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 최신순 정렬
        final recentStoryboard = userStoryboards.isNotEmpty ? userStoryboards[0] : null;
    
    return Stack(
      children: [
        // 상단 카드 (제목 영역)
        Positioned(
          left: cardLeft,
          top: cardTopY,
      child: Container(
        width: cardWidth,
            height: cardTopHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFEFA),
              borderRadius: BorderRadius.circular(15),
              border: const Border(
                left: BorderSide(color: Color(0xFF303030), width: 3),
                top: BorderSide(color: Color(0xFF303030), width: 3),
                right: BorderSide(color: Color(0xFF303030), width: 6),
                bottom: BorderSide(color: Color(0xFF303030), width: 6),
              ),
            ),
          ),
        ),
        
        // 하단 카드 (메인 카드)
        Positioned(
          left: cardLeft,
          top: cardBottomY,
          child: GestureDetector(
            onTap: recentStoryboard != null ? () {
              // 키보드 닫기
              FocusScope.of(context).unfocus();

              VlogDataService().loadStoryboard(recentStoryboard.id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StoryboardPage(),
                ),
              );
            } : null,
                child: Container(
              width: cardWidth,
              height: cardBottomHeight,
                  decoration: BoxDecoration(
                color: const Color(0xFFFFFEFA),
                borderRadius: BorderRadius.circular(15),
                border: const Border(
                  left: BorderSide(color: Color(0xFF303030), width: 3),
                  top: BorderSide(color: Color(0xFF303030), width: 3),
                  right: BorderSide(color: Color(0xFF303030), width: 6),
                  bottom: BorderSide(color: Color(0xFF303030), width: 6),
                ),
              ),
              child: recentStoryboard != null
                  ? _buildStoryboardCardContent(recentStoryboard, cardWidth, cardBottomHeight, screenWidth, screenHeight)
                  : const Center(
                      child: Text(
                        '스토리보드가 없습니다',
                        style: TextStyle(
                          fontFamily: 'Tmoney RoundWind',
                          color: Color(0xFF303030),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
      },
    );
  }

  // 스토리보드 카드 내용
  Widget _buildStoryboardCardContent(SavedStoryboard storyboard, double cardWidth, double cardHeight, double screenWidth, double screenHeight) {
    final duration = storyboard.plan.goalDurationMin;
    final sceneCount = storyboard.cueCards.length;
    final dateStr = _formatDate(storyboard.createdAt);
    
    // 마진: 7.5px / 402px = 0.019, 6px / 904px = 0.007
    final thumbnailMargin = screenWidth * 0.008;
    final thumbnailTopMargin = screenHeight * 0.003;
    
    // 썸네일 너비: 카드 너비에서 좌우 마진을 뺀 값
    final thumbnailWidth = cardWidth - (thumbnailMargin * 2);
    // 썸네일 높이: user_drawer 비율 유지 (너비 * 0.282 = 높이, 원래 242:127 비율)
    final thumbnailHeight = thumbnailWidth * (127.0 / 242.0);
    // 패딩: 12px / 402px = 0.03, 8px / 904px = 0.009
    final cardPadding = screenWidth * 0.03;
    final cardVerticalPadding = screenHeight * 0.009;
    // 폰트 크기: 20px / 402px = 0.05, 14px / 402px = 0.035
    final titleFontSize = screenWidth * 0.05;
    final metaFontSize = screenWidth * 0.045;
    // 아이콘 크기: 32px / 402px = 0.08
    final iconSize = screenWidth * 0.08;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 썸네일
        Container(
          width: thumbnailWidth,
          height: thumbnailHeight,
          margin: EdgeInsets.fromLTRB(
            thumbnailMargin,
            thumbnailTopMargin,
            thumbnailMargin,
            0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFB2B2B2),
          ),
          child: (storyboard.mainThumbnail != null || storyboard.plan.locationImage != null)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    storyboard.mainThumbnail ?? storyboard.plan.locationImage ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: const Color(0xFFB2B2B2),
                          size: iconSize,
                        ),
                      );
                    },
                  ),
                )
              : Center(
                    child: Icon(
                      Icons.movie_outlined,
                    color: const Color(0xFFB2B2B2),
                    size: iconSize,
                  ),
                ),
              ),
              
        // 제목과 정보
              Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              cardPadding,
              cardVerticalPadding * 2.5, // 썸네일과 제목 사이 간격 증가
              cardPadding,
              cardVerticalPadding * 1.8,
            ),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                Text(
                  storyboard.title,
                  style: TextStyle(
                    fontFamily: 'Tmoney RoundWind',
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: screenHeight * 0.024),
                
                // 날짜와 시간/씬 정보
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 날짜
                        Text(
                      dateStr,
                      style: TextStyle(
                        fontFamily: 'Tmoney RoundWind',
                        fontSize: metaFontSize,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFB2B2B2),
                        height: 1.29,
                      ),
                    ),
                    // 시간/씬 정보
                    Text(
                      '$duration분 | ${sceneCount}씬',
                      style: TextStyle(
                        fontFamily: 'Tmoney RoundWind',
                        fontSize: metaFontSize,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFB2B2B2),
                        height: 1.29,
                      ),
                    ),
                  ],
              ),
            ],
          ),
        ),
      ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().substring(2)}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // 새 스토리보드 생성 버튼
  Widget _buildNewStoryboardButton(double screenWidth, double screenHeight) {
    final baseWidth = 402.0;
    final baseHeight = 904.0;
    
    // 버튼 크기: 371px 너비, 84px 높이
    final buttonWidth = 371.0 * (screenWidth / baseWidth);
    final buttonHeight = 84.0 * (screenHeight / baseHeight);
    
    // 버튼 위치: left: 15px, top: 794px -> 650px -> 750px (원래 위치 유지)
    final buttonLeft = 15.0 * (screenWidth / baseWidth);
    final buttonTop = 750.0 * (screenHeight / baseHeight);
    
    // 하단 마진: 30px
    final bottomMargin = 30.0 * (screenHeight / baseHeight);
    
    return Positioned(
      left: buttonLeft,
      top: buttonTop,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomMargin),
        child: GestureDetector(
      onTap: _navigateToUserInput,
      child: Container(
        width: buttonWidth,
        height: buttonHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF455D75),
            borderRadius: BorderRadius.circular(10),
            border: const Border(
              left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
              top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
              right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
              bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
          ),
        ),
        child: Center(
          child: Text(
              '+ 스토리보드 생성',
              style: TextStyle(
                fontFamily: 'Tmoney RoundWind',
                fontWeight: FontWeight.w800,
                fontSize: 24,
                height: 36 / 28,
                color: const Color(0xFFFAFAFA),
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}

