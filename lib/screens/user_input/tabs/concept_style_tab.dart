import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';

class ConceptStyleTab extends StatefulWidget {
  const ConceptStyleTab({super.key});

  @override
  State<ConceptStyleTab> createState() => _ConceptStyleTabState();
}

class _ConceptStyleTabState extends State<ConceptStyleTab> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _targetAudienceController = TextEditingController();
  final TextEditingController _toneMannersController = TextEditingController();
  final TextEditingController _customDurationController = TextEditingController();
  String _selectedDuration = '5분';

  @override
  void dispose() {
    _subjectController.dispose();
    _targetAudienceController.dispose();
    _toneMannersController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  Widget _buildTitle(String title, IconData icon, {bool isRequired = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: AppColors.white,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _inputField(TextEditingController controller, String hintText) {
    return TextField(
      controller: controller,
      maxLines: null,  // 무제한 줄
      minLines: 1,     // 최소 1줄
      keyboardType: TextInputType.multiline,
      autocorrect: false,  // 자동 수정 끄기
      enableSuggestions: false,  // 제안 끄기 (밑줄 제거)
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.cardBackground,
        isDense: true,  // 기본 높이 제약 제거
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDurationOption(String duration) {
    final isSelected = _selectedDuration == duration;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDuration = duration;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Center(
          child: Text(
            duration,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 입력 폼들
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  // 1. 촬영 주제
                  _buildTitle('촬영 주제', Icons.videocam, isRequired: true),
                  const SizedBox(height: 12),
                  _inputField(_subjectController, '예: 친구 2명과 근황 토크 중심의 브이로그'),
                  const SizedBox(height: 32),
                  
                  // 2. 타깃 시청자
                  _buildTitle('타깃 시청자', Icons.group, isRequired: true),
                  const SizedBox(height: 12),
                  _inputField(_targetAudienceController, '예: 20대 친구 / 일반 관람객'),
                  const SizedBox(height: 32),
                  
                  // 3. 영상 톤앤매너
                  _buildTitle('영상 톤&바이브', Icons.palette, isRequired: true),
                  const SizedBox(height: 12),
                  _inputField(_toneMannersController, '예: 밝고 경쾌 / MZ 감성'),
                  const SizedBox(height: 32),
                  
                  // 4. 목표 영상 길이
                  _buildTitle('목표 영상 길이', Icons.timer, isRequired: true),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDurationOption('5분'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDurationOption('10분'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDurationOption('15분'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDurationOption('기타'),
                      ),
                    ],
                  ),
                  if (_selectedDuration == '기타') ...[
                    const SizedBox(height: 12),
                    _inputField(_customDurationController, '예: 20분'),
                  ],
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

