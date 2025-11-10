import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class BudgetService {
  static const String _naverBaseUrl = 'https://openapi.naver.com/v1/search/local.json';
  static const String _googlePlacesBaseUrl = 'https://maps.googleapis.com/maps/api/place';
  
  static String? get _naverClientId => ApiConfig.naverClientId;
  static String? get _naverClientSecret => ApiConfig.naverClientSecret;
  static String? get _googleMapsApiKey => ApiConfig.googleMapsApiKey;

  /// 촬영 장소 기반 예산 정보 조회
  ///
  /// [location]: 촬영 장소 (예: "오월드", "롯데월드")
  /// [categories]: 예산 카테고리 (예: ["입장료", "식사", "교통"])
  static Future<List<Map<String, dynamic>>?> getBudgetEstimate({
    required String location,
    required List<String> categories,
  }) async {
    try {
      print('[BUDGET_SERVICE] 예산 정보 조회: $location');

      final budgetItems = <Map<String, dynamic>>[];

      // 각 카테고리별로 정보 조회
      for (final category in categories) {
        final item = await _getBudgetForCategory(location, category);
        if (item != null) {
          budgetItems.add(item);
        }
      }

      // API 사용 불가능한 경우 Mock 데이터 반환
      if (budgetItems.isEmpty) {
        return _getMockBudgetData(location, categories);
      }

      print('[BUDGET_SERVICE] 예산 정보 조회 완료: ${budgetItems.length}개 항목');
      return budgetItems;
    } catch (e) {
      print('[BUDGET_SERVICE] 예산 조회 예외: $e');
      return _getMockBudgetData(location, categories);
    }
  }

  /// 카테고리별 예산 정보 조회
  static Future<Map<String, dynamic>?> _getBudgetForCategory(
    String location,
    String category,
  ) async {
    try {
      // 1. Google Places API를 사용하여 실제 가격 정보 조회 시도
      if (_googleMapsApiKey != null) {
        final googlePrice = await _getPriceFromGooglePlaces(location, category);
        if (googlePrice != null) {
          print('[BUDGET_SERVICE] Google Places 가격 정보 사용: ${googlePrice['amount']}원');
          return googlePrice;
        }
      }

      // 2. Naver API를 사용하여 장소 검색
      if (_naverClientId != null && _naverClientSecret != null) {
        final query = '$location $category';

        final uri = Uri.parse(_naverBaseUrl).replace(queryParameters: {
          'query': query,
          'display': '5',
        });

        final response = await http.get(
          uri,
          headers: {
            'X-Naver-Client-Id': _naverClientId!,
            'X-Naver-Client-Secret': _naverClientSecret!,
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final items = data['items'] as List<dynamic>;

          if (items.isNotEmpty) {
            // Naver 결과를 사용하여 추정값 반환
            return _estimatePriceFromCategory(category, location);
          }
        }
      }
    } catch (e) {
      print('[BUDGET_SERVICE] 카테고리 조회 예외: $e');
    }

    return null;
  }

  /// Google Places API를 사용하여 가격 정보 조회
  static Future<Map<String, dynamic>?> _getPriceFromGooglePlaces(
    String location,
    String category,
  ) async {
    try {
      if (_googleMapsApiKey == null) {
        return null;
      }

      // 검색 쿼리 생성
      final query = '$location $category';

      // 1. 장소 검색
      final searchUri = Uri.parse('$_googlePlacesBaseUrl/textsearch/json').replace(queryParameters: {
        'query': query,
        'key': _googleMapsApiKey!,
      });

      final searchResponse = await http.get(searchUri);

      if (searchResponse.statusCode == 200) {
        final searchData = jsonDecode(searchResponse.body);
        final results = searchData['results'] as List<dynamic>?;

        if (results != null && results.isNotEmpty) {
          final placeId = results[0]['place_id'] as String?;
          
          if (placeId != null) {
            // 2. 장소 상세 정보 조회 (price_level 포함)
            final detailsUri = Uri.parse('$_googlePlacesBaseUrl/details/json').replace(queryParameters: {
              'place_id': placeId,
              'fields': 'price_level,rating,user_ratings_total',
              'key': _googleMapsApiKey!,
            });

            final detailsResponse = await http.get(detailsUri);

            if (detailsResponse.statusCode == 200) {
              final detailsData = jsonDecode(detailsResponse.body);
              final result = detailsData['result'] as Map<String, dynamic>?;

              if (result != null && result.containsKey('price_level')) {
                final priceLevel = result['price_level'] as int?;
                
                if (priceLevel != null) {
                  // price_level을 실제 금액으로 변환
                  final amount = _convertPriceLevelToAmount(priceLevel, category);
                  
                  return {
                    'category': category,
                    'description': _getCategoryDescription(category, location),
                    'amount': amount,
                    'min': (amount * 0.8).round(),
                    'max': (amount * 1.2).round(),
                    'source': 'google',
                  };
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('[BUDGET_SERVICE] Google Places 조회 예외: $e');
    }

    return null;
  }

  /// price_level(1-4)을 실제 금액으로 변환
  static int _convertPriceLevelToAmount(int priceLevel, String category) {
    // price_level: 0=무료, 1=저렴, 2=보통, 3=비쌈, 4=매우비쌈
    // 카테고리별 기본 가격 * price_level 배수
    int basePrice;
    
    if (category.contains('입장료') || category.contains('입장권')) {
      basePrice = 30000;
    } else if (category.contains('식사') || category.contains('점심') || category.contains('저녁')) {
      basePrice = 12000;
    } else if (category.contains('교통') || category.contains('주차')) {
      basePrice = 5000;
    } else if (category.contains('간식') || category.contains('음료')) {
      basePrice = 5000;
    } else if (category.contains('기념품') || category.contains('쇼핑')) {
      basePrice = 20000;
    } else {
      basePrice = 10000;
    }

    // price_level에 따른 가격 조정
    switch (priceLevel) {
      case 0:
        return 0;
      case 1:
        return (basePrice * 0.6).round();
      case 2:
        return (basePrice * 1.0).round();
      case 3:
        return (basePrice * 1.5).round();
      case 4:
        return (basePrice * 2.5).round();
      default:
        return basePrice;
    }
  }

  /// 카테고리 기반 가격 추정
  static Map<String, dynamic> _estimatePriceFromCategory(String category, String location) {
    // 간단한 가격 추정 로직 (실제로는 DB나 더 정확한 API 사용)
    final prices = _getCategoryPriceRange(category, location);

    return {
      'category': category,
      'description': _getCategoryDescription(category, location),
      'amount': prices['estimated'],
      'min': prices['min'],
      'max': prices['max'],
    };
  }

  /// 카테고리별 가격 범위
  static Map<String, int> _getCategoryPriceRange(String category, String location) {
    // 테마파크 기준 가격
    final themeParks = ['오월드', '에버랜드', '롯데월드', '서울랜드'];
    final isThemePark = themeParks.any((park) => location.contains(park));

    if (category.contains('입장료') || category.contains('입장권')) {
      if (isThemePark) {
        return {'min': 30000, 'max': 60000, 'estimated': 45000};
      } else {
        return {'min': 5000, 'max': 15000, 'estimated': 10000};
      }
    } else if (category.contains('식사') || category.contains('점심') || category.contains('저녁')) {
      return {'min': 10000, 'max': 20000, 'estimated': 15000};
    } else if (category.contains('교통') || category.contains('주차')) {
      return {'min': 5000, 'max': 15000, 'estimated': 10000};
    } else if (category.contains('간식') || category.contains('음료')) {
      return {'min': 3000, 'max': 10000, 'estimated': 6000};
    } else if (category.contains('기념품') || category.contains('쇼핑')) {
      return {'min': 10000, 'max': 50000, 'estimated': 20000};
    } else {
      return {'min': 5000, 'max': 15000, 'estimated': 10000};
    }
  }

  /// 카테고리 설명 생성
  static String _getCategoryDescription(String category, String location) {
    if (category.contains('입장료')) {
      return '$location 입장권 (1인 기준)';
    } else if (category.contains('식사')) {
      return '점심 또는 저녁 식사 (1인 기준)';
    } else if (category.contains('교통')) {
      return '교통비 및 주차비';
    } else if (category.contains('간식')) {
      return '간식 및 음료';
    } else if (category.contains('기념품')) {
      return '기념품 및 소품';
    } else {
      return category;
    }
  }

  /// Mock 예산 데이터
  static List<Map<String, dynamic>> _getMockBudgetData(
    String location,
    List<String> categories,
  ) {
    print('[BUDGET_SERVICE] Mock 예산 데이터 사용');

    return categories.map((category) {
      final prices = _getCategoryPriceRange(category, location);
      return {
        'category': category,
        'description': _getCategoryDescription(category, location),
        'amount': prices['estimated'],
        'min': prices['min'],
        'max': prices['max'],
      };
    }).toList();
  }

  /// 예산 총액 계산
  static int calculateTotalBudget(List<Map<String, dynamic>> budgetItems) {
    return budgetItems.fold(
      0,
      (sum, item) => sum + (item['amount'] as int),
    );
  }

  /// 예산 범위 계산 (최소~최대)
  static Map<String, int> calculateBudgetRange(List<Map<String, dynamic>> budgetItems) {
    final min = budgetItems.fold(0, (sum, item) => sum + (item['min'] as int? ?? 0));
    final max = budgetItems.fold(0, (sum, item) => sum + (item['max'] as int? ?? 0));

    return {'min': min, 'max': max};
  }

  /// 예산 항목을 텍스트로 포맷
  static String formatBudgetText(List<Map<String, dynamic>> budgetItems) {
    final buffer = StringBuffer();

    for (final item in budgetItems) {
      buffer.writeln('${item['category']}: ${_formatCurrency(item['amount'] as int)}');
      buffer.writeln('  └ ${item['description']}');
    }

    final total = calculateTotalBudget(budgetItems);
    buffer.writeln('\n총 예상 비용: ${_formatCurrency(total)}');

    return buffer.toString();
  }

  /// 금액 포맷 (원화)
  static String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}원';
  }
}
