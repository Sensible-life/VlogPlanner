import 'package:flutter/material.dart';
import '../../../services/vlog_data_service.dart';
import '../../../ui/styles.dart';

class EtcTab extends StatefulWidget {
  final VlogDataService dataService;

  const EtcTab({
    super.key,
    required this.dataService,
  });

  @override
  State<EtcTab> createState() => _EtcTabState();
}

class _EtcTabState extends State<EtcTab> {
  List<ChecklistItem> checklistItems = [];
  final TextEditingController _memoController = TextEditingController();
  final Map<int, TextEditingController> _itemControllers = {};
  final Map<int, FocusNode> _itemFocusNodes = {};
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _initializeChecklist();
  }

  void _initializeChecklist() {
    final plan = widget.dataService.plan;
    if (plan?.shootingChecklist != null) {
      checklistItems = plan!.shootingChecklist!
          .map((item) => ChecklistItem(
                text: item.replaceAll('✓', '').trim(),
                isChecked: false,
              ))
          .toList();
      
      // 각 항목에 대한 컨트롤러와 포커스 노드 생성
      for (int i = 0; i < checklistItems.length; i++) {
        _itemControllers[i] = TextEditingController(text: checklistItems[i].text);
        _itemFocusNodes[i] = FocusNode();
      }
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    _itemControllers.forEach((_, controller) => controller.dispose());
    _itemFocusNodes.forEach((_, node) => node.dispose());
    super.dispose();
  }

  void _addChecklistItem() {
    setState(() {
      final newIndex = checklistItems.length;
      checklistItems.add(ChecklistItem(text: '', isChecked: false));
      _itemControllers[newIndex] = TextEditingController(text: '');
      _itemFocusNodes[newIndex] = FocusNode();
      _editingIndex = newIndex;
      
      // 다음 프레임에서 포커스 설정
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _itemFocusNodes[newIndex]?.requestFocus();
      });
    });
  }

  void _toggleChecklistItem(int index) {
    setState(() {
      checklistItems[index].isChecked = !checklistItems[index].isChecked;
    });
  }

  void _startEditing(int index) {
    setState(() {
      _editingIndex = index;
    });
    _itemFocusNodes[index]?.requestFocus();
  }

  void _finishEditing(int index) {
    setState(() {
      checklistItems[index].text = _itemControllers[index]?.text ?? '';
      _editingIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.dataService.plan;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (plan == null) {
      return Center(child: Text('데이터를 불러올 수 없습니다'));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: screenWidth * 0.928, // 373/402
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.036),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 체크리스트 헤더 (제목 + 추가 버튼)
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / 402)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '체크리스트',
                    style: const TextStyle(
                      fontFamily: 'Tmoney RoundWind',
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      height: 1.29,
                      letterSpacing: -0.72,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  GestureDetector(
                    onTap: _addChecklistItem,
                    child: Container(
                      width: 28,
                      height: 27,
                      decoration: BoxDecoration(
                        color: Color(0xFF2C3E50),
                        borderRadius: BorderRadius.circular(7),
                        border: Border(
                          left: BorderSide(color: Color(0xFF1A1A1A), width: 2),
                          top: BorderSide(color: Color(0xFF1A1A1A), width: 2),
                          right: BorderSide(color: Color(0xFF1A1A1A), width: 5),
                          bottom: BorderSide(color: Color(0xFF1A1A1A), width: 5),
                        ),
                      ),
                      child: Transform.translate(
                        offset: Offset(0, -4),
                        child: Center(
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
            ),
            SizedBox(height: AppDims.marginSubtitleToContent(screenHeight)),

            // 체크리스트 컨테이너
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(15),
                border: Border(
                  left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
                  top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
                  right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
                  bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
                ),
              ),
              child: Column(
                children: checklistItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isEditing = _editingIndex == index;
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: index < checklistItems.length - 1 ? 21 : 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _toggleChecklistItem(index),
                          child: Container(
                            width: 21,
                            height: 21,
                            decoration: BoxDecoration(
                              color: Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Color(0xFF1A1A1A), width: 2),
                            ),
                            child: item.isChecked
                                ? CustomPaint(
                                    painter: CheckmarkPainter(),
                                  )
                                : null,
                          ),
                        ),
                        SizedBox(width: 21),
                        Expanded(
                          child: isEditing
                              ? TextField(
                                  controller: _itemControllers[index],
                                  focusNode: _itemFocusNodes[index],
                                  onSubmitted: (_) => _finishEditing(index),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: '항목 입력...',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Tmoney RoundWind',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      height: 1.2,
                                      color: Color(0xFFB2B2B2),
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Tmoney RoundWind',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                    height: 1.2,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () => _startEditing(index),
                                  child: Text(
                                    item.text.isEmpty ? '항목 입력...' : item.text,
                                    style: TextStyle(
                                      fontFamily: 'Tmoney RoundWind',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      height: 1.2,
                                      color: item.text.isEmpty
                                          ? Color(0xFFB2B2B2)
                                          : (item.isChecked ? Color(0xFFB2B2B2) : Color(0xFF1A1A1A)),
                                      decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 65),

            // 메모 헤더 (제목만, + 버튼은 제거)
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / 402)),
              child: Text(
                '메모',
                style: const TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  height: 1.29,
                  letterSpacing: -0.72,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            SizedBox(height: AppDims.marginSubtitleToContent(screenHeight)),

            // 메모 컨테이너
            Container(
              width: double.infinity,
              height: 99,
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(15),
                border: Border(
                  left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
                  top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
                  right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
                  bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
                ),
              ),
              child: TextField(
                controller: _memoController,
                maxLines: null,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class ChecklistItem {
  String text;
  bool isChecked;

  ChecklistItem({required this.text, required this.isChecked});
}

// 체크 마크를 그리는 CustomPainter
class CheckmarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF1A1A1A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.45, size.height * 0.75);
    path.lineTo(size.width * 0.8, size.height * 0.25);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
