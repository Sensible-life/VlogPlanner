import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 상수 (Film Mode)
class AppColors {
  // ========== FILM AESTHETIC PALETTE ==========
  
  // 아날로그 필름 톤 - 흑백 & warm gray
  static const Color filmBlack = Color(0xFF1A1A1A);           // 순수한 검정 (잉크)
  static const Color filmGray = Color(0xFF3A3A3A);            // 진한 회색 (그림자)
  static const Color filmMediumGray = Color(0xFF6B6B6B);      // 중간 회색
  static const Color filmLightGray = Color(0xFF9B9B9B);       // 연한 회색
  static const Color filmBorder = Color(0xFFD5D5D5);          // 얇은 테두리
  
  // 종이 질감 - warm off-white
  static const Color paper = Color(0xFFFFFFFF);               // 크림화이트 (메인 배경)
  static const Color paperLight = Color(0xFFFBFAF8);          // 밝은 종이
  static const Color paperWarm = Color(0xFFF5F3F0);           // 따뜻한 종이
  
  // Brand Colors
  static const Color brandBlue = Color(0xFF0DBBB5);    // Primary Blue
  static const Color brandGreen = Color(0xFF63BF78);   // Secondary Green
  
  // Legacy compatibility
  static const Color black = filmBlack;
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = filmMediumGray;
  static const Color lightGrey = filmBorder;
  static const Color green = brandGreen; // Brand Green
  
  // Primary 색상
  static const Color primary = brandBlue;  // Brand Blue
  
  // 텍스트 색상
  static const Color textPrimary = filmBlack;         // 잉크 블랙
  static const Color textSecondary = filmMediumGray;  // 연한 잉크
  
  // 상태 색상
  static const Color error = Color(0xFFC41E3A);       // 어두운 빨강
  static const Color success = brandGreen;            // Brand Green
  static const Color warning = Color(0xFFD68910);     // 따뜻한 주황
  
  // 배경 색상
  static const Color background = paper;              // 크림화이트 배경
  static const Color cardBackground = paperLight;     // 밝은 종이 카드
  
  // Film-specific colors
  static const Color filmStripBorder = Color(0xFFB8B8B8);  // 필름 테두리
  static const Color pencilLine = Color(0xFF8B8B8B);       // 연필 라인
  
  // Deprecated but kept for compatibility
  static const Color primaryAccent = primary;  // Legacy compatibility
  static const Color border = filmBorder;       // Legacy compatibility
}

