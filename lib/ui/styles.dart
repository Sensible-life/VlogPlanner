import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 상수
class AppColors {
  // 기본 색상
  static const Color black = Color(0xFF1A1A1A);  // 검정
  static const Color white = Color(0xFFFAFAFA);  // 화이트
  static const Color gray = Color(0xFFB2B2B2);  // 회색

  // 배경색
  static const Color background = Color(0xFFCEDCD3);  // 배경 바탕색

  // 키컬러
  static const Color primary = Color(0xFF455D75);  // 키컬러1
  static const Color secondary = Color(0xFF2C3E50);  // 키컬러2

  // 텍스트 색상 (기본 팔레트 활용)
  static const Color textPrimary = black;
  static const Color textSecondary = gray;
}

/// 앱 전체에서 사용하는 크기/간격 상수
class AppDims {
  // Border Radius
  static const double r4 = 4.0;
  static const double r8 = 8.0;
  static const double r10 = 10.0;
  static const double r15 = 15.0;
  
  // Border Width
  static const double border1 = 1.0;
  static const double border2 = 2.0;
  
  // Padding
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p24 = 24.0;
  
  // Margins (based on screen height of 904px)
  // 소제목과 내용 사이의 마진: screenHeight * (12/904)
  static double marginSubtitleToContent(double screenHeight) => screenHeight * (12 / 904);
  
  // 이전 내용과 소제목 사이의 마진: screenHeight * (24/904)
  static double marginContentToSubtitle(double screenHeight) => screenHeight * (24 / 904);
}

/// 앱 전체에서 사용하는 텍스트 스타일
class AppText {
  // 타이틀
  static const TextStyle title56 = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w800,
    color: AppColors.black,
    height: 1.1,
    fontFamily: 'Tmoney RoundWind',
  );

  static const TextStyle title32 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.black,
    height: 1.1,
    fontFamily: 'Tmoney RoundWind',
  );

  // 카드 타이틀
  static const TextStyle cardTitle24 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.2,
    fontFamily: 'Tmoney RoundWind',
  );

  // 카드 메타 정보
  static const TextStyle cardMeta14 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
    fontFamily: 'Tmoney RoundWind',
  );

  // 버튼 텍스트
  static const TextStyle button18 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.black,
    fontFamily: 'Tmoney RoundWind',
  );
}
