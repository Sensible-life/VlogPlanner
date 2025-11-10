import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class LoadingDialog extends StatelessWidget {
  final String title;
  final String message;
  final double? progress; // 0.0 ~ 1.0, null이면 무한 로딩

  const LoadingDialog({
    super.key,
    required this.title,
    required this.message,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 로딩 인디케이터
            SizedBox(
              width: 60,
              height: 60,
              child: progress != null
                  ? CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      backgroundColor: AppColors.grey.withOpacity(0.3),
                    )
                  : CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
            ),
            const SizedBox(height: 24),
            // 제목
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // 메시지
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (progress != null) ...[
              const SizedBox(height: 16),
              // 진행률 표시
              Text(
                '${(progress! * 100).toInt()}%',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 로딩 다이얼로그 표시 헬퍼 함수
void showLoadingDialog(
  BuildContext context, {
  required String title,
  required String message,
  double? progress,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => LoadingDialog(
      title: title,
      message: message,
      progress: progress,
    ),
  );
}

// 로딩 다이얼로그 업데이트 (진행률이 있는 경우)
class LoadingDialogController {
  final BuildContext context;
  String title;
  String message;
  double? progress;

  LoadingDialogController({
    required this.context,
    required this.title,
    required this.message,
    this.progress,
  });

  void show() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(
        title: title,
        message: message,
        progress: progress,
      ),
    );
  }

  void hide() {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

