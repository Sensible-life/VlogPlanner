import 'package:flutter/material.dart';
import '../../../services/vlog_data_service.dart';
import '../../../ui/styles.dart';

class BudgetTab extends StatelessWidget {
  final VlogDataService dataService;

  const BudgetTab({
    super.key,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    final plan = dataService.plan;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (plan == null) {
      return const Center(child: Text('데이터를 불러올 수 없습니다'));
    }

    // 예산 항목: plan의 budget.items와 모든 씬의 cost를 통합
    final budgetItems = plan.budget?.items ?? [];
    
    // 모든 씬의 cost를 카테고리별로 그룹화
    final cueCards = dataService.cueCards ?? [];
    final sceneCostsByCategory = <String, int>{};
    
    for (final card in cueCards) {
      if (card.cost > 0) {
        // 씬의 location이나 title을 기반으로 카테고리 추정
        String category = '기타';
        if (card.location.contains('식당') || card.location.contains('맛집') || card.location.contains('푸드')) {
          category = '식사';
        } else if (card.location.contains('카페') || card.location.contains('커피')) {
          category = '카페';
        } else if (card.location.contains('입장') || card.location.contains('게이트') || card.location.contains('공원')) {
          category = '입장료';
        } else if (card.location.contains('교통') || card.location.contains('주차')) {
          category = '교통비';
        }
        
        sceneCostsByCategory[category] = (sceneCostsByCategory[category] ?? 0) + card.cost;
      }
    }
    
    // 기존 budget items와 씬 cost를 통합
    final allBudgetItems = <Map<String, dynamic>>[];
    
    // 기존 budget items 추가
    for (final item in budgetItems) {
      allBudgetItems.add({
        'category': item.category,
        'description': item.description,
        'amount': item.amount,
      });
    }
    
    // 씬 cost를 카테고리별로 추가 (기존 항목과 같은 카테고리가 있으면 합산)
    sceneCostsByCategory.forEach((category, amount) {
      final existingIndex = allBudgetItems.indexWhere((item) => item['category'] == category);
      if (existingIndex >= 0) {
        // 기존 항목에 합산
        allBudgetItems[existingIndex]['amount'] = (allBudgetItems[existingIndex]['amount'] as int) + amount;
      } else {
        // 새 항목 추가
        allBudgetItems.add({
          'category': category,
          'description': '씬별 촬영 비용',
          'amount': amount,
        });
      }
    });
    
    final displayItems = allBudgetItems.take(8).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: screenWidth * 0.928, // 373/402
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.036),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 촬영 예산 소제목
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / 402)),
              child: const Text(
                '촬영 예산',
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

            // 예산 박스
            RepaintBoundary(
              child: Container(
                width: double.infinity,
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
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * (21 / 402), // 피그마 기준 36 + 일부 여백
                  vertical: screenHeight * (18 / 904),
                ),
                child: Column(
                  children: [
                    // 예산 항목들
                    ...List.generate(displayItems.length, (index) {
                      final item = displayItems[index];
                      final iconSize = screenWidth * (29.97 / 402);
                      return Column(
                        children: [
                          _buildBudgetItem(item, screenWidth, screenHeight),
                          if (index < displayItems.length - 1)
                            Padding(
                              padding: EdgeInsets.only(
                                left: iconSize + screenWidth * (12 / 402), // 아이콘 + 간격만큼 왼쪽 패딩
                              ),
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: screenHeight * (12 / 904)),
                                height: 2,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                        ],
                      );
                    }),
                    
                    // 마지막 구분선
                    Padding(
                      padding: EdgeInsets.only(
                        left: screenWidth * (29.97 / 402) + screenWidth * (12 / 402), // 아이콘 + 간격
                      ),
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: screenHeight * (12 / 904)),
                        height: 2,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),

                    SizedBox(height: screenHeight * (12 / 904)),
                    
                    // 합계
                    _buildTotalRow(displayItems, screenWidth, screenHeight),

                    SizedBox(height: screenHeight * (6 / 904)),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: screenHeight * 0.03),
          ],
        ),
      ),
    );
  }

  // 예산 항목
  Widget _buildBudgetItem(Map<String, dynamic> item, double screenWidth, double screenHeight) {
    // 피그마 기준: 아이콘 29.97 x 31.57
    final iconSize = screenWidth * (29.97 / 402);
    
    return Row(
      children: [
        // 아이콘
        Container(
          width: iconSize * (37 / 29.97),
          height: iconSize * (37 / 29.97),
          decoration: const BoxDecoration(
            color: Color(0xFF2C3E50),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.attach_money,
              color: Color(0xFFFAFAFA),
              size: 28,
            ),
          ),
        ),
        SizedBox(width: screenWidth * (12 / 402)),
        
        // 항목명
        Expanded(
          child: Text(
            item['category'] as String,
            style: const TextStyle(
              fontFamily: 'Tmoney RoundWind',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              height: 1.28,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        
        // 금액 (원화 형식)
        Text(
          _formatCurrency(item['amount'] as int),
          style: const TextStyle(
            fontFamily: 'Tmoney RoundWind',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            height: 1.28,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  // 합계 행
  Widget _buildTotalRow(List<Map<String, dynamic>> displayItems, double screenWidth, double screenHeight) {
    // 표시된 모든 예산 항목의 합계 계산
    final totalAmount = displayItems.fold<int>(
      0,
      (sum, item) => sum + (item['amount'] as int),
    );
    
    final iconSize = screenWidth * (29.97 / 402);
    
    return Row(
      children: [
        SizedBox(width: iconSize + screenWidth * (12 / 402)), // 아이콘 + 간격만큼 왼쪽 여백
        const Text(
          '촬영 예산 합계:',
          style: TextStyle(
            fontFamily: 'Tmoney RoundWind',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            height: 1.3,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const Spacer(),
        Text(
          _formatCurrency(totalAmount),
          style: const TextStyle(
            fontFamily: 'Tmoney RoundWind',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            height: 1.3,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
  
  // 원화 포맷 변환
  String _formatCurrency(int amount) {
    if (amount == 0) return '0원';
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatted원';
  }
}
