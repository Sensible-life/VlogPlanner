import 'package:flutter/material.dart';

class ConceptStyleTab extends StatefulWidget {
  final Function(String)? onSubjectChanged;
  final Function(String)? onDurationChanged;
  final Function(List<String>)? onTonesChanged;
  final Function(String)? onToneCustomChanged;
  final Function(String)? onTargetAudienceChanged;
  final Map<String, dynamic>? initialValues;

  const ConceptStyleTab({
    super.key,
    this.onSubjectChanged,
    this.onDurationChanged,
    this.onTonesChanged,
    this.onToneCustomChanged,
    this.onTargetAudienceChanged,
    this.initialValues,
  });

  @override
  State<ConceptStyleTab> createState() => _ConceptStyleTabState();
}

class _ConceptStyleTabState extends State<ConceptStyleTab> {
  late TextEditingController subjectController;
  late TextEditingController toneCustomController;
  late TextEditingController targetAudienceController;

  late ScrollController scrollController;
  late FocusNode subjectFocusNode;
  late FocusNode toneCustomFocusNode;
  late FocusNode targetAudienceFocusNode;

  String selectedDuration = '10';
  Set<String> selectedTones = {};

  final List<Map<String, String>> toneOptions = [
    {'label': '밝고 활기찬', 'value': 'bright'},
    {'label': '힐링/여유로운', 'value': 'healing'},
    {'label': '힙한/트렌디한', 'value': 'hip'},
    {'label': '재미있는/유머', 'value': 'funny'},
    {'label': '정보전달/깔끔한', 'value': 'informative'},
    {'label': '빈티지/레트로', 'value': 'vintage'},
  ];

  @override
  void initState() {
    super.initState();

    scrollController = ScrollController();
    subjectFocusNode = FocusNode();
    toneCustomFocusNode = FocusNode();
    targetAudienceFocusNode = FocusNode();

    subjectController = TextEditingController(
      text: widget.initialValues?['subject'] ?? '',
    );
    toneCustomController = TextEditingController(
      text: widget.initialValues?['tone_custom'] ?? '',
    );
    targetAudienceController = TextEditingController(
      text: widget.initialValues?['target_audience'] ?? '',
    );

    selectedDuration = widget.initialValues?['target_duration'] ?? '10';

    // 초기 톤 값 처리 (멀티 선택)
    if (widget.initialValues?['tones'] is List<String>) {
      selectedTones = Set<String>.from(widget.initialValues!['tones'] as List<String>);
    }

    subjectController.addListener(() {
      widget.onSubjectChanged?.call(subjectController.text);
    });

    toneCustomController.addListener(() {
      widget.onToneCustomChanged?.call(toneCustomController.text);
    });

    targetAudienceController.addListener(() {
      widget.onTargetAudienceChanged?.call(targetAudienceController.text);
    });

    // FocusNode 리스너 추가 - 포커스 시 자동 스크롤
    subjectFocusNode.addListener(() {
      if (subjectFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          final context = subjectFocusNode.context;
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

    toneCustomFocusNode.addListener(() {
      if (toneCustomFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          final context = toneCustomFocusNode.context;
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

    targetAudienceFocusNode.addListener(() {
      if (targetAudienceFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          final context = targetAudienceFocusNode.context;
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
    subjectFocusNode.dispose();
    toneCustomFocusNode.dispose();
    targetAudienceFocusNode.dispose();
    subjectController.dispose();
    toneCustomController.dispose();
    targetAudienceController.dispose();
    super.dispose();
  }

  void _toggleTone(String value) {
    setState(() {
      if (selectedTones.contains(value)) {
        selectedTones.remove(value);
      } else {
        selectedTones.add(value);
      }
      widget.onTonesChanged?.call(selectedTones.toList());
    });
  }

  void _selectDuration(String value) {
    setState(() {
      selectedDuration = value;
      widget.onDurationChanged?.call(value);
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

            // 촬영 주제
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / baseWidth)),
              child: Text(
                '촬영 주제',
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
                controller: subjectController,
                focusNode: subjectFocusNode,
                scrollPadding: const EdgeInsets.only(bottom: 100),
                maxLines: null,
                minLines: 1,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: '예: 바르셀로나 여행기',
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

            // 목표 영상 길이
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / baseWidth)),
              child: Text(
                '목표 영상 길이',
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDurationButton('5분', '5', screenWidth, screenHeight, baseWidth, baseHeight),
                _buildDurationButton('10분', '10', screenWidth, screenHeight, baseWidth, baseHeight),
                _buildDurationButton('15분', '15', screenWidth, screenHeight, baseWidth, baseHeight),
                _buildDurationButton('20+', '20', screenWidth, screenHeight, baseWidth, baseHeight),
              ],
            ),

            SizedBox(height: screenHeight * (25 / baseHeight)),

            // 영상 톤
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / baseWidth)),
              child: Text(
                '영상 톤',
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
              children: toneOptions.map((option) {
                return _buildToneChip(
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

            // 기타 톤 입력
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
                controller: toneCustomController,
                focusNode: toneCustomFocusNode,
                scrollPadding: const EdgeInsets.only(bottom: 100),
                maxLines: null,
                minLines: 1,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: '기타 톤 입력...',
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

            SizedBox(height: screenHeight * (25 / baseHeight)),

            // 대상 시청자
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / baseWidth)),
              child: Text(
                '대상 시청자',
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
                controller: targetAudienceController,
                focusNode: targetAudienceFocusNode,
                scrollPadding: const EdgeInsets.only(bottom: 100),
                maxLines: null,
                minLines: 1,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: '예: 20대 남성',
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

  // 목표 영상 길이 버튼
  Widget _buildDurationButton(
    String label,
    String value,
    double screenWidth,
    double screenHeight,
    double baseWidth,
    double baseHeight,
  ) {
    final isSelected = selectedDuration == value;

    return GestureDetector(
      onTap: () => _selectDuration(value),
      child: Container(
        width: 78.0 * (screenWidth / baseWidth),
        height: 38.0 * (screenHeight / baseHeight),
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
    );
  }

  // 영상 톤 칩 (멀티 선택)
  Widget _buildToneChip(
    String label,
    String value,
    double screenWidth,
    double screenHeight,
    double baseWidth,
    double baseHeight,
  ) {
    final isSelected = selectedTones.contains(value);

    return GestureDetector(
      onTap: () => _toggleTone(value),
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
