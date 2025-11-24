import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../ui/styles.dart';
import '../../services/vlog_data_service.dart';
import '../storyboard/storyboard_page.dart';
import '../user_input/user_input_page.dart';

class UserDrawer extends StatefulWidget {
  final VoidCallback? onClose;
  
  const UserDrawer({super.key, this.onClose});

  // 커스텀 페이지 전환 애니메이션 (home_page에서 사용)
  static Route<void> route() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return _UserDrawerPage();
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // 오른쪽에서 시작
        const end = Offset.zero; // 원래 위치
        const curve = Curves.easeInOut;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  State<UserDrawer> createState() => _UserDrawerState();
}

// home_page에서 route()로 사용할 때를 위한 페이지 위젯
class _UserDrawerPage extends StatefulWidget {
  @override
  State<_UserDrawerPage> createState() => _UserDrawerPageState();
}

class _UserDrawerPageState extends State<_UserDrawerPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // 페이지가 열릴 때 drawer를 자동으로 열기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState?.openDrawer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false, // 키보드 나타날 때 불필요한 리렌더링 방지
      drawer: const UserDrawer(),
      body: Container(
        color: const Color(0xFFCEDCD3),
      ),
      onDrawerChanged: (isOpened) {
        if (!isOpened) {
          Navigator.pop(context);
        }
      },
    );
  }
}

