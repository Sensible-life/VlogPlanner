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

