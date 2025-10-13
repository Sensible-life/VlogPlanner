import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class StyleRadarChart extends StatelessWidget {
  const StyleRadarChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 레이더 차트
        SizedBox(
          height: 300,
          child: RadarChart(
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
                  '감정 표현',
                  '동작 강도',
                  '장소 다양성',
                  '속도/리듬',
                  '흥분/놀람',
                ];
                return RadarChartTitle(
                  text: titles[index],
                  angle: 0,
                );
              },
              titleTextStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              dataSets: [
                RadarDataSet(
                  fillColor: AppColors.primary.withOpacity(0.2),
                  borderColor: AppColors.primary,
                  borderWidth: 2,
                  entryRadius: 4,
                  dataEntries: const [
                    RadarEntry(value: 3), // 감정 표현
                    RadarEntry(value: 2), // 동작 강도
                    RadarEntry(value: 4), // 장소 다양성
                    RadarEntry(value: 3), // 속도/리듬
                    RadarEntry(value: 2), // 흥분/놀람
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // 각 항목별 점수 및 설명
        _buildStyleItem(
          '감정 표현',
          3,
          '차분하고 편안한 분위기로 일상적인 감정을 자연스럽게 표현합니다.',
        ),
        const SizedBox(height: 24),
        
        _buildStyleItem(
          '동작 강도',
          2,
          '과도한 움직임 없이 정적인 대화 중심으로 진행됩니다.',
        ),
        const SizedBox(height: 24),
        
        _buildStyleItem(
          '장소 다양성',
          4,
          '카페 내부의 다양한 공간과 앵글을 활용하여 시각적 변화를 줍니다.',
        ),
        const SizedBox(height: 24),
        
        _buildStyleItem(
          '속도/리듬',
          3,
          '빠르지도 느리지도 않은 중간 템포로 편안한 시청 경험을 제공합니다.',
        ),
        const SizedBox(height: 24),
        
        _buildStyleItem(
          '흥분/놀람',
          2,
          '차분한 일상 브이로그로 큰 이벤트나 반전 없이 자연스럽게 흘러갑니다.',
        ),
      ],
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
}

