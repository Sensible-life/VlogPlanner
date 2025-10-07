import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import 'tabs/concept_style_tab.dart';
import 'tabs/detail_plan_tab.dart';
import 'tabs/environment_tab.dart';

class UserInputPage extends StatefulWidget {
  const UserInputPage({super.key});

  @override
  State<UserInputPage> createState() => _UserInputPageState();
}

class _UserInputPageState extends State<UserInputPage> {
  int _selectedSegment = 0;
  late PageController _pageController;
  double _dragStartX = 0;

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
                  : AppColors.textSecondary,
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
            color: AppColors.black,
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
                            color: AppColors.cardBackground,
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
                children: const [
                  ConceptStyleTab(),
                  DetailPlanTab(),
                  EnvironmentTab(),
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
                  onPressed: () {
                    // TODO: 완료 처리 로직
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Text(
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

