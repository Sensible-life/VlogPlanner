import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../widgets/style_radar_chart.dart';
import '../../widgets/shooting_route_map.dart';

class StoryboardPage extends StatefulWidget {
  const StoryboardPage({super.key});

  @override
  State<StoryboardPage> createState() => _StoryboardPageState();
}

class _StoryboardPageState extends State<StoryboardPage> {

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
            child: Container(
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
                        '친구들과의 카페 토크 브이로그',
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '대화 위주 촬영 | 먹방 | 낮, 맑음',
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
                      _buildInfoRow(Icons.camera_alt, '촬영 장비', '스마트폰'),
                      Divider(color: AppColors.grey.withOpacity(0.3)),
                      _buildInfoRow(Icons.timer, '촬영 길이', '15분'),
                      Divider(color: AppColors.grey.withOpacity(0.3)),
                      _buildInfoRow(Icons.movie, '씬 갯수', '12개'),
                      Divider(color: AppColors.grey.withOpacity(0.3)),
                      _buildInfoRow(Icons.attach_money, '촬영 예산', '\$40'),
                      Divider(color: AppColors.grey.withOpacity(0.3)),
                      _buildInfoRow(Icons.people, '등장 인물', '3명'),
                      Divider(color: AppColors.grey.withOpacity(0.3)),
                      _buildInfoRow(Icons.palette, '영상 톤', '차분함'),
                      Divider(color: AppColors.grey.withOpacity(0.3)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // 시나리오 요약
                _buildSectionTitle('시나리오 요약'),
                _buildSectionContent('친구 2명과 함께 카페에서 만나 최근 근황을 이야기하며 브런치를 즐기는 일상 브이로그. 자연스러운 대화 속에서 서로의 이야기를 공유하고, 카페 음식 리뷰도 함께 진행합니다.'),
                
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
                
                // 촬영 준비 체크리스트
                _buildSectionTitle('촬영 준비 체크리스트'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChecklistItem('카페 사전 예약 및 촬영 허가'),
                      _buildChecklistItem('스마트폰 완충 및 여분 배터리 준비'),
                      _buildChecklistItem('삼각대 또는 거치대 준비'),
                      _buildChecklistItem('무선 마이크 또는 핀마이크'),
                      _buildChecklistItem('조명 장비 (필요시)'),
                    ],
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
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
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
          child: Row(
            children: [
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
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: 세부 씬 확인하기 로직
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardBackground,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Text(
                    '세부 씬 확인하기',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

