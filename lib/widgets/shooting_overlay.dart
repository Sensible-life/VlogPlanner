import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../models/cue_card.dart';
import '../models/shooting_session.dart';
import '../services/shake_detection_service.dart';
import '../services/system_check_service.dart';

/// 촬영 화면 오버레이
class ShootingOverlay extends StatelessWidget {
  final ShootingSession session;
  final CueCard scene;
  final bool isRecording;
  final int recordingSeconds;
  final BatteryStatus? batteryStatus;
  final StorageStatus? storageStatus;
  final ShakeEvent? lastShakeEvent;
  final Function(String) onChecklistToggle;

  const ShootingOverlay({
    super.key,
    required this.session,
    required this.scene,
    required this.isRecording,
    required this.recordingSeconds,
    this.batteryStatus,
    this.storageStatus,
    this.lastShakeEvent,
    required this.onChecklistToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 상단 정보 바
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: _buildTopBar(),
        ),

        // 녹화 중 표시
        if (isRecording)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: _buildRecordingIndicator(),
          ),

        // 흔들림 경고
        if (lastShakeEvent != null && isRecording)
          Positioned(
            top: MediaQuery.of(context).padding.top + 110,
            left: 16,
            right: 16,
            child: _buildShakeWarning(),
          ),

        // 체크리스트 (좌측 상단)
        Positioned(
          top: MediaQuery.of(context).padding.top + 170,
          left: 16,
          child: _buildChecklistButton(context),
        ),

        // 씬 정보 (우측 상단)
        Positioned(
          top: MediaQuery.of(context).padding.top + 170,
          right: 16,
          child: _buildSceneInfo(),
        ),
      ],
    );
  }

  /// 상단 정보 바
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 배터리
          if (batteryStatus != null) ...[
            Icon(
              batteryStatus!.isCharging
                  ? Icons.battery_charging_full
                  : _getBatteryIcon(batteryStatus!.level),
              color: batteryStatus!.isLowBattery ? AppColors.error : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '${batteryStatus!.level}%',
              style: AppTextStyles.bodySmall.copyWith(
                color: batteryStatus!.isLowBattery ? AppColors.error : Colors.white,
              ),
            ),
            const SizedBox(width: 16),
          ],

          // 저장 공간
          if (storageStatus != null) ...[
            Icon(
              Icons.storage,
              color: storageStatus!.isLowStorage ? AppColors.error : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '${storageStatus!.freeSpaceGB.toStringAsFixed(1)}GB',
              style: AppTextStyles.bodySmall.copyWith(
                color: storageStatus!.isLowStorage ? AppColors.error : Colors.white,
              ),
            ),
            const SizedBox(width: 16),
          ],

          const Spacer(),

          // 테이크 정보
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Takes: ${session.totalTakeCount} | OK: ${session.circleTakeCount}',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBatteryIcon(int level) {
    if (level > 80) return Icons.battery_full;
    if (level > 60) return Icons.battery_6_bar;
    if (level > 40) return Icons.battery_4_bar;
    if (level > 20) return Icons.battery_2_bar;
    return Icons.battery_1_bar;
  }

  /// 녹화 중 표시
  Widget _buildRecordingIndicator() {
    final minutes = recordingSeconds ~/ 60;
    final seconds = recordingSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'REC $timeStr',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 흔들림 경고
  Widget _buildShakeWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        children: [
          Text(
            lastShakeEvent!.emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lastShakeEvent!.message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 체크리스트 버튼
  Widget _buildChecklistButton(BuildContext context) {
    final progress = session.checklistProgress;

    return GestureDetector(
      onTap: () => _showChecklistDialog(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: progress == 100
              ? AppColors.primary.withOpacity(0.9)
              : Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              progress == 100 ? Icons.check_circle : Icons.checklist,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              '${progress.toStringAsFixed(0)}%',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 씬 정보
  Widget _buildSceneInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            scene.title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${scene.allocatedSec}초',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            scene.trigger,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// 체크리스트 다이얼로그
  void _showChecklistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.checklist),
            const SizedBox(width: 8),
            const Text('촬영 체크리스트'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: session.checklist.entries.map((entry) {
              return CheckboxListTile(
                title: Text(entry.key),
                value: entry.value,
                onChanged: (value) {
                  onChecklistToggle(entry.key);
                  Navigator.pop(context);
                  // 다이얼로그 다시 열기
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _showChecklistDialog(context);
                  });
                },
                activeColor: AppColors.primary,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
