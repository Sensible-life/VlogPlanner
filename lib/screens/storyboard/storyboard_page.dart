import 'package:flutter/material.dart';
import '../../services/vlog_data_service.dart';
import '../../services/storyboard_generation_service.dart';
import '../../widgets/app_notification.dart';
import '../../ui/styles.dart';
import '../scene/scene_list_page.dart';
import '../home/user_drawer.dart';
import '../home_page.dart';
import 'tabs/summary_tab.dart';
import 'tabs/shooting_tab.dart';
import 'tabs/budget_tab.dart';
import 'tabs/direction_tab.dart';
import 'tabs/etc_tab.dart';

class StoryboardPage extends StatefulWidget {
  const StoryboardPage({super.key});

  @override
  State<StoryboardPage> createState() => _StoryboardPageState();
}

class _StoryboardPageState extends State<StoryboardPage> {
  final VlogDataService _dataService = VlogDataService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTab = 0;
  
  // 입력창 관련
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isInputExpanded = false;
  double _previousKeyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    _precacheImages();
    _inputFocusNode.addListener(_onFocusChanged);
    _inputController.addListener(_onInputChanged);
  }
  
  @override
  void dispose() {
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    _inputFocusNode.removeListener(_onFocusChanged);
    _inputFocusNode.dispose();
    super.dispose();
  }
  
  // 포커스 변경 감지
  void _onFocusChanged() {
    setState(() {
      // 포커스가 있으면 확장, 없으면 한 줄로 축소
      _isInputExpanded = _inputFocusNode.hasFocus;
    });
  }
  
  // 입력 변경 감지 (X 버튼 상태 업데이트용)
  void _onInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  
  // 수정 사항 전송 처리
  Future<void> _handleSendModification() async {
    final modificationText = _inputController.text.trim();
    
    if (modificationText.isEmpty) {
      AppNotification.show(
        context,
        '수정 내용을 입력해주세요.',
        type: NotificationType.warning,
      );
      return;
    }
    
    final plan = _dataService.plan;
    final cueCards = _dataService.cueCards;
    
    if (plan == null || cueCards == null) {
      AppNotification.show(
        context,
        '스토리보드 데이터를 불러올 수 없습니다.',
        type: NotificationType.error,
      );
      return;
    }
    
    try {
      // 현재 스토리보드 데이터 준비
      final currentStoryboard = {
        'plan': plan.toJson(),
        'scenes': cueCards.map((c) => c.toJson()).toList(),
        'user_input': _dataService.userInput,
      };
      
      // StoryboardGenerationService를 사용하여 스토리보드 수정
      final result = await StoryboardGenerationService.modifyStoryboard(
        currentStoryboard: currentStoryboard,
        modificationRequest: modificationText,
        dataService: _dataService,
      );
      
      if (result == null) {
        AppNotification.show(
          context,
          '스토리보드 수정에 실패했습니다.\nAPI 키를 확인하거나 네트워크 연결을 확인해주세요.',
          type: NotificationType.error,
        );
        return;
      }
      
      // 입력창 초기화
      _inputController.clear();
      _inputFocusNode.unfocus();
      
      if (mounted) {
        setState(() {
          _isInputExpanded = false;
        });
        
        AppNotification.show(
          context,
          '스토리보드가 성공적으로 수정되었습니다!',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      print('[STORYBOARD] 스토리보드 수정 오류: $e');
      if (mounted) {
        AppNotification.show(
          context,
          '스토리보드 수정 중 오류가 발생했습니다: ${e.toString()}',
          type: NotificationType.error,
        );
      }
    }
  }

  // 이미지 미리 캐싱
  void _precacheImages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 탭 선택 이미지
      precacheImage(const AssetImage('assets/images/tab_selection.png'), context);
      
      // 버튼 이미지
      precacheImage(const AssetImage('assets/images/button_sidebar.png'), context);
      precacheImage(const AssetImage('assets/images/button_scenelist.png'), context);
      
      // 세부 정보 아이콘들
      precacheImage(const AssetImage('assets/icons/icon_clock.png'), context);
      precacheImage(const AssetImage('assets/icons/icon_camera.png'), context);
      precacheImage(const AssetImage('assets/icons/icon_people.png'), context);
      precacheImage(const AssetImage('assets/icons/icon_pallette.png'), context);
      precacheImage(const AssetImage('assets/icons/icon_scenes.png'), context);
      precacheImage(const AssetImage('assets/icons/icon_money.png'), context);
      
      // DALL-E 생성 이미지 미리 캐싱
      _precacheStoryboardImages();
    });
  }

  // DALL-E 생성 스토리보드 이미지 미리 캐싱
  void _precacheStoryboardImages() {
    final cueCards = _dataService.cueCards;
    if (cueCards == null || cueCards.isEmpty) return;

    print('[STORYBOARD] DALL-E 이미지 캐싱 시작: ${cueCards.length}개 씬');
    
    for (final cueCard in cueCards) {
      if (cueCard.storyboardImageUrl != null && 
          cueCard.storyboardImageUrl!.isNotEmpty) {
        try {
          precacheImage(
            NetworkImage(cueCard.storyboardImageUrl!),
            context,
          ).then((_) {
            print('[STORYBOARD] 이미지 캐싱 완료: ${cueCard.storyboardImageUrl}');
          }).catchError((error) {
            print('[STORYBOARD] 이미지 캐싱 실패: ${cueCard.storyboardImageUrl}, 오류: $error');
          });
        } catch (e) {
          print('[STORYBOARD] 이미지 캐싱 예외: ${cueCard.storyboardImageUrl}, 오류: $e');
        }
      }
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final plan = _dataService.plan;
    final cueCards = _dataService.cueCards;

    if (plan == null || cueCards == null) {
      return const Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Center(child: Text('스토리보드 데이터를 불러올 수 없습니다')),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 키보드 높이 변화 감지를 별도로 처리하여 리빌드 최소화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      // 키보드가 내려갔을 때 포커스 해제
      if (_previousKeyboardHeight > 0 && keyboardHeight == 0) {
        if (mounted && _inputFocusNode.hasFocus) {
          _inputFocusNode.unfocus();
        }
      }
      if (mounted) {
        _previousKeyboardHeight = keyboardHeight;
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFCEDCD3),
      resizeToAvoidBottomInset: true, // 키보드 나타날 때 레이아웃 리사이즈 허용
      drawer: const UserDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더 바
            _buildTopBar(context, screenWidth),
            SizedBox(height: screenHeight * 0.01),
            // 탭 바
            _buildTabBar(screenWidth, screenHeight),
            SizedBox(height: AppDims.marginContentToSubtitle(screenHeight)),
            // PageView로 탭 전환 (시나리오 요약 포함)
            Expanded(
              child: _buildDetailsSection(plan, cueCards, screenWidth, screenHeight),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomInputBar(screenWidth, screenHeight),
    );
  }

  // 상단 헤더 바
  Widget _buildTopBar(BuildContext context, double screenWidth) {
    return Container(
      width: screenWidth,
      height: 79,
      decoration: const BoxDecoration(
        color: Color(0xFFCEDCD3),
      ),
      child: Stack(
        children: [
          // 왼쪽 사이드바 버튼
          Positioned(
            left: 17,
            top: 15,
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
          
          // 중앙 로고와 화면 이름
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 로고 (클릭 시 홈으로 이동)
                GestureDetector(
                  onTap: () {
                    // 키보드 닫기
                    FocusScope.of(context).unfocus();
                    
                    // 네비게이션 스택을 모두 제거하고 홈으로 이동
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (route) => false,
                    );
                  },
                  child: Image.asset(
                    'assets/images/logo_text.png',
                    width: screenWidth * 0.25, // 더 작게
                    fit: BoxFit.contain,
                  ),
                ),
                // 화면 이름 (작은 글씨)
                Text(
                  '스토리보드',
                  style: TextStyle(
                    fontFamily: 'Tmoney RoundWind',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: const Color(0xFF1A1A1A).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // 오른쪽 씬 리스트 버튼
          Positioned(
            right: 17,
            top: 15,
            child: GestureDetector(
              onTap: () {
                // 키보드 닫기
                FocusScope.of(context).unfocus();

                Navigator.push(
                  context,
                  SceneListPage.route(),
                );
              },
              child: Image.asset(
                'assets/images/button_scenelist.png',
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 탭 바
  Widget _buildTabBar(double screenWidth, double screenHeight) {
    final tabs = const ['요약', '촬영', '예산', '연출', '기타'];
    final isSelected = [
      _selectedTab == 0,
      _selectedTab == 1,
      _selectedTab == 2,
      _selectedTab == 3,
      _selectedTab == 4,
    ];

    return Container(
      width: screenWidth * 0.928, // 373/402
      height: screenHeight * 0.062, // 56/904
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
          bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
          right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
          top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 요약 탭
          _buildTabItem('요약', 0, isSelected[0], hasIcon: true),
          _buildTabItem('촬영', 1, isSelected[1]),
          _buildTabItem('예산', 2, isSelected[2]),
          _buildTabItem('연출', 3, isSelected[3]),
          _buildTabItem('기타', 4, isSelected[4]),
        ],
      ),
    );
  }

  // 탭 아이템
  Widget _buildTabItem(String label, int index, bool isSelected, {bool hasIcon = false}) {
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 선택된 탭 배경 이미지
          if (isSelected)
            Image.asset(
              'assets/images/tab_selection.png',
              width: 62,
              height: 37,
              fit: BoxFit.contain,
            ),
          // 텍스트
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Tmoney RoundWind',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                height: 1.3,
                color: isSelected ? const Color(0xFFFAFAFA) : const Color(0xFFB2B2B2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // IndexedStack 섹션 - 선택된 탭만 렌더링
  Widget _buildDetailsSection(dynamic plan, List<dynamic> cueCards, double screenWidth, double screenHeight) {
    return RepaintBoundary(
      child: IndexedStack(
        index: _selectedTab,
        children: [
          RepaintBoundary(child: SummaryTab(dataService: _dataService)),
          RepaintBoundary(child: ShootingTab(dataService: _dataService)),
          RepaintBoundary(child: BudgetTab(dataService: _dataService)),
          RepaintBoundary(child: DirectionTab(dataService: _dataService)),
          RepaintBoundary(child: EtcTab(dataService: _dataService)),
        ],
      ),
    );
  }

  // 하단 입력 바
  Widget _buildBottomInputBar(double screenWidth, double screenHeight) {
    // 키보드 높이를 별도 위젯으로 분리하여 리빌드 최소화
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardHeight), // 키보드 높이만큼 패딩 추가
          child: Container(
        width: screenWidth,
        constraints: BoxConstraints(
          minHeight: screenHeight * 0.087, // 최소 높이
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          border: Border(
            top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 입력 필드
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 48,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: const Border(
                  left: BorderSide(color: Color(0xFF2C3E50), width: 3),
                  bottom: BorderSide(color: Color(0xFF2C3E50), width: 6),
                  right: BorderSide(color: Color(0xFF2C3E50), width: 6),
                  top: BorderSide(color: Color(0xFF2C3E50), width: 3),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      focusNode: _inputFocusNode,
                      textAlignVertical: TextAlignVertical.top,
                      maxLines: _isInputExpanded ? null : 1,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: '수정 내용을 입력하세요...',
                        hintStyle: TextStyle(
                          fontFamily: 'Tmoney RoundWind',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Color(0xFFB2B2B2),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Tmoney RoundWind',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  // X 버튼 (항상 표시)
                  GestureDetector(
                    onTap: _inputController.text.isNotEmpty
                        ? () {
                            _inputController.clear();
                            setState(() {
                              _isInputExpanded = false;
                            });
                          }
                        : null,
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _inputController.text.isNotEmpty
                            ? const Color(0xFFB2B2B2).withOpacity(0.2)
                            : const Color(0xFFB2B2B2).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: _inputController.text.isNotEmpty
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFB2B2B2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 17),
          // 전송 버튼
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: _handleSendModification,
              child: Image.asset(
                'assets/images/button_send.png',
                width: 45,
                height: 45,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
      ),
        );
      },
    );
  }

}
