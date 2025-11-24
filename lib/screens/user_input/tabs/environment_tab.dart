import 'package:flutter/material.dart';

class EnvironmentTab extends StatefulWidget {
  final Function(List<String>)? onEquipmentChanged;
  final Function(String)? onEquipmentCustomChanged;
  final Function(int)? onCrewCountChanged;
  final Function(List<String>)? onRestrictionsChanged;
  final Function(String)? onRestrictionCustomChanged;
  final Map<String, dynamic>? initialValues;

  const EnvironmentTab({
    super.key,
    this.onEquipmentChanged,
    this.onEquipmentCustomChanged,
    this.onCrewCountChanged,
    this.onRestrictionsChanged,
    this.onRestrictionCustomChanged,
    this.initialValues,
  });

  @override
  State<EnvironmentTab> createState() => _EnvironmentTabState();
}

class _EnvironmentTabState extends State<EnvironmentTab> {
  late TextEditingController equipmentCustomController;
  late TextEditingController restrictionCustomController;

  late ScrollController scrollController;
  late FocusNode equipmentCustomFocusNode;
  late FocusNode restrictionCustomFocusNode;

  Set<String> selectedEquipment = {};
  int crewCount = 1;
  Set<String> selectedRestrictions = {};

  final List<Map<String, String>> equipmentOptions = [
    {'label': '스마트폰', 'value': 'smartphone'},
    {'label': 'DSLR', 'value': 'dslr'},
    {'label': '액션캠', 'value': 'action_cam'},
    {'label': '삼각대', 'value': 'tripod'},
    {'label': '짐벌', 'value': 'gimbal'},
    {'label': '마이크', 'value': 'microphone'},
  ];

  final List<Map<String, String>> restrictionOptions = [
    {'label': '시간 부족', 'value': 'time_limit'},
    {'label': '예산 부족', 'value': 'budget_limit'},
    {'label': '혼자 촬영', 'value': 'solo_shooting'},
    {'label': '낯가림/출연 부담', 'value': 'camera_shy'},
  ];

