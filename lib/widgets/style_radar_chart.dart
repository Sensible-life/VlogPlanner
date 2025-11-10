import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../services/vlog_data_service.dart';

class StyleRadarChart extends StatelessWidget {
  const StyleRadarChart({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = VlogDataService();
    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        radarBorderData: BorderSide(
          color: AppColors.grey.withOpacity(0.3),
          width: 1,
        ),
        gridBorderData: BorderSide(
          color: AppColors.grey.withOpacity(0.2),
          width: 1,
        ),
        tickCount: 5,
        ticksTextStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
        tickBorderData: BorderSide(
          color: AppColors.grey.withOpacity(0.2),
          width: 1,
        ),
        getTitle: (index, angle) {
          const titles = [
            '동작 강도',
            '감정 표현',
            '장소 다양성',
            '속도/리듬',
            '흥분/놀람',
          ];
          return RadarChartTitle(
            text: titles[index],
            angle: 0,
          );
        },
        titleTextStyle: const TextStyle(
          fontFamily: 'Pretendard Variable',
          color: Colors.black,
          fontWeight: FontWeight.w300,
          fontSize: 11,
        ),
        dataSets: [
          RadarDataSet(
            fillColor: AppColors.primary.withOpacity(0.2),
            borderColor: AppColors.primary,
            borderWidth: 2,
            entryRadius: 3,
            dataEntries: [
              RadarEntry(value: (dataService.getMovement() + dataService.getIntensity()) / 2), // 동작 강도 (동작+강도 평균)
              RadarEntry(value: dataService.getEmotionalExpression().toDouble()), // 감정 표현
              RadarEntry(value: dataService.getLocationDiversity().toDouble()), // 장소 다양성
              RadarEntry(value: dataService.getSpeedRhythm().toDouble()), // 속도/리듬
              RadarEntry(value: dataService.getExcitementSurprise().toDouble()), // 흥분/놀람
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStyleItem(String title, int score, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < score ? Icons.star : Icons.star_border,
                  color: AppColors.primary,
                  size: 20,
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // 점수에 따른 설명 생성 함수들
  String _getEmotionalExpressionDescription(int score) {
    if (score >= 4) return '풍부하고 다양한 감정을 표현하며 시청자와 강한 공감대를 형성합니다.';
    if (score >= 3) return '자연스러운 감정 표현으로 편안한 분위기를 만듭니다.';
    return '절제된 감정 표현으로 담담하게 이야기를 전달합니다.';
  }

  String _getMovementDescription(int score) {
    if (score >= 4) return '활발한 움직임과 다이나믹한 장면 전환이 특징입니다.';
    if (score >= 3) return '적절한 움직임으로 자연스러운 흐름을 만듭니다.';
    return '정적인 구도와 안정적인 프레임을 유지합니다.';
  }

  String _getIntensityDescription(int score) {
    if (score >= 4) return '높은 에너지와 강렬한 장면으로 몰입감을 극대화합니다.';
    if (score >= 3) return '적절한 강도로 지루하지 않은 영상을 만듭니다.';
    return '차분하고 편안한 강도로 편안한 시청 경험을 제공합니다.';
  }

  String _getLocationDiversityDescription(int score) {
    if (score >= 4) return '다양한 장소와 앵글을 활용하여 시각적 변화를 극대화합니다.';
    if (score >= 3) return '여러 장소를 적절히 활용하여 단조롭지 않게 구성합니다.';
    return '제한된 장소에서 안정적인 구도로 촬영합니다.';
  }

  String _getSpeedRhythmDescription(int score) {
    if (score >= 4) return '빠른 템포와 경쾌한 리듬으로 활기찬 분위기를 만듭니다.';
    if (score >= 3) return '적절한 템포로 편안하게 시청할 수 있습니다.';
    return '느린 템포로 여유롭고 차분한 분위기를 연출합니다.';
  }

  String _getExcitementSurpriseDescription(int score) {
    if (score >= 4) return '예상치 못한 장면과 이벤트로 흥미진진한 스토리를 전개합니다.';
    if (score >= 3) return '적절한 이벤트로 지루하지 않게 구성됩니다.';
    return '차분한 일상으로 자연스럽게 흘러갑니다.';
  }
}

