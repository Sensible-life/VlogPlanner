import 'package:flutter/material.dart';

class LocationTimeTab extends StatefulWidget {
  final Function(String)? onLocationChanged;
  final Function(List<String>)? onRequiredLocationsChanged;
  final Function(String)? onTimeWeatherChanged;
  final Map<String, dynamic>? initialValues;

  const LocationTimeTab({
    super.key,
    this.onLocationChanged,
    this.onRequiredLocationsChanged,
    this.onTimeWeatherChanged,
    this.initialValues,
  });

  @override
  State<LocationTimeTab> createState() => _LocationTimeTabState();
}

class _LocationTimeTabState extends State<LocationTimeTab> {
  late TextEditingController locationController;
  late TextEditingController timeWeatherController;

  late ScrollController scrollController;
  late FocusNode locationFocusNode;
  late FocusNode timeWeatherFocusNode;

  List<TextEditingController> requiredLocationControllers = [];
  List<FocusNode> requiredLocationFocusNodes = [];

  @override
  void initState() {
    super.initState();

    scrollController = ScrollController();
    locationFocusNode = FocusNode();
    timeWeatherFocusNode = FocusNode();

    locationController = TextEditingController(
      text: widget.initialValues?['location'] ?? '',
    );
    timeWeatherController = TextEditingController(
      text: widget.initialValues?['time_weather'] ?? '',
    );

    // 초기 필수 촬영 장소
    final initialRequiredLocations = widget.initialValues?['required_locations'] as List<String>?;
    if (initialRequiredLocations != null && initialRequiredLocations.isNotEmpty) {
      for (var i = 0; i < initialRequiredLocations.length; i++) {
        final controller = TextEditingController(text: initialRequiredLocations[i]);
        final focusNode = FocusNode();
        controller.addListener(() => _notifyRequiredLocationsChanged());
        requiredLocationControllers.add(controller);
        requiredLocationFocusNodes.add(focusNode);
      }
    } else {
      // 기본 2개의 필수 장소 입력란
      for (int i = 0; i < 2; i++) {
        final controller = TextEditingController();
        final focusNode = FocusNode();
        controller.addListener(() => _notifyRequiredLocationsChanged());
        requiredLocationControllers.add(controller);
        requiredLocationFocusNodes.add(focusNode);
      }
    }

    locationController.addListener(() {
      widget.onLocationChanged?.call(locationController.text);
    });

    timeWeatherController.addListener(() {
      widget.onTimeWeatherChanged?.call(timeWeatherController.text);
    });

    // FocusNode 리스너 추가 - 포커스 시 자동 스크롤
    locationFocusNode.addListener(() {
      if (locationFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          final context = locationFocusNode.context;
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

    timeWeatherFocusNode.addListener(() {
      if (timeWeatherFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          final context = timeWeatherFocusNode.context;
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

    // 필수 장소 FocusNode 리스너 추가
    for (int i = 0; i < requiredLocationFocusNodes.length; i++) {
      requiredLocationFocusNodes[i].addListener(() {
        if (requiredLocationFocusNodes[i].hasFocus) {
          Future.delayed(const Duration(milliseconds: 300), () {
            final context = requiredLocationFocusNodes[i].context;
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

  }

  @override
  void dispose() {
    scrollController.dispose();
    locationFocusNode.dispose();
    timeWeatherFocusNode.dispose();
    locationController.dispose();
    timeWeatherController.dispose();
    for (var controller in requiredLocationControllers) {
      controller.dispose();
    }
    for (var focusNode in requiredLocationFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _notifyRequiredLocationsChanged() {
    final locations = requiredLocationControllers
        .map((c) => c.text)
        .where((text) => text.isNotEmpty)
        .toList();
    widget.onRequiredLocationsChanged?.call(locations);
  }

  void _addRequiredLocation() {
    setState(() {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      controller.addListener(() => _notifyRequiredLocationsChanged());
      requiredLocationControllers.add(controller);
      requiredLocationFocusNodes.add(focusNode);
      
      // 새로 추가된 필수 장소 FocusNode 리스너 추가
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          Future.delayed(const Duration(milliseconds: 300), () {
            final context = focusNode.context;
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
    });
  }

  void _removeRequiredLocation(int index) {
    setState(() {
      requiredLocationControllers[index].dispose();
      requiredLocationFocusNodes[index].dispose();
      requiredLocationControllers.removeAt(index);
      requiredLocationFocusNodes.removeAt(index);
      _notifyRequiredLocationsChanged();
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

            // 촬영 장소
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / baseWidth)),
              child: Text(
                '촬영 장소',
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
                controller: locationController,
                focusNode: locationFocusNode,
                scrollPadding: const EdgeInsets.only(bottom: 100),
                maxLines: null,
                minLines: 1,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: '예: 서울 강남구',
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

            // 필수 촬영 장소
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / baseWidth)),
              child: Text(
                '필수 촬영 장소',
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

            // 필수 장소 리스트
            ...List.generate(
              requiredLocationControllers.length,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: 8 * (screenHeight / baseHeight)),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
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
                          controller: requiredLocationControllers[index],
                          focusNode: requiredLocationFocusNodes[index],
                          scrollPadding: const EdgeInsets.only(bottom: 100),
                          maxLines: null,
                          minLines: 1,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: '장소 ${index + 1}',
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
                    ),
                    if (requiredLocationControllers.length > 2)
                      Padding(
                        padding: EdgeInsets.only(left: 8 * (screenWidth / baseWidth)),
                        child: GestureDetector(
                          onTap: () => _removeRequiredLocation(index),
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
                      ),
                  ],
                ),
              ),
            ),

            // 장소 추가 버튼
            GestureDetector(
              onTap: _addRequiredLocation,
              child: Row(
                children: [
                  Container(
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
                  SizedBox(width: 8 * (screenWidth / baseWidth)),
                  Text(
                    '장소 추가하기',
                    style: TextStyle(
                      fontFamily: 'Tmoney RoundWind',
                      fontWeight: FontWeight.w800,
                      fontSize: 18 * (screenWidth / baseWidth),
                      height: 23 / 18,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * (25 / baseHeight)),

            // 시간/날씨
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / baseWidth)),
              child: Text(
                '시간/날씨',
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
                controller: timeWeatherController,
                focusNode: timeWeatherFocusNode,
                scrollPadding: const EdgeInsets.only(bottom: 100),
                maxLines: null,
                minLines: 1,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: '예: 오후, 맑음',
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
}