class _UserDrawerState extends State<UserDrawer> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // 원래 디자인: 287px / 402px = 0.714
    final drawerWidth = screenWidth * 0.714;
    // 오른쪽 테두리: 6px / 402px = 0.015
    final rightBorderWidth = screenWidth * 0.015;
    
    return Drawer(
      width: drawerWidth,
      backgroundColor: const Color(0xFFCEDCD3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // 둥근 모서리 제거
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: const Color(0xFF1A1A1A),
              width: rightBorderWidth,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 검색창
              _buildSearchBar(context),

              // 스토리보드 리스트
              Expanded(
                child: _buildStoryboardList(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 검색창
  Widget _buildSearchBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // 원래 디자인 기준: 257px / 402px = 0.639, 47px / 904px = 0.052
    final searchWidth = screenWidth * 0.639;
    final searchHeight = screenHeight * 0.052;
    // 패딩: 12px / 402px = 0.03, 23px / 904px = 0.025, 16px / 904px = 0.018
    final horizontalPadding = screenWidth * 0.03;
    final topPadding = screenHeight * 0.025;
    final bottomPadding = screenHeight * 0.018;
    // 폰트 크기: 16px / 402px = 0.04
    final fontSize = screenWidth * 0.04;
    // 아이콘 크기: 20px / 402px = 0.05
    final iconSize = screenWidth * 0.05;
    // 테두리: 3px / 402px = 0.0075, 6px / 402px = 0.015
    final borderWidth = screenWidth * 0.0075;
    final borderWidthBottom = screenWidth * 0.015;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, topPadding, horizontalPadding, bottomPadding),
      child: Container(
        width: searchWidth,
        height: searchHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: const Color(0xFF1A1A1A), width: borderWidth),
            bottom: BorderSide(color: const Color(0xFF1A1A1A), width: borderWidthBottom),
            right: BorderSide(color: const Color(0xFF1A1A1A), width: borderWidthBottom),
            top: BorderSide(color: const Color(0xFF1A1A1A), width: borderWidth),
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: '검색...',
            hintStyle: TextStyle(
              fontFamily: 'Tmoney RoundWind',
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFB2B2B2),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.fromLTRB(
              screenWidth * 0.04,
              screenHeight * 0.002, // 위에 3 마진 추가
              screenWidth * 0.04,
              screenHeight * 0.009,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: const Color(0xFF1A1A1A),
              size: iconSize,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: const Color(0xFF1A1A1A),
                      size: iconSize,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                : null,
          ),
          style: TextStyle(
            fontFamily: 'Tmoney RoundWind',
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }

  // 스토리보드 리스트
  Widget _buildStoryboardList(BuildContext context) {
    final dataService = VlogDataService();
    
    return StreamBuilder<List<SavedStoryboard>>(
      stream: dataService.getStoryboardsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF1A1A1A),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '스토리보드를 불러오는 중 오류가 발생했습니다',
                style: TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontSize: 14,
                  color: const Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final allStoryboards = snapshot.data ?? [];
        
        // 검색 필터링
        final filteredStoryboards = _searchQuery.isEmpty
            ? allStoryboards
            : allStoryboards.where((storyboard) {
                return storyboard.title.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

        if (filteredStoryboards.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _searchQuery.isEmpty
                    ? '저장된 스토리보드가 없습니다'
                    : '검색 결과가 없습니다',
                style: TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontSize: 14,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
          );
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        // 패딩: 12px / 402px = 0.03, 8px / 904px = 0.009
        final horizontalPadding = screenWidth * 0.03;
        final verticalPadding = screenHeight * 0.009;
        // 펀치 구멍 크기: 더 크게
        final holeDiameter = screenWidth * 0.03;
        final holeRadius = holeDiameter / 2;
        // 연결선 너비: 2배로
        final connectorWidth = screenWidth * 0.0075 * 2;
        // 카드 간격: 2/3로 줄임
        final cardSpacing = screenHeight * 0.04;

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          itemCount: filteredStoryboards.length,
          itemBuilder: (context, index) {
            final storyboard = filteredStoryboards[index];
            final isSelected = dataService.currentStoryboardId == storyboard.id;
            final isFirst = index == 0;
            final isLast = index == filteredStoryboards.length - 1;

            return Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // 카드
                    _buildStoryboardCard(
                      context: context,
                      storyboard: storyboard,
                      isSelected: isSelected,
                      dataService: dataService,
                    ),

                    // 상단 펀치 구멍 (첫 번째 카드 제외) - 카드 내부 깊숙이
                    if (!isFirst)
                      Positioned(
                        top: holeRadius * 2,
                        child: Container(
                          width: holeDiameter,
                          height: holeDiameter,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                    // 하단 펀치 구멍 (마지막 카드 제외) - 카드 내부 깊숙이
                    if (!isLast)
                      Positioned(
                        bottom: holeRadius * 2,
                        child: Container(
                          width: holeDiameter,
                          height: holeDiameter,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                    // 이전 카드에서 오는 연결선 (첫 번째 카드 제외)
                    // 현재 카드 위에 렌더링되어 앞에 표시됨
                    if (!isFirst)
                      Positioned(
                        top: -(cardSpacing + holeRadius * 3),
                        child: Container(
                          width: connectorWidth,
                          height: cardSpacing + holeRadius * 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB2B2B2),
                            borderRadius: BorderRadius.circular(connectorWidth / 2),
                          ),
                        ),
                      ),
                  ],
                ),

                // 간격 유지
                if (!isLast)
                  SizedBox(height: cardSpacing),
              ],
            );
          },
        );
      },
    );
  }

  // 스토리보드 카드
  Widget _buildStoryboardCard({
    required BuildContext context,
    required SavedStoryboard storyboard,
    required bool isSelected,
    required VlogDataService dataService,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final duration = storyboard.plan.goalDurationMin;
    final sceneCount = storyboard.cueCards.length;
    final dateStr = _formatDate(storyboard.createdAt);
    
    // 원래 디자인 기준: 257px / 402px = 0.639, 207px / 904px = 0.229
    final cardWidth = screenWidth * 0.639;
    final cardHeight = screenHeight * 0.27; // 세로 사이즈 증가
    // 썸네일: 242px / 402px = 0.602, 127px / 904px = 0.140
    final thumbnailWidth = screenWidth * 0.602;
    final thumbnailHeight = screenHeight * 0.17; // 썸네일 높이도 증가
    // 마진: 7.5px / 402px = 0.019, 6px / 904px = 0.007
    final thumbnailMargin = screenWidth * 0.008; // 가로 패딩 감소
    final thumbnailTopMargin = screenHeight * 0.003; // 위 패딩 감소
    // 패딩: 12px / 402px = 0.03, 8px / 904px = 0.009
    final cardPadding = screenWidth * 0.03;
    final cardVerticalPadding = screenHeight * 0.009;
    // 테두리: 3px / 402px = 0.0075, 6px / 402px = 0.015
    final borderWidth = screenWidth * 0.0075;
    final borderWidthBottom = screenWidth * 0.015;
    // 폰트 크기: 20px / 402px = 0.05, 14px / 402px = 0.035
    final titleFontSize = screenWidth * 0.05;
    final metaFontSize = screenWidth * 0.035;
    // 진행 바: 6px / 904px = 0.007, 4px / 904px = 0.004
    final progressBarHeight = screenHeight * 0.007;
    final progressBarMargin = screenHeight * 0.004;
    // 아이콘 크기: 32px / 402px = 0.08
    final iconSize = screenWidth * 0.08;
    
    return GestureDetector(
      onTap: () {
        // 키보드 닫기
        FocusScope.of(context).unfocus();

        if (!isSelected) {
          dataService.loadStoryboard(storyboard.id);
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StoryboardPage()),
          );
        } else {
          Navigator.pop(context);
        }
        widget.onClose?.call();
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(15),
          border: Border(
            left: BorderSide(color: const Color(0xFF1A1A1A), width: borderWidth),
            bottom: BorderSide(color: const Color(0xFF1A1A1A), width: borderWidthBottom),
            right: BorderSide(color: const Color(0xFF1A1A1A), width: borderWidthBottom),
            top: BorderSide(color: const Color(0xFF1A1A1A), width: borderWidth),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일
            Container(
              width: thumbnailWidth,
              height: thumbnailHeight,
              margin: EdgeInsets.fromLTRB(
                thumbnailMargin,
                thumbnailTopMargin,
                thumbnailMargin, // 왼쪽과 동일한 패딩
                0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFB2B2B2),
              ),
              child: _buildThumbnailImage(
                storyboard.mainThumbnail ?? storyboard.plan.locationImage,
                iconSize,
              ),
            ),
            
            // 제목과 정보
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  cardPadding,
                  cardVerticalPadding,
                  cardPadding,
                  cardVerticalPadding * 1.8, // 아래 패딩 늘림
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

                    SizedBox(height: screenHeight * 0.008), // 제목과 정보 사이 간격

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
        ),
      ),
    );
  }

  // 날짜 포맷 헬퍼
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('yy.MM.dd').format(date);
    }
  }

  // 썸네일 이미지 빌더
  Widget _buildThumbnailImage(String? imageUrl, double iconSize) {
    // 빈 문자열이나 null 체크
    if (imageUrl == null || imageUrl.isEmpty) {
      return Center(
        child: Icon(
          Icons.movie_outlined,
          color: const Color(0xFFB2B2B2),
          size: iconSize,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
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
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: iconSize * 0.5,
              height: iconSize * 0.5,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
