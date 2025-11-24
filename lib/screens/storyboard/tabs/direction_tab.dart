import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../services/vlog_data_service.dart';
import '../../../widgets/style_radar_chart.dart';
import '../../../ui/styles.dart';

class DirectionTab extends StatefulWidget {
  final VlogDataService dataService;

  const DirectionTab({
    super.key,
    required this.dataService,
  });

  @override
  State<DirectionTab> createState() => _DirectionTabState();
}

class _DirectionTabState extends State<DirectionTab> {
  int _selectedIndex = 0; // 동작 강도부터 시작

  @override
  Widget build(BuildContext context) {
    final plan = widget.dataService.plan;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (plan == null) {
      return const Center(child: Text('데이터를 불러올 수 없습니다'));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: screenWidth * 0.928, // 373/402
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.036),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 연출 소제목
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / 402)),
              child: const Text(
                '연출',
                style: TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  height: 1.29,
                  letterSpacing: -0.72,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            SizedBox(height: AppDims.marginSubtitleToContent(screenHeight)),

            // 레이더 차트 박스
            RepaintBoundary(
              child: Container(
                width: double.infinity,
                height: screenHeight * (390 / 904), // 피그마 기준 390
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return RepaintBoundary(
                      child: Stack(
                        children: [
                          // 레이더 차트
                          Positioned.fill(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.08,
                                vertical: screenHeight * 0.06,
                              ),
                              child: RepaintBoundary(
                                child: StyleRadarChart(
                                  selectedIndex: _selectedIndex,
                                  onTap: (index) {
                                    setState(() {
                                      _selectedIndex = index;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),

                          // 각 텍스트 위치에 배경 박스 추가
                          ..._buildTextBackgrounds(constraints, screenWidth, screenHeight),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: AppDims.marginContentToSubtitle(screenHeight)),

            // 하단 설명 박스
            _buildStyleDescription(screenWidth, screenHeight),
            
            SizedBox(height: screenHeight * 0.03),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTextBackgrounds(BoxConstraints constraints, double screenWidth, double screenHeight) {
    final offsets = [0.15, 0.3, 0.3, 0.25, 0.3, 0.3];
    final angles = [0, 60, 120, 180, 240, 300]; // 도 단위
    final titles = ['동작 강도', '다양성', '흥분/놀람', '색감/질감', '속도/리듬', '감정 표현'];

    // 각 항목별 배율 (개별 조정 가능)
    // index 0: 동작 강도, 1: 장소 다양성, 2: 흥분/놀람, 3: 색감/질감, 4: 속도/리듬, 5: 감정 표현
    final multipliers = [
      7.3, // 동작 강도
      3.9, // 장소 다양성
      3.6, // 흥분/놀람
      4.2, // 색감/질감
      3.6, // 속도/리듬
      3.9, // 감정 표현
    ];

    // 각 항목별 하이라이트 가로 길이 (개별 조정 가능)
    final textWidths = [
      55.0,  // 동작 강도
      57.0, // 장소 다양성
      50.0, // 흥분/놀람
      60.0, // 색감/질감
      55.0, // 속도/리듬
      50.0, // 감정 표현
    ];

    // 각 항목별 가로 위치 미세 조정 (개별 조정 가능)
    // 음수: 왼쪽으로, 양수: 오른쪽으로
    final horizontalOffsets = [
      -5.0, // 동작 강도
      4.0, // 장소 다양성
      -8.0, // 흥분/놀람
      -5.0, // 색감/질감
      -8.0, // 속도/리듬
      1.0, // 감정 표현
    ];

    // 실제 컨테이너 크기 사용
    final containerWidth = constraints.maxWidth;
    final containerHeight = constraints.maxHeight;

    final horizontalPadding = screenWidth * 0.08;
    final verticalPadding = screenHeight * 0.06;

    // 차트의 실제 크기 (padding 제외)
    final chartWidth = containerWidth - 2 * horizontalPadding;
    final chartHeight = containerHeight - 2 * verticalPadding;

    // 컨테이너의 중심점
    final centerX = containerWidth / 2;
    final centerY = containerHeight / 2;

    // RadarChart가 사용하는 radius (정사각형 기준)
    final radius = math.min(chartWidth, chartHeight) / 2;

    return List.generate(6, (index) {
      final angleRad = angles[index] * math.pi / 180;
      final offset = offsets[index];
      final title = titles[index];

      // 텍스트 위치 계산 (차트 중심 기준)
      // 각 항목별 배율 적용
      final multiplier = multipliers[index];
      final textX = centerX + radius * offset * multiplier * math.sin(angleRad);
      final textY = centerY - radius * offset * multiplier * math.cos(angleRad);

      // 텍스트 크기 (개별 조정 가능)
      final textWidth = textWidths[index];
      final textHeight = 18.0;

      final isSelected = index == _selectedIndex;

      return Positioned(
        left: textX - textWidth / 2 - 14 + horizontalOffsets[index], // 텍스트 중심 기준 (개별 조정)
        top: textY - textHeight / 2 - 6, // 텍스트 중심 기준 (클릭 영역 확대)
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, // 투명 영역도 클릭 가능하게
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
            },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2C3E50) : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              border: isSelected
                  ? const Border(
                      left: BorderSide(color: Color(0xFF1A1A1A), width: 1),
                      bottom: BorderSide(color: Color(0xFF1A1A1A), width: 2),
                      right: BorderSide(color: Color(0xFF1A1A1A), width: 2),
                      top: BorderSide(color: Color(0xFF1A1A1A), width: 1),
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  color: isSelected ? const Color(0xFFFAFAFA) : const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildStyleDescription(double screenWidth, double screenHeight) {
    final dataService = widget.dataService;
    
    // 각 스타일 항목의 제목, 점수, 설명
    final titles = ['동작 강도', '다양성', '흥분/놀람', '색감/질감', '속도/리듬', '감정 표현'];
    
    // 점수에 따른 구체적이고 정확한 설명
    final plan = dataService.plan;
    final styleAnalysis = plan?.styleAnalysis;
    
    // 각 항목의 점수 가져오기
    final movementScore = dataService.getMovement();
    final locationDiversityScore = dataService.getLocationDiversity();
    final excitementScore = dataService.getExcitementSurprise();
    final speedRhythmScore = dataService.getSpeedRhythm();
    final emotionalScore = dataService.getEmotionalExpression();
    
    // 점수에 따라 구체적인 설명 생성
    final descriptions = [
      _getMovementDescription(movementScore, styleAnalysis?.rationale?.movement),
      _getDiversityDescription(locationDiversityScore, styleAnalysis?.rationale?.locationDiversity),
      _getExcitementDescription(excitementScore, styleAnalysis?.rationale?.excitementSurprise),
      _getVisualStyleDescription(styleAnalysis?.visualStyle ?? []),
      _getSpeedRhythmDescription(speedRhythmScore, styleAnalysis?.rationale?.speedRhythm),
      _getEmotionalDescription(emotionalScore, styleAnalysis?.rationale?.emotionalExpression),
    ];
    
    // 각 항목의 점수 (5점 만점)
    final scores = [
      ((dataService.getMovement() + dataService.getIntensity()) / 2).round(),
      dataService.getLocationDiversity(),
      dataService.getExcitementSurprise(),
      dataService.getExcitementSurprise(), // 임시로 색감/질감 대신 사용
      dataService.getSpeedRhythm(),
      dataService.getEmotionalExpression(),
    ];

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(15),
          border: const Border(
            left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
            bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
            right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
            top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * (25 / 402),
          vertical: screenHeight * (18 / 904),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 행
            Row(
              children: [
                Text(
                  titles[_selectedIndex],
                  style: const TextStyle(
                    fontFamily: 'Tmoney RoundWind',
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    height: 1.2,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${scores[_selectedIndex]}/5',
                  style: const TextStyle(
                    fontFamily: 'Tmoney RoundWind',
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    height: 1.2,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            
            // 설명 텍스트 (bullet point 지원)
            _buildDescriptionText(descriptions[_selectedIndex]),
          ],
        ),
      ),
    );
  }
  
  // 동작 강도 설명
  String _getMovementDescription(int score, String? rationale) {
    if (rationale != null && rationale.isNotEmpty) {
      return rationale;
    }
    switch (score) {
      case 1:
        return '카메라가 거의 고정되어 있으며, 정적인 촬영 위주입니다. 안정적인 구도와 최소한의 움직임으로 차분한 분위기를 연출합니다.';
      case 2:
        return '카메라 움직임이 제한적이며, 대부분 고정 샷과 간단한 팬/틸트만 사용합니다. 신중하고 안정적인 촬영 스타일입니다.';
      case 3:
        return '적절한 수준의 카메라 움직임이 있으며, 팬, 틸트, 줌 등 기본적인 카메라 워크를 활용합니다. 균형잡힌 촬영 방식입니다.';
      case 4:
        return '카메라 움직임이 활발하며, 핸드헬드, 트래킹 샷, 다이나믹한 각도 변화가 많습니다. 역동적인 영상을 만듭니다.';
      case 5:
        return '매우 활발한 카메라 움직임으로, 빠른 패닝, 급격한 줌, 다양한 각도 전환이 특징입니다. 매우 역동적이고 생동감 있는 영상입니다.';
      default:
        return '카메라의 움직임이 활발하며, 역동적인 장면 전환이 많습니다.';
    }
  }
  
  // 다양성 설명
  String _getDiversityDescription(int score, String? rationale) {
    if (rationale != null && rationale.isNotEmpty) {
      return rationale;
    }
    switch (score) {
      case 1:
        return '단일 장소나 매우 제한된 공간에서만 촬영이 이루어집니다. 장소의 변화가 거의 없습니다.';
      case 2:
        return '2-3개의 장소에서 촬영하며, 장소 변화가 제한적입니다. 주로 한 공간 내에서의 촬영입니다.';
      case 3:
        return '4-5개의 다양한 장소에서 촬영하며, 적절한 수준의 장소 다양성을 보입니다.';
      case 4:
        return '6개 이상의 다양한 장소에서 촬영하며, 실내/실외, 다양한 배경이 풍부하게 포함됩니다.';
      case 5:
        return '10개 이상의 매우 다양한 장소에서 촬영하며, 완전히 다른 환경과 배경이 지속적으로 변화합니다.';
      default:
        return '다양한 장소에서 촬영이 이루어져 시각적 변화가 풍부합니다.';
    }
  }
  
  // 흥분/놀람 설명
  String _getExcitementDescription(int score, String? rationale) {
    if (rationale != null && rationale.isNotEmpty) {
      return rationale;
    }
    switch (score) {
      case 1:
        return '예측 가능하고 일상적인 내용으로, 특별한 놀라움이나 흥분 요소가 거의 없습니다. 차분하고 안정적인 흐름입니다.';
      case 2:
        return '대부분 예측 가능한 흐름이며, 가끔 작은 변화나 재미있는 순간이 포함됩니다.';
      case 3:
        return '적절한 수준의 예상치 못한 순간과 재미있는 이벤트가 포함되어 있습니다.';
      case 4:
        return '놀라운 순간과 흥미진진한 이벤트가 자주 등장하며, 시청자의 관심을 지속적으로 유지합니다.';
      case 5:
        return '매우 예상치 못한 순간, 강렬한 반전, 흥미진진한 이벤트가 지속적으로 등장합니다. 매우 역동적이고 몰입도 높은 영상입니다.';
      default:
        return '놀라움과 흥분이 느껴지는 순간들이 많이 포함되어 있습니다.';
    }
  }
  
  // 색감/질감 설명
  String _getVisualStyleDescription(List<String> visualStyles) {
    if (visualStyles.isEmpty) {
      return '영상의 색감과 질감이 특별한 분위기를 연출합니다.';
    }
    return '${visualStyles.join(', ')} 등의 시각적 스타일이 적용되어 있습니다. 이러한 색감과 질감이 영상의 전체적인 분위기와 톤을 결정합니다.';
  }
  
  // 속도/리듬 설명
  String _getSpeedRhythmDescription(int score, String? rationale) {
    if (rationale != null && rationale.isNotEmpty) {
      return rationale;
    }
    switch (score) {
      case 1:
        return '매우 느린 템포로, 긴 샷과 천천히 진행되는 장면이 특징입니다. 여유롭고 차분한 리듬감입니다.';
      case 2:
        return '느린 편의 템포로, 안정적이고 여유로운 편집 리듬입니다.';
      case 3:
        return '적절한 템포와 리듬감으로, 빠르지도 느리지도 않은 균형잡힌 편집입니다.';
      case 4:
        return '빠른 템포와 활발한 리듬감으로, 역동적인 편집과 빠른 장면 전환이 특징입니다.';
      case 5:
        return '매우 빠른 템포와 강렬한 리듬감으로, 급격한 컷, 빠른 전환, 역동적인 편집이 지속됩니다.';
      default:
        return '영상의 템포와 리듬감이 시청자의 몰입도를 높입니다.';
    }
  }
  
  // 감정 표현 설명
  String _getEmotionalDescription(int score, String? rationale) {
    if (rationale != null && rationale.isNotEmpty) {
      return rationale;
    }
    switch (score) {
      case 1:
        return '감정 표현이 최소화되어 있으며, 중립적이고 객관적인 톤으로 진행됩니다.';
      case 2:
        return '제한적인 감정 표현으로, 대부분 차분하고 절제된 감정 전달입니다.';
      case 3:
        return '적절한 수준의 감정 표현으로, 자연스럽고 균형잡힌 감정 전달이 이루어집니다.';
      case 4:
        return '풍부한 감정 표현으로, 다양한 감정의 변화와 깊이 있는 감정 전달이 특징입니다.';
      case 5:
        return '매우 풍부하고 강렬한 감정 표현으로, 감정의 극대화와 깊은 공감을 이끌어냅니다.';
      default:
        return '감정이 풍부하게 표현되어 공감을 이끌어냅니다.';
    }
  }
  
  // 설명 텍스트 위젯 (bullet point 형식 지원)
  Widget _buildDescriptionText(String description) {
    // \n으로 구분된 bullet point 형식인지 확인
    if (description.contains('\n')) {
      final lines = description.split('\n');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          final trimmedLine = line.trim();
          if (trimmedLine.isEmpty) {
            return const SizedBox(height: 4);
          }
          // bullet point가 이미 포함되어 있으면 그대로 표시, 없으면 추가
          final displayText = trimmedLine.startsWith('•') || trimmedLine.startsWith('-')
              ? trimmedLine
              : '• $trimmedLine';
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              displayText,
              style: const TextStyle(
                fontFamily: 'Tmoney RoundWind',
                fontWeight: FontWeight.w400,
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF1A1A1A),
              ),
            ),
          );
        }).toList(),
      );
    }
    
    // 일반 텍스트인 경우
    return Text(
      description,
      style: const TextStyle(
        fontFamily: 'Tmoney RoundWind',
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.5,
        color: Color(0xFF1A1A1A),
      ),
    );
  }
}
