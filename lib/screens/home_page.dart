import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import 'user_input/user_input_page.dart';
import 'home/storyboard_drawer.dart';
import 'home/user_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _scaffoldKeyRight = GlobalKey<ScaffoldState>();
  bool _isLeftDrawerOpen = false;
  bool _isRightDrawerOpen = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Widget _mainContent;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150), // 기본은 열릴 때 속도 (200 -> 150으로 더 빠르게)
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear, // 동일한 속도로 이동
    );
    _mainContent = _buildMainContent();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openLeftDrawer() {
    setState(() {
      _isLeftDrawerOpen = true;
    });
    // 열릴 때는 150ms
    _animationController.duration = const Duration(milliseconds: 150);
    _animationController.forward();
  }

  void _openRightDrawer() {
    // user page는 오른쪽에서 슬라이드하는 커스텀 애니메이션으로 이동
    Navigator.push(
      context,
      UserDrawer.route(),
    );
  }
  
  void _onLeftDrawerChanged(bool isOpened) {
    setState(() {
      _isLeftDrawerOpen = isOpened;
    });
    if (!isOpened) {
      // 닫힐 때는 200ms
      _animationController.duration = const Duration(milliseconds: 200);
      _animationController.reverse();
    }
  }
  
  void _onRightDrawerChanged(bool isOpened) {
    // user drawer는 더 이상 사용하지 않음
  }

  void _closeLeftDrawer() {
    setState(() {
      _isLeftDrawerOpen = false;
    });
    _animationController.duration = const Duration(milliseconds: 200);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * 0.8;
    final visibleWidth = screenWidth * 0.2;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // 메인 콘텐츠와 scrim을 함께 이동
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              // offset은 _animation.value에만 의존하여 대칭 동작
              final offset = drawerWidth * _animation.value;
              
              return Stack(
                children: [
                  // 사이드바 (왼쪽에서 슬라이드)
                  Positioned(
                    left: -drawerWidth + drawerWidth * _animation.value,
                    top: 0,
                    bottom: 0,
                    width: drawerWidth,
                    child: child!,
                  ),
                  
                  // 메인 콘텐츠
                  Transform.translate(
                    offset: Offset(offset, 0),
                    child: _mainContent,
                  ),
                  
                  // 사이드바 뒷배경 scrim (전체 화면 덮기)
                  if (_animation.value > 0)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      right: 0,
                      child: Transform.translate(
                        offset: Offset(offset, 0),
                        child: GestureDetector(
                          onTap: _closeLeftDrawer,
                          child: Opacity(
                            opacity: _animation.value,
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            child: StoryboardDrawer(onClose: _closeLeftDrawer),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 메인 콘텐츠
            Column(
              children: [
                // 상단 여백
                const Expanded(child: SizedBox()),
                
                // 타이틀 영역
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      
                      // 메인 타이틀
                      Text(
                        '나만의 브이로그 만들기',
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 서브 타이틀
                      Text(
                        'AI가 당신의 브이로그\n스토리보드를 만들어 드립니다',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // 하단 여백
                const Expanded(child: SizedBox()),
                
                // 하단 버튼
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserInputPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            '스토리보드 만들기',
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // 왼쪽 상단 메뉴 버튼
            Positioned(
              left: 20,
              top: 20,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _openLeftDrawer,
                    child: Icon(
                      Icons.menu,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            
            // 오른쪽 상단 사용자 버튼
            Positioned(
              right: 20,
              top: 20,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _openRightDrawer,
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

