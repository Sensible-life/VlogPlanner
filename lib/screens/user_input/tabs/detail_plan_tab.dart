import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';

class DetailPlanTab extends StatefulWidget {
  const DetailPlanTab({super.key});

  @override
  State<DetailPlanTab> createState() => _DetailPlanTabState();
}

class _DetailPlanTabState extends State<DetailPlanTab> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _requiredLocationController = TextEditingController();
  final TextEditingController _topicsController = TextEditingController();
  
  // 레퍼런스 체크 상태
  final Map<String, bool> _styleReferences = {
    '브이로그 스타일 - 일상 기록형': false,
    '토크 중심 - 대화형': false,
    '리뷰/후기 형식': false,
    '튜토리얼/설명형': false,
    '챌린지/이벤트형': false,
  };

  @override
  void dispose() {
    _locationController.dispose();
    _requiredLocationController.dispose();
    _topicsController.dispose();
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
      maxLines: null,
      minLines: 1,
      keyboardType: TextInputType.multiline,
      autocorrect: false,
      enableSuggestions: false,
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
                  const SizedBox(height: 14),
                  // 1. 촬영 장소 (필수)
                  _buildTitle('촬영 장소', Icons.location_on, isRequired: true),
                  const SizedBox(height: 12),
                  _inputField(_locationController, '예: 카페, 공원, 스튜디오'),
                  const SizedBox(height: 36),
                  
                  // 2. 필수 촬영 장소 (선택)
                  _buildTitle('필수 촬영 장소', Icons.pin_drop),
                  const SizedBox(height: 12),
                  _inputField(_requiredLocationController, '예: 반드시 포함되어야 할 특정 장소'),
                  const SizedBox(height: 36),
                  
                  // 3. 대화 주제 (선택)
                  _buildTitle('대화 주제', Icons.chat_bubble_outline),
                  const SizedBox(height: 12),
                  _inputField(_topicsController, '예: 최근 근황, 여행 이야기, 맛집 리뷰'),
                  const SizedBox(height: 36),
                  
                  // 4. 선호 스타일 레퍼런스
                  _buildTitle('선호 스타일 레퍼런스', Icons.bookmark_border),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      children: _styleReferences.keys.map((reference) {
                        return CheckboxListTile(
                          title: Text(
                            reference,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          value: _styleReferences[reference],
                          activeColor: AppColors.primary,
                          checkColor: Colors.white,
                          onChanged: (bool? value) {
                            setState(() {
                              _styleReferences[reference] = value ?? false;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  
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

