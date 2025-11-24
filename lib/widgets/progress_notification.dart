import 'package:flutter/material.dart';
import '../services/progress_notification_service.dart';
import '../constants/app_colors.dart';

class ProgressNotification extends StatelessWidget {
  final double progress; // 0.0 ~ 1.0
  final String currentTask;

  const ProgressNotification({
    super.key,
    required this.progress,
    required this.currentTask,
  });

  // 서비스에서 현재 상태를 가져오는 생성자
  factory ProgressNotification.fromService() {
    final service = ProgressNotificationService();
    return ProgressNotification(
      progress: service.progress,
      currentTask: service.currentTask,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Container(
        width: screenWidth * 0.65, // 가로 길이 60%
        constraints: const BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5).withOpacity(0.95), // 촬영 알림과 동일한 색상, 약간 투명
          border: Border(
            left: const BorderSide(color: Color(0xFFFF9800), width: 2),
            bottom: const BorderSide(color: Color(0xFFFF9800), width: 3.5),
            right: const BorderSide(color: Color(0xFFFF9800), width: 3.5),
            top: const BorderSide(color: Color(0xFFFF9800), width: 2),
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // 로딩 애니메이션 (크기 줄이기)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.black),
                ),
              ),
              const SizedBox(width: 10),
              
              // 진행 텍스트
              Expanded(
                child: Text(
                  currentTask,
                  style: TextStyle(
                    fontFamily: 'Tmoney RoundWind',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.black,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 퍼센테이지 (오른쪽에 붙이기)
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

