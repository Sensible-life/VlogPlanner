import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';

class UserDrawer extends StatelessWidget {
  const UserDrawer({super.key});

  // 커스텀 페이지 전환 애니메이션
  static Route<void> route() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const UserDrawer(),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '사용자 정보',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 프로필 섹션
              Container(
                decoration: BoxDecoration(
                  color: AppColors.paperLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.filmBorder.withOpacity(0.6),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '사용자 이름',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'user@example.com',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 설정 메뉴
              _buildSettingItem(
                icon: Icons.edit_outlined,
                title: '프로필 편집',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _buildSettingItem(
                icon: Icons.settings_outlined,
                title: '설정',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _buildSettingItem(
                icon: Icons.help_outline,
                title: '도움말',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _buildSettingItem(
                icon: Icons.logout_outlined,
                title: '로그아웃',
                isDanger: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.filmBorder.withOpacity(0.5),
          width: 0.6,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDanger
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isDanger ? AppColors.error : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDanger ? AppColors.error : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: isDanger ? AppColors.error : AppColors.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
