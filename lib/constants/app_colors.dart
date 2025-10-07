import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상 상수
class AppColors {
  // 기본 색상 (커스텀)
  static const Color black = Color(0xFF353535);
  static const Color white = Color(0xFFFBFBFB);
  static const Color grey = Color(0xFF888888);
  static const Color green = Color(0xFF3C6E71);
  
  // Primary 색상
  static const Color primary = green;
  
  // 텍스트 색상
  static const Color textPrimary = Color(0xFFFFFFFF);      // 흰색 (검은 배경용)
  static const Color textSecondary = Color(0xFFBBBBBB);    // 연한 회색
  
  // 상태 색상
  static const Color error = Colors.red;
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  
  // 배경 색상
  static const Color background = black;
  static const Color cardBackground = Color(0xFF454545);   // 약간 밝은 회색
}

