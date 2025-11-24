import 'package:flutter/material.dart';
import '../../services/vlog_data_service.dart'; // Plan도 export됨
import '../../services/storyboard_generation_service.dart';
import '../../services/progress_notification_service.dart';
import '../../widgets/app_notification.dart';
import '../home_page.dart';
import '../storyboard/storyboard_page.dart';
import 'tabs/concept_style_tab.dart';
import 'tabs/location_time_tab.dart';
import 'tabs/environment_tab.dart';

class UserInputPage extends StatefulWidget {
  const UserInputPage({super.key});

  @override
  State<UserInputPage> createState() => _UserInputPageState();
}

class _UserInputPageState extends State<UserInputPage> {
  int _selectedTab = 0; // 0: 컨셉&스타일, 1: 장소&시간, 2: 환경&제약
  bool _isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  

  // 사용자 입력 데이터 저장
  final Map<String, dynamic> _userInput = {
    // 컨셉&스타일 탭
    'subject': '',
    'target_duration': '10',
    'tones': <String>[],
    'tone_custom': '',
    'target_audience': '',

    // 장소&시간 탭
    'location': '',
    'required_locations': <String>[],
    'time_weather': '',

    // 환경&제약 탭
    'equipment': <String>[],
    'equipment_custom': '',
    'crew_count': 1,
    'restrictions': <String>[],
    'restriction_custom': '',
  };

