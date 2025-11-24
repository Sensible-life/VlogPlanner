import 'package:flutter/material.dart';
import '../../../services/vlog_data_service.dart';
import '../../../ui/styles.dart';

class SummaryTab extends StatelessWidget {
  final VlogDataService dataService;

  const SummaryTab({
    super.key,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    final plan = dataService.plan;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (plan == null) {
      return Center(child: Text('데이터를 불러올 수 없습니다'));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: screenWidth * 0.928, // 373/402
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.036),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시나리오 요약 섹션
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / 402)),
              child: Text(
                '시나리오 요약',
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
            RepaintBoundary(
              child: Container(
                width: double.infinity,
                // minHeight 제거하여 내용에 따라 가변하도록
                decoration: BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
                    bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
                    right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
                    top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.066,
                  vertical: screenHeight * 0.028,
                ),
                child: Text(
                  plan.summary,
                  style: const TextStyle(
                    fontFamily: 'Tmoney RoundWind',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    height: 1.31,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: AppDims.marginContentToSubtitle(screenHeight)),
            
            // 세부 정보 섹션
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / 402)),
              child: Text(
                '세부 정보',
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
            RepaintBoundary(
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: screenHeight * 0.25, // 253/904
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
                    bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
                    right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
                    top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.02,
                  vertical: screenHeight * 0.033,
                ),
                child: _buildDetailsGrid(plan, screenWidth, screenHeight),
              ),
            ),
            SizedBox(height: 2 * AppDims.marginSubtitleToContent(screenHeight)),
          ],
        ),
      ),
    );
  }

  // 세부 정보 그리드 (2*3)
  Widget _buildDetailsGrid(dynamic plan, double screenWidth, double screenHeight) {
    final details = [
      {'icon': 'assets/icons/icon_clock.png', 'value': '${plan.goalDurationMin ?? 10}분'},
      {'icon': 'assets/icons/icon_camera.png', 'value': dataService.userInput['equipment'] ?? '스마트폰'},
      {'icon': 'assets/icons/icon_people.png', 'value': dataService.getPeople()},
      {'icon': 'assets/icons/icon_pallette.png', 'value': plan.styleAnalysis?.tone ?? '차분함'},
      {'icon': 'assets/icons/icon_scenes.png', 'value': '${dataService.cueCards?.length ?? 0}씬'},
      {'icon': 'assets/icons/icon_money.png', 'value': dataService.getTotalBudget()},
    ];

    return Column(
      children: [
        // 첫 번째 행
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem(details[0], screenWidth, screenHeight),
            _buildDetailItem(details[1], screenWidth, screenHeight),
            _buildDetailItem(details[2], screenWidth, screenHeight),
          ],
        ),
        SizedBox(height: screenHeight * 0.02),
        // 두 번째 행
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem(details[3], screenWidth, screenHeight),
            _buildDetailItem(details[4], screenWidth, screenHeight),
            _buildDetailItem(details[5], screenWidth, screenHeight),
          ],
        ),
      ],
    );
  }

  // 세부 정보 아이템
  Widget _buildDetailItem(Map<String, dynamic> detail, double screenWidth, double screenHeight) {
    return SizedBox(
      width: screenWidth * 0.28, // 고정 너비로 정렬 맞춤
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 아이콘 사각형
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Color(0xFF2C3E50),
              border: Border.all(color: Color(0xFF2C3E50), width: 2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Image.asset(
                detail['icon'] as String,
                fit: BoxFit.contain,
                color: Color(0xFFFAFAFA),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.012),
          // 값
          Text(
            _formatTextWithLineBreak(detail['value'] as String),
            style: TextStyle(
              fontFamily: 'Tmoney RoundWind',
              fontWeight: FontWeight.w800,
              fontSize: 14,
              height: 1.31,
              letterSpacing: -0.72,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 텍스트가 일정 길이를 넘으면 중간에 줄바꿈 추가
  String _formatTextWithLineBreak(String text) {
    // "분", "원", "씬" 등의 단위가 붙은 경우 처리
    if (text.length <= 7) {
      return text;
    }
    
    // 공백이 있으면 공백 기준으로 분리
    if (text.contains(' ')) {
      return text.replaceFirst(' ', '\n');
    }
    
    // "하고", "로", "고" 등의 조사 뒤에서 줄바꿈
    final breakPoints = ['하고 ', '하고', '로 ', '고 ', '고', '과 ', '과', '적 ', '적'];
    for (final breakPoint in breakPoints) {
      if (text.contains(breakPoint)) {
        return text.replaceFirst(breakPoint, '$breakPoint\n');
      }
    }
    
    // 적절한 위치를 찾지 못하면 중간에서 줄바꿈
    final mid = text.length ~/ 2;
    return '${text.substring(0, mid)}\n${text.substring(mid)}';
  }
}