  @override
  void initState() {
    super.initState();

    scrollController = ScrollController();
    equipmentCustomFocusNode = FocusNode();
    restrictionCustomFocusNode = FocusNode();

    equipmentCustomController = TextEditingController(
      text: widget.initialValues?['equipment_custom'] ?? '',
    );
    restrictionCustomController = TextEditingController(
      text: widget.initialValues?['restriction_custom'] ?? '',
    );

    // 초기 장비 선택
    if (widget.initialValues?['equipment'] is List<String>) {
      selectedEquipment = Set<String>.from(widget.initialValues!['equipment'] as List<String>);
    }

    // 초기 촬영 인원
    crewCount = widget.initialValues?['crew_count'] ?? 1;

    // 초기 제약 선택
    if (widget.initialValues?['restrictions'] is List<String>) {
      selectedRestrictions = Set<String>.from(widget.initialValues!['restrictions'] as List<String>);
    }

    equipmentCustomController.addListener(() {
      widget.onEquipmentCustomChanged?.call(equipmentCustomController.text);
    });

    restrictionCustomController.addListener(() {
      widget.onRestrictionCustomChanged?.call(restrictionCustomController.text);
    });

    // FocusNode 리스너 추가 - 포커스 시 자동 스크롤
    equipmentCustomFocusNode.addListener(() {
      if (equipmentCustomFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          final context = equipmentCustomFocusNode.context;
          if (context != null) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              alignment: 0.05,
            );
          }
        });
      }
    });

    restrictionCustomFocusNode.addListener(() {
      if (restrictionCustomFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          final context = restrictionCustomFocusNode.context;
          if (context != null) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              alignment: 0.05,
            );
          }
        });
      }
    });

  }

  @override
  void dispose() {
    scrollController.dispose();
    equipmentCustomFocusNode.dispose();
    restrictionCustomFocusNode.dispose();
    equipmentCustomController.dispose();
    restrictionCustomController.dispose();
    super.dispose();
  }

  void _toggleEquipment(String value) {
    setState(() {
      if (selectedEquipment.contains(value)) {
        selectedEquipment.remove(value);
      } else {
        selectedEquipment.add(value);
      }
      widget.onEquipmentChanged?.call(selectedEquipment.toList());
    });
  }

  void _incrementCrewCount() {
    setState(() {
      crewCount++;
      widget.onCrewCountChanged?.call(crewCount);
    });
  }

  void _decrementCrewCount() {
    if (crewCount > 1) {
      setState(() {
        crewCount--;
        widget.onCrewCountChanged?.call(crewCount);
      });
    }
  }

  void _toggleRestriction(String value) {
    setState(() {
      if (selectedRestrictions.contains(value)) {
        selectedRestrictions.remove(value);
      } else {
        selectedRestrictions.add(value);
      }
      widget.onRestrictionsChanged?.call(selectedRestrictions.toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final baseWidth = 402.0;
    final baseHeight = 904.0;

    return SingleChildScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: screenWidth * 0.928, // 373/402
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.036), // (402-373)/2 / 402
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * (29 / baseHeight)), // 탭바와 첫 소제목 거리

            // 사용 장비
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / baseWidth)),
              child: Text(
                '사용 장비',
                style: TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontWeight: FontWeight.w800,
                  fontSize: 20 * (screenWidth / baseWidth),
                  height: 26 / 20,
                  color: const Color(0xFF303030),
                ),
              ),
            ),
            SizedBox(height: screenHeight * (8 / baseHeight)), // 소제목과 입력창 거리
            Wrap(
              spacing: 8.0 * (screenWidth / baseWidth),
              runSpacing: 8.0 * (screenHeight / baseHeight),
              children: equipmentOptions.map((option) {
                return _buildEquipmentChip(
                  option['label']!,
                  option['value']!,
                  screenWidth,
                  screenHeight,
                  baseWidth,
                  baseHeight,
                );
              }).toList(),
            ),

            SizedBox(height: 12 * (screenHeight / baseHeight)),

            // 기타 장비 입력
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: 56.0 * (screenHeight / baseHeight),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
                  top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
                  right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
                  bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
                ),
              ),
              child: TextField(
                controller: equipmentCustomController,
                focusNode: equipmentCustomFocusNode,
                scrollPadding: const EdgeInsets.only(bottom: 100),
                maxLines: null,
                minLines: 1,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: '기타 장비 입력...',
                  hintStyle: TextStyle(
                    fontFamily: 'Tmoney RoundWind',
                    fontWeight: FontWeight.w800,
                    fontSize: 20 * (screenWidth / baseWidth),
                    color: const Color(0xFFB2B2B2),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16 * (screenWidth / baseWidth),
                    vertical: 8 * (screenHeight / baseHeight),
                  ),
                  isDense: true,
                ),
                style: TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontWeight: FontWeight.w800,
                  fontSize: 20 * (screenWidth / baseWidth),
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),

            SizedBox(height: screenHeight * (25 / baseHeight)), // 내용과 다음 소제목 거리

            // 촬영 인원
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / baseWidth)),
              child: Text(
                '촬영 인원',
                style: TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontWeight: FontWeight.w800,
                  fontSize: 20 * (screenWidth / baseWidth),
                  height: 26 / 20,
                  color: const Color(0xFF303030),
                ),
              ),
            ),
            SizedBox(height: screenHeight * (8 / baseHeight)),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // - 버튼
                GestureDetector(
                  onTap: _decrementCrewCount,
                  child: Container(
                    width: 28,
                    height: 27,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3E50),
                      borderRadius: BorderRadius.circular(7),
                      border: const Border(
                        left: BorderSide(color: Color(0xFF1A1A1A), width: 2),
                        top: BorderSide(color: Color(0xFF1A1A1A), width: 2),
                        right: BorderSide(color: Color(0xFF1A1A1A), width: 5),
                        bottom: BorderSide(color: Color(0xFF1A1A1A), width: 5),
                      ),
                    ),
                    child: Transform.translate(
                      offset: const Offset(0, -4),
                      child: const Center(
                        child: Text(
                          '-',
                          style: TextStyle(
                            fontFamily: 'Tmoney RoundWind',
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            height: 1.29,
                            color: Color(0xFFFAFAFA),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 8 * (screenWidth / baseWidth)),

                // 숫자 표시
                Container(
                  width: 80 * (screenWidth / baseWidth),
                  height: 38.0 * (screenHeight / baseHeight),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(7),
                    border: const Border(
                      left: BorderSide(color: Color(0xFF1A1A1A), width: 2),
                      top: BorderSide(color: Color(0xFF1A1A1A), width: 2),
                      right: BorderSide(color: Color(0xFF1A1A1A), width: 5),
                      bottom: BorderSide(color: Color(0xFF1A1A1A), width: 5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$crewCount명',
                      style: TextStyle(
                        fontFamily: 'Tmoney RoundWind',
                        fontWeight: FontWeight.w800,
                        fontSize: 18 * (screenWidth / baseWidth),
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 8 * (screenWidth / baseWidth)),

                // + 버튼
                GestureDetector(
                  onTap: _incrementCrewCount,
                  child: Container(
                    width: 28,
                    height: 27,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3E50),
                      borderRadius: BorderRadius.circular(7),
                      border: const Border(
                        left: BorderSide(color: Color(0xFF1A1A1A), width: 2),
                        top: BorderSide(color: Color(0xFF1A1A1A), width: 2),
                        right: BorderSide(color: Color(0xFF1A1A1A), width: 5),
                        bottom: BorderSide(color: Color(0xFF1A1A1A), width: 5),
                      ),
                    ),
                    child: Transform.translate(
                      offset: const Offset(0, -4),
                      child: const Center(
                        child: Text(
                          '+',
                          style: TextStyle(
                            fontFamily: 'Tmoney RoundWind',
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            height: 1.29,
                            color: Color(0xFFFAFAFA),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: screenHeight * (25 / baseHeight)),

            // 촬영 제약
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / baseWidth)),
              child: Text(
                '촬영 제약',
                style: TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontWeight: FontWeight.w800,
                  fontSize: 20 * (screenWidth / baseWidth),
                  height: 26 / 20,
                  color: const Color(0xFF303030),
                ),
              ),
            ),
            SizedBox(height: screenHeight * (8 / baseHeight)),
            Wrap(
              spacing: 8.0 * (screenWidth / baseWidth),
              runSpacing: 8.0 * (screenHeight / baseHeight),
              children: restrictionOptions.map((option) {
                return _buildRestrictionChip(
                  option['label']!,
                  option['value']!,
                  screenWidth,
                  screenHeight,
                  baseWidth,
                  baseHeight,
                );
              }).toList(),
            ),

            SizedBox(height: 12 * (screenHeight / baseHeight)),

            // 기타 제약 입력
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: 56.0 * (screenHeight / baseHeight),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
                  top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
                  right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
                  bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
                ),
              ),
              child: TextField(
                controller: restrictionCustomController,
                focusNode: restrictionCustomFocusNode,
                scrollPadding: const EdgeInsets.only(bottom: 100),
                maxLines: null,
                minLines: 1,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: '기타 제약 입력...',
                  hintStyle: TextStyle(
                    fontFamily: 'Tmoney RoundWind',
                    fontWeight: FontWeight.w800,
                    fontSize: 20 * (screenWidth / baseWidth),
                    color: const Color(0xFFB2B2B2),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16 * (screenWidth / baseWidth),
                    vertical: 8 * (screenHeight / baseHeight),
                  ),
                  isDense: true,
                ),
                style: TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontWeight: FontWeight.w800,
                  fontSize: 20 * (screenWidth / baseWidth),
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),

            SizedBox(height: 150 * (screenHeight / baseHeight)), // 버튼 공간 확보 (버튼 높이 84px + 여유 공간)
          ],
        ),
      ),
    );
  }

  // 장비 칩 (멀티 선택)
  Widget _buildEquipmentChip(
    String label,
    String value,
    double screenWidth,
    double screenHeight,
    double baseWidth,
    double baseHeight,
  ) {
    final isSelected = selectedEquipment.contains(value);

    return GestureDetector(
      onTap: () => _toggleEquipment(value),
      child: IntrinsicWidth(
        child: Container(
          height: 38.0 * (screenHeight / baseHeight), // 목표 영상 길이 버튼과 동일한 높이
          padding: EdgeInsets.symmetric(
            horizontal: 16 * (screenWidth / baseWidth),
          ),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF455D75) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(10),
            border: const Border(
              left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
              top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
              right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
              bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Tmoney RoundWind',
                fontWeight: FontWeight.w800,
                fontSize: 18 * (screenWidth / baseWidth),
                height: 23 / 18,
                color: isSelected ? const Color(0xFFFAFAFA) : const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 제약 칩 (멀티 선택)
  Widget _buildRestrictionChip(
    String label,
    String value,
    double screenWidth,
    double screenHeight,
    double baseWidth,
    double baseHeight,
  ) {
    final isSelected = selectedRestrictions.contains(value);

    return GestureDetector(
      onTap: () => _toggleRestriction(value),
      child: IntrinsicWidth(
        child: Container(
          height: 38.0 * (screenHeight / baseHeight), // 목표 영상 길이 버튼과 동일한 높이
          padding: EdgeInsets.symmetric(
            horizontal: 16 * (screenWidth / baseWidth),
          ),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF455D75) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(10),
            border: const Border(
              left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
              top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
              right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
              bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Tmoney RoundWind',
                fontWeight: FontWeight.w800,
                fontSize: 18 * (screenWidth / baseWidth),
                height: 23 / 18,
                color: isSelected ? const Color(0xFFFAFAFA) : const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
