import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';

class EnvironmentTab extends StatefulWidget {
  final Function(String)? onEquipmentChanged;
  final Function(String)? onTimeWeatherChanged;
  final Function(String)? onDifficultyChanged;
  final Function(String, String)? onInputChanged;  // key, value 형태
  final Map<String, String>? initialValues;  // 초기값 전달

  const EnvironmentTab({
    super.key,
    this.onEquipmentChanged,
    this.onTimeWeatherChanged,
    this.onDifficultyChanged,
    this.onInputChanged,
    this.initialValues,
  });

  @override
  State<EnvironmentTab> createState() => _EnvironmentTabState();
}

class _EnvironmentTabState extends State<EnvironmentTab> {
  final TextEditingController _timeWeatherController = TextEditingController();
  final TextEditingController _crewCountController = TextEditingController();
  final TextEditingController _restrictionsController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _customEquipmentController = TextEditingController();
  
  String _selectedEquipment = '스마트폰';
  String _selectedLevel = '입문';

  @override
  void initState() {
    super.initState();
    
    // 초기값 설정
    if (widget.initialValues != null) {
      _timeWeatherController.text = widget.initialValues!['time_weather'] ?? '';
      _crewCountController.text = widget.initialValues!['people'] ?? '';
      _restrictionsController.text = widget.initialValues!['restrictions'] ?? '';
      _memoController.text = widget.initialValues!['memo'] ?? '';
      
      // equipment 값 복원
      final equipment = widget.initialValues!['equipment'];
      if (equipment != null && equipment.isNotEmpty) {
        if (['smartphone', '액션캠', 'DSLR/미러리스', '짐벌'].contains(equipment) || 
            ['스마트폰', '액션캠', 'DSLR/미러리스', '짐벌'].contains(equipment)) {
          _selectedEquipment = equipment;
        } else {
          _selectedEquipment = '기타';
          _customEquipmentController.text = equipment;
        }
      }
      
      // difficulty 값 복원
      final difficulty = widget.initialValues!['difficulty'];
      if (difficulty != null) {
        switch (difficulty) {
          case 'novice':
            _selectedLevel = '입문';
            break;
          case 'intermediate':
            _selectedLevel = '중급';
            break;
          case 'advanced':
            _selectedLevel = '고급';
            break;
        }
      }
    }
    
    // 초기 선택값 콜백 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onEquipmentChanged?.call(_selectedEquipment);
      widget.onDifficultyChanged?.call('novice'); // 입문 = novice
    });

    // time_weather TextField에 리스너 추가
    _timeWeatherController.addListener(() {
      if (_timeWeatherController.text.isNotEmpty) {
        widget.onTimeWeatherChanged?.call(_timeWeatherController.text);
      }
    });
    // 커스텀 장비 TextField에 리스너 추가
    _customEquipmentController.addListener(() {
      if (_selectedEquipment == '기타' && _customEquipmentController.text.isNotEmpty) {
        widget.onEquipmentChanged?.call(_customEquipmentController.text);
      }
    });
    
    // crew_count, restrictions, memo TextField에 리스너 추가
    _crewCountController.addListener(() {
      widget.onInputChanged?.call('crew_count', _crewCountController.text);
    });
    _restrictionsController.addListener(() {
      widget.onInputChanged?.call('restrictions', _restrictionsController.text);
    });
    _memoController.addListener(() {
      widget.onInputChanged?.call('memo', _memoController.text);
    });
  }

  @override
  void dispose() {
    _timeWeatherController.dispose();
    _crewCountController.dispose();
    _restrictionsController.dispose();
    _memoController.dispose();
    _customEquipmentController.dispose();
    super.dispose();
  }

  Widget _buildTitle(String title, IconData icon, {bool isRequired = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: AppColors.primary,
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
        fillColor: AppColors.lightGrey,
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

  Widget _buildOption(String option, String groupValue, Function(String) onSelect) {
    final isSelected = groupValue == option;
    return GestureDetector(
      onTap: () => onSelect(option),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Center(
          child: Text(
            option,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
                  
                  // 1. 시간/날씨
                  _buildTitle('시간/날씨', Icons.wb_sunny, isRequired: true),
                  const SizedBox(height: 12),
                  _inputField(_timeWeatherController, '예: 낮/맑음, 저녁/흐림'),
                  const SizedBox(height: 32),
                  
                  // 2. 사용 장비
                  _buildTitle('사용 장비', Icons.camera_alt, isRequired: true),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOption('스마트폰', _selectedEquipment, (value) {
                          setState(() => _selectedEquipment = value);
                          widget.onEquipmentChanged?.call(value);
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOption('고프로', _selectedEquipment, (value) {
                          setState(() => _selectedEquipment = value);
                          widget.onEquipmentChanged?.call(value);
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOption('기타', _selectedEquipment, (value) {
                          setState(() => _selectedEquipment = value);
                        }),
                      ),
                    ],
                  ),
                  if (_selectedEquipment == '기타') ...[
                    const SizedBox(height: 12),
                    _inputField(_customEquipmentController, '예: DSLR, 미러리스'),
                  ],
                  const SizedBox(height: 32),
                  
                  // 3. 촬영 경험 수준
                  _buildTitle('촬영 경험 수준', Icons.bar_chart, isRequired: true),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOption('입문', _selectedLevel, (value) {
                          setState(() => _selectedLevel = value);
                          widget.onDifficultyChanged?.call('novice');
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOption('숙련', _selectedLevel, (value) {
                          setState(() => _selectedLevel = value);
                          widget.onDifficultyChanged?.call('intermediate');
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOption('전문가', _selectedLevel, (value) {
                          setState(() => _selectedLevel = value);
                          widget.onDifficultyChanged?.call('expert');
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // 4. 촬영 인원
                  _buildTitle('촬영 인원', Icons.people, isRequired: true),
                  const SizedBox(height: 12),
                  _inputField(_crewCountController, '예: 3명'),
                  const SizedBox(height: 32),
                  
                  // 5. 금지 제약
                  _buildTitle('촬영 제약', Icons.block),
                  const SizedBox(height: 12),
                  _inputField(_restrictionsController, '예: 실내 촬영 금지, 음향 사용 제한'),
                  const SizedBox(height: 32),
                  
                  // 6. 기타 메모
                  _buildTitle('기타 메모', Icons.edit_note),
                  const SizedBox(height: 12),
                  _inputField(_memoController, '추가로 고려해야 할 사항/메모를 자유롭게 입력하세요'),
                  
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