  void _updateUserInput(String key, dynamic value) {
    setState(() {
      _userInput[key] = value;
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFCEDCD3),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            // 상단 바
            _buildTopBar(context, screenWidth),

            // 탭 바
            _buildTabBar(screenWidth, screenHeight),

            // 입력 필드들
            _buildInputFields(screenWidth, screenHeight),

            // 입력 완료 버튼
            _buildCompleteButton(screenWidth, screenHeight),
          ],
        ),
      ),
    );
  }

  // 상단 바
  Widget _buildTopBar(BuildContext context, double screenWidth) {
    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      child: Container(
        width: screenWidth,
        height: 79,
        decoration: const BoxDecoration(
          color: Color(0xFFCEDCD3),
        ),
        child: Stack(
          children: [
            // 왼쪽 뒤로가기 버튼
            Positioned(
              left: 17,
              top: 15,
              child: GestureDetector(
                onTap: () {
                  // 키보드 닫기
                  FocusScope.of(context).unfocus();
                  Navigator.pop(context);
                },
                child: Image.asset(
                  'assets/icons/icon_arrow.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // 중앙 로고와 화면 이름
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 로고 (클릭 시 홈으로 이동)
                  GestureDetector(
                    onTap: () {
                      // 키보드 닫기
                      FocusScope.of(context).unfocus();
                      
                      // 네비게이션 스택을 모두 제거하고 홈으로 이동
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const HomePage()),
                        (route) => false,
                      );
                    },
                    child: Image.asset(
                      'assets/images/logo_text.png',
                      width: screenWidth * 0.25, // 더 작게
                      fit: BoxFit.contain,
                    ),
                  ),
                  // 화면 이름 (작은 글씨)
                  Text(
                    '스토리보드 생성',
                    style: TextStyle(
                      fontFamily: 'Tmoney RoundWind',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF1A1A1A).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // 우측 상단 테스트 실행 버튼
            _buildTestButton(screenWidth),
          ],
        ),
      ),
    );
  }

  // 탭 바 (storyboard와 동일한 스타일)
  Widget _buildTabBar(double screenWidth, double screenHeight) {
    final tabs = const ['컨셉&스타일', '장소&시간', '환경&제약'];
    final isSelected = [
      _selectedTab == 0,
      _selectedTab == 1,
      _selectedTab == 2,
    ];

    return Positioned(
      left: (screenWidth - screenWidth * 0.928) / 2,
      top: 92,
      child: Container(
        width: screenWidth * 0.928, // 373/402
        height: screenHeight * 0.062, // 56/904
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: const Border(
            left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
            bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
            right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
            top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTabItem(tabs[0], 0, isSelected[0]),
            _buildTabItem(tabs[1], 1, isSelected[1]),
            _buildTabItem(tabs[2], 2, isSelected[2]),
          ],
        ),
      ),
    );
  }

  // 탭 아이템
  Widget _buildTabItem(String label, int index, bool isSelected) {
    // 각 탭에 맞는 배경 이미지와 크기 선택
    String backgroundImage;
    double imageWidth;
    double imageHeight = 60;
    
    switch (index) {
      case 0: // 컨셉&스타일
        backgroundImage = 'assets/images/background_cc.png';
        imageWidth = 120; // 컨셉&스타일은 조금 더 넓게
        break;
      case 1: // 장소&시간
        backgroundImage = 'assets/images/background_lt.png';
        imageWidth = 110; // 장소&시간은 중간
        break;
      case 2: // 환경&제약
        backgroundImage = 'assets/images/background_re.png';
        imageWidth = 110; // 환경&제약은 중간
        break;
      default:
        backgroundImage = 'assets/images/tab_selection.png';
        imageWidth = 62;
    }

    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 선택된 탭 배경 이미지
          if (isSelected)
            Image.asset(
              backgroundImage,
              width: imageWidth,
              height: imageHeight,
              fit: BoxFit.contain,
            ),
          // 텍스트
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Tmoney RoundWind',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isSelected ? const Color(0xFFFAFAFA) : const Color(0xFFB2B2B2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 입력 필드들
  Widget _buildInputFields(double screenWidth, double screenHeight) {
    return Positioned(
      left: 0,
      top: 79 + 56 + 10, // 상단 바 + 탭 바 + 간격
      right: 0,
      bottom: 0,
      child: IndexedStack(
        index: _selectedTab,
        children: [
          // 컨셉&스타일 탭
          ConceptStyleTab(
            onSubjectChanged: (value) => _updateUserInput('subject', value),
            onDurationChanged: (value) => _updateUserInput('target_duration', value),
            onTonesChanged: (value) => _updateUserInput('tones', value),
            onToneCustomChanged: (value) => _updateUserInput('tone_custom', value),
            onTargetAudienceChanged: (value) => _updateUserInput('target_audience', value),
            initialValues: _userInput,
          ),
          // 장소&시간 탭
          LocationTimeTab(
            onLocationChanged: (value) => _updateUserInput('location', value),
            onRequiredLocationsChanged: (value) => _updateUserInput('required_locations', value),
            onTimeWeatherChanged: (value) => _updateUserInput('time_weather', value),
            initialValues: _userInput,
          ),
          // 환경&제약 탭
          EnvironmentTab(
            onEquipmentChanged: (value) => _updateUserInput('equipment', value),
            onEquipmentCustomChanged: (value) => _updateUserInput('equipment_custom', value),
            onCrewCountChanged: (value) => _updateUserInput('crew_count', value),
            onRestrictionsChanged: (value) => _updateUserInput('restrictions', value),
            onRestrictionCustomChanged: (value) => _updateUserInput('restriction_custom', value),
            initialValues: _userInput,
          ),
        ],
      ),
    );
  }

  // 입력 완료 버튼 (메인 페이지와 동일)
  Widget _buildCompleteButton(double screenWidth, double screenHeight) {
    final baseWidth = 402.0;
    final baseHeight = 904.0;

    // 버튼 크기: 371px 너비, 84px 높이
    final buttonWidth = 371.0 * (screenWidth / baseWidth);
    final buttonHeight = 84.0 * (screenHeight / baseHeight);

    // 버튼 위치: left: 15px, top: 750px (메인 화면과 동일)
    final buttonLeft = 15.0 * (screenWidth / baseWidth);
    final buttonTop = 750.0 * (screenHeight / baseHeight);

    // 진행 중인지 확인 (ProgressNotificationService 사용)
    final isProgressing = ProgressNotificationService().isShowing;
    final isDisabled = _isLoading || isProgressing;

    return Positioned(
      left: buttonLeft,
      top: buttonTop,
      child: GestureDetector(
        onTap: isDisabled ? null : _generateVlogPlan,
        child: Container(
          width: buttonWidth,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: isDisabled ? const Color(0xFFB2B2B2) : const Color(0xFF455D75),
            borderRadius: BorderRadius.circular(10),
            border: const Border(
              left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
              top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
              right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
              bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
            ),
          ),
          child: Center(
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFAFAFA)),
                    ),
                  )
                : Text(
                    '입력 완료',
                    style: TextStyle(
                      fontFamily: 'Tmoney RoundWind',
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      height: 36 / 28,
                      color: isDisabled ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // 테스트용 Mock Data 버튼 (우측 상단)
  Widget _buildTestButton(double screenWidth) {
    // 진행 중인지 확인 (ProgressNotificationService 사용)
    final isProgressing = ProgressNotificationService().isShowing;
    final isDisabled = _isLoading || isProgressing;

    return Positioned(
      right: 17,
      top: 15,
      child: GestureDetector(
        onTap: isDisabled ? null : _testWithMockData,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDisabled ? const Color(0xFFB2B2B2) : const Color(0xFFFF6B6B), // 빨간색으로 테스트 버튼임을 표시
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: Color(0xFF1A1A1A), width: 2),
              top: BorderSide(color: Color(0xFF1A1A1A), width: 2),
              right: BorderSide(color: Color(0xFF1A1A1A), width: 4),
              bottom: BorderSide(color: Color(0xFF1A1A1A), width: 4),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFAFAFA)),
                  ),
                )
              : Text(
                  '🧪 테스트',
                  style: TextStyle(
                    fontFamily: 'Tmoney RoundWind',
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: isDisabled ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
                  ),
                ),
        ),
      ),
    );
  }

  // 브이로그 계획 생성
  Future<void> _generateVlogPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 프롬프트에 전달할 데이터 준비
      final Map<String, String> promptData = _preparePromptData();

      final dataService = VlogDataService();
      dataService.setUserInput(promptData);

      // StoryboardGenerationService를 사용하여 스토리보드 생성
      final result = await StoryboardGenerationService.generateStoryboard(
        userInput: promptData,
        dataService: dataService,
      );

      if (result == null) {
        _showErrorDialog('스토리보드 생성에 실패했습니다.\nAPI 키를 확인하거나 네트워크 연결을 확인해주세요.');
        return;
      }

      if (mounted) {
        // 키보드 닫기
        FocusScope.of(context).unfocus();
        
        // 완료 알림 표시 (다이얼로그 대신 AppNotification 사용)
        AppNotification.show(
          context,
          '완료되었습니다! 스토리보드를 확인하러 가시겠습니까?',
          type: NotificationType.success,
          onTap: () {
            // 스토리보드 화면으로 이동
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const StoryboardPage(),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('오류가 발생했습니다:\n$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  // Mock Data로 user_input 채우기 (테스트용)
  void _fillMockData() {
    setState(() {
      // 컨셉&스타일 탭
      _userInput['subject'] = '친구들과 제주도 여행';
      _userInput['target_duration'] = '10';
      _userInput['tones'] = ['밝고 경쾌한', '자연스러운'];
      _userInput['tone_custom'] = '';
      _userInput['target_audience'] = '20대 여행 좋아하는 사람들';

      // 장소&시간 탭
      _userInput['location'] = '제주도';
      _userInput['required_locations'] = ['성산일출봉', '섭지코지', '월정리 해변'];
      _userInput['time_weather'] = '낮, 맑음';

      // 환경&제약 탭
      _userInput['equipment'] = ['smartphone'];
      _userInput['equipment_custom'] = '';
      _userInput['crew_count'] = 3;
      _userInput['restrictions'] = [];
      _userInput['restriction_custom'] = '';
    });
  }

  // Mock Data로 채우고 바로 API 요청 보내기 (테스트용)
  Future<void> _testWithMockData() async {
    // Mock Data로 채우기
    _fillMockData();
    
    // 약간의 딜레이 후 API 요청 (UI 업데이트를 위해)
    await Future.delayed(const Duration(milliseconds: 300));
    
    // API 요청 보내기
    await _generateVlogPlan();
  }

  // 프롬프트에 전달할 데이터 준비
  Map<String, String> _preparePromptData() {
    final Map<String, String> promptData = {};

    // 촬영 주제
    if (_userInput['subject']?.toString().isNotEmpty ?? false) {
      promptData['subject'] = _userInput['subject'].toString();
    }

    // 목표 영상 길이
    promptData['target_duration'] = _userInput['target_duration'].toString();

    // 영상 톤 (멀티 선택 + 기타)
    final tonesRaw = _userInput['tones'];
    final tones = tonesRaw != null
        ? (tonesRaw is List<String>
            ? tonesRaw
            : List<String>.from((tonesRaw as List<dynamic>).map((e) => e.toString())))
        : <String>[];
    final toneCustom = _userInput['tone_custom']?.toString() ?? '';
    if (tones.isNotEmpty || toneCustom.isNotEmpty) {
      final toneLabels = tones.map((value) {
        switch (value) {
          case 'bright': return '밝고 활기찬';
          case 'healing': return '힐링/여유로운';
          case 'hip': return '힙한/트렌디한';
          case 'funny': return '재미있는/유머';
          case 'informative': return '정보전달/깔끔한';
          case 'vintage': return '빈티지/레트로';
          default: return value;
        }
      }).toList();

      if (toneCustom.isNotEmpty) {
        toneLabels.add(toneCustom);
      }

      promptData['tone_manners'] = toneLabels.join(', ');
    }

    // 대상 시청자
    if (_userInput['target_audience']?.toString().isNotEmpty ?? false) {
      promptData['target_audience'] = _userInput['target_audience'].toString();
    }

    // 촬영 장소
    if (_userInput['location']?.toString().isNotEmpty ?? false) {
      promptData['location'] = _userInput['location'].toString();
    }

    // 필수 촬영 장소
    final requiredLocationsRaw = _userInput['required_locations'];
    final requiredLocations = requiredLocationsRaw != null
        ? (requiredLocationsRaw is List<String>
            ? requiredLocationsRaw
            : List<String>.from((requiredLocationsRaw as List<dynamic>).map((e) => e.toString())))
        : <String>[];
    if (requiredLocations.isNotEmpty) {
      promptData['required_location'] = requiredLocations.join(', ');
    }

    // 시간/날씨
    if (_userInput['time_weather']?.toString().isNotEmpty ?? false) {
      promptData['time_weather'] = _userInput['time_weather'].toString();
    }

    // 사용 장비 (멀티 선택 + 기타)
    final equipmentRaw = _userInput['equipment'];
    final equipment = equipmentRaw != null
        ? (equipmentRaw is List<String>
            ? equipmentRaw
            : List<String>.from((equipmentRaw as List<dynamic>).map((e) => e.toString())))
        : <String>[];
    final equipmentCustom = _userInput['equipment_custom']?.toString() ?? '';
    if (equipment.isNotEmpty || equipmentCustom.isNotEmpty) {
      final equipmentLabels = equipment.map((value) {
        switch (value) {
          case 'smartphone': return '스마트폰';
          case 'dslr': return 'DSLR';
          case 'action_cam': return '액션캠';
          case 'tripod': return '삼각대';
          case 'gimbal': return '짐벌';
          case 'microphone': return '마이크';
          default: return value;
        }
      }).toList();

      if (equipmentCustom.isNotEmpty) {
        equipmentLabels.add(equipmentCustom);
      }

      promptData['equipment'] = equipmentLabels.join(', ');
    }

    // 촬영 인원
    promptData['crew_count'] = _userInput['crew_count'].toString();

    // 촬영 제약 (멀티 선택 + 기타)
    final restrictionsRaw = _userInput['restrictions'];
    final restrictions = restrictionsRaw != null
        ? (restrictionsRaw is List<String>
            ? restrictionsRaw
            : List<String>.from((restrictionsRaw as List<dynamic>).map((e) => e.toString())))
        : <String>[];
    final restrictionCustom = _userInput['restriction_custom']?.toString() ?? '';
    if (restrictions.isNotEmpty || restrictionCustom.isNotEmpty) {
      final restrictionLabels = restrictions.map((value) {
        switch (value) {
          case 'time_limit': return '시간 부족';
          case 'budget_limit': return '예산 부족';
          case 'solo_shooting': return '혼자 촬영';
          case 'camera_shy': return '낯가림/출연 부담';
          default: return value;
        }
      }).toList();

      if (restrictionCustom.isNotEmpty) {
        restrictionLabels.add(restrictionCustom);
      }

      promptData['restrictions'] = restrictionLabels.join(', ');
    }

    return promptData;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAFAFA),
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
