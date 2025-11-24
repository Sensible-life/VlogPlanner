import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/styles.dart';
import '../../services/vlog_data_service.dart';
import '../../models/cue_card.dart';
import '../../models/plan.dart';
import '../camera/camera_mode_page.dart';
import '../home_page.dart';
import '../../widgets/app_notification.dart';
import '../../widgets/loading_dialog.dart';
import '../../services/openai_service.dart';

class SceneListPage extends StatefulWidget {
  final int? initialExpandedIndex;
  
  const SceneListPage({super.key, this.initialExpandedIndex});

  // 커스텀 페이지 전환 애니메이션 (오른쪽에서 슬라이드)
  static Route<void> route({int? initialExpandedIndex}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return SceneListPage(initialExpandedIndex: initialExpandedIndex);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // 나올 때: 오른쪽(1.0)에서 왼쪽(0.0)으로
        // 들어갈 때: 왼쪽(0.0)에서 오른쪽(1.0)으로
        const begin = Offset(1.0, 0.0); // 오른쪽에서 시작
        const end = Offset.zero; // 원래 위치
        const curve = Curves.easeInOut;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      fullscreenDialog: true,
    );
  }

  @override
  State<SceneListPage> createState() => _SceneListPageState();
}

class _SceneListPageState extends State<SceneListPage> with TickerProviderStateMixin {
  final VlogDataService _dataService = VlogDataService();
  List<CueCard> _scenes = [];
  int? _expandedSceneIndex;
  bool _isEditMode = false; // 편집 모드 상태
  int? _longPressedIndex; // 길게 누른 카드 인덱스
  int? _draggingIndex; // 드래그 중인 카드 인덱스
  Map<int, AnimationController> _rotationControllers = {}; // 각 카드의 회전 애니메이션
  
  // 입력창 관련
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isInputExpanded = false;
  double _previousKeyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    _loadScenes();
    _inputFocusNode.addListener(_onFocusChanged);
    _inputController.addListener(_onInputChanged);
    // initialExpandedIndex가 있으면 해당 씬을 확장된 상태로 설정
    if (widget.initialExpandedIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _expandedSceneIndex = widget.initialExpandedIndex;
          });
          // 해당 씬으로 스크롤
          _scrollToScene(widget.initialExpandedIndex!);
        }
      });
    }
  }
  
  // 포커스 변경 감지
  void _onFocusChanged() {
    setState(() {
      // 포커스가 있으면 확장, 없으면 한 줄로 축소
      _isInputExpanded = _inputFocusNode.hasFocus;
    });
  }
  
  // 입력 변경 감지 (X 버튼 상태 업데이트용)
  void _onInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  
  // 특정 씬으로 스크롤
  void _scrollToScene(int index) {
    // ScrollController가 있다면 사용, 없으면 GlobalKey로 찾기
    // 일단 간단하게 Future.delayed로 처리
    Future.delayed(const Duration(milliseconds: 100), () {
      // 스크롤 로직은 나중에 추가 가능
    });
  }

  @override
  void dispose() {
    // 모든 애니메이션 컨트롤러 해제
    for (var controller in _rotationControllers.values) {
      controller.dispose();
    }
    _rotationControllers.clear();
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    _inputFocusNode.removeListener(_onFocusChanged);
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _loadScenes() {
    if (_dataService.cueCards != null) {
      setState(() {
        _scenes = List.from(_dataService.cueCards!);
      });
    }
  }

  // 편집 모드 토글
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      _expandedSceneIndex = null; // 편집 모드 진입 시 확장된 카드 닫기
      _longPressedIndex = null; // 편집 모드 종료 시 길게 누른 인덱스 초기화
      _draggingIndex = null; // 드래그 인덱스 초기화
      
      if (_isEditMode) {
        // 편집 모드 진입: 모든 카드에 회전 애니메이션 시작
        for (int i = 0; i < _scenes.length; i++) {
          _startRotationAnimation(i);
        }
      } else {
        // 편집 모드 종료: 모든 애니메이션 정지
        for (var controller in _rotationControllers.values) {
          controller.stop();
        }
      }
    });
  }

  // 회전 애니메이션 시작
  void _startRotationAnimation(int index) {
    if (_rotationControllers.containsKey(index)) {
      _rotationControllers[index]!.repeat(reverse: true);
    } else {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 100), // iPhone 앱처럼 매우 빠른 속도
        vsync: this,
      );
      _rotationControllers[index] = controller;
      controller.repeat(reverse: true);
    }
  }

  // 씬 삭제
  void _deleteScene(int index) {
    if (index < 0 || index >= _scenes.length) return;
    
    // 삭제 확인 다이얼로그
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAFAFA),
        title: Text(
          '씬 삭제',
          style: TextStyle(
            fontFamily: 'Tmoney RoundWind',
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        content: Text(
          '이 씬을 삭제하시겠습니까?',
          style: TextStyle(
            fontFamily: 'Tmoney RoundWind',
            color: const Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: TextStyle(
                fontFamily: 'Tmoney RoundWind',
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _scenes.removeAt(index);
                // 데이터 서비스 업데이트
                _dataService.cueCards = List.from(_scenes);
                _longPressedIndex = null;
                
                // 애니메이션 컨트롤러 정리
                if (_rotationControllers.containsKey(index)) {
                  _rotationControllers[index]!.dispose();
                  _rotationControllers.remove(index);
                }
                // 인덱스 재조정
                final newControllers = <int, AnimationController>{};
                _rotationControllers.forEach((key, value) {
                  if (key > index) {
                    newControllers[key - 1] = value;
                  } else if (key < index) {
                    newControllers[key] = value;
                  }
                });
                _rotationControllers = newControllers;
                
                // 씬이 없으면 편집 모드 종료
                if (_scenes.isEmpty) {
                  _isEditMode = false;
                }
              });
              
              // Firebase에 실시간 반영
              _dataService.updateCurrentStoryboard().catchError((error) {
                print('Firebase 업데이트 실패: $error');
              });
            },
            child: Text(
              '삭제',
              style: TextStyle(
                fontFamily: 'Tmoney RoundWind',
                color: Colors.red,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 씬 대체 (새 씬으로 교체)
  void _replaceScene(int index) {
    if (index < 0 || index >= _scenes.length) return;

    final scene = _scenes[index];
    final plan = _dataService.plan;
    
    // 디버깅 로그
    print('[SCENE_LIST] 대체 버튼 클릭 - 씬 #${index + 1}: ${scene.title}');
    print('[SCENE_LIST] Plan 상태: ${plan != null ? "존재" : "null"}');
    if (plan != null) {
      print('[SCENE_LIST] Plan.alternativeScenes 개수: ${plan.alternativeScenes.length}');
      if (plan.alternativeScenes.isNotEmpty) {
        for (var i = 0; i < plan.alternativeScenes.length; i++) {
          final altScene = plan.alternativeScenes[i];
          print('[SCENE_LIST]   - 대체 씬 #${i + 1}: ${altScene.title} (id: ${altScene.alternativeSceneId ?? "없음"})');
        }
      }
    }
    
    // Plan의 alternativeScenes 확인
    if (plan == null) {
      print('[SCENE_LIST] ⚠️ Plan이 null입니다');
      AppNotification.show(
        context,
        '대체 씬이 없습니다. (Plan이 null)',
        type: NotificationType.warning,
      );
      setState(() {
        _longPressedIndex = null;
      });
      return;
    }
    
    if (plan.alternativeScenes.isEmpty) {
      print('[SCENE_LIST] ⚠️ Plan.alternativeScenes가 비어있습니다');
      AppNotification.show(
        context,
        '대체 씬이 없습니다. (alternativeScenes가 비어있음)',
        type: NotificationType.warning,
      );
      setState(() {
        _longPressedIndex = null;
      });
      return;
    }

    print('[SCENE_LIST] ✅ 대체 씬 모달 표시: ${plan.alternativeScenes.length}개');
    // 대체 씬 선택 모달 표시
    _showAlternativeSceneModal(index, plan.alternativeScenes);

    setState(() {
      _longPressedIndex = null;
    });
  }

  // 대체 씬 교체 확인 다이얼로그
  void _showReplaceConfirmationDialog({
    required int sceneIndex,
    required int altIndex,
    required String altSceneTitle,
    required double screenWidth,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAFAFA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF1A1A1A), width: 3),
        ),
        title: Text(
          '대체 씬 교체',
          style: TextStyle(
            fontFamily: 'Tmoney RoundWind',
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        content: Text(
          '이 씬을 다음 씬으로 대체하시겠습니까?\n\n"$altSceneTitle"',
          style: TextStyle(
            fontFamily: 'Tmoney RoundWind',
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '취소',
              style: TextStyle(
                fontFamily: 'Tmoney RoundWind',
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 확인 다이얼로그 닫기
              Navigator.of(context).pop(); // 대체 씬 모달 닫기
              _replaceWithAlternativeScene(sceneIndex, altIndex);
            },
            child: Text(
              '확인',
              style: TextStyle(
                fontFamily: 'Tmoney RoundWind',
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 대체 씬으로 교체
  void _replaceWithAlternativeScene(int sceneIndex, int altIndex) async {
    if (sceneIndex < 0 || sceneIndex >= _scenes.length) return;

    final plan = _dataService.plan;
    if (plan == null || plan.alternativeScenes.isEmpty) {
      AppNotification.show(
        context,
        '대체 씬을 찾을 수 없습니다.',
        type: NotificationType.error,
      );
      return;
    }

    if (altIndex < 0 || altIndex >= plan.alternativeScenes.length) {
      AppNotification.show(
        context,
        '대체 씬을 찾을 수 없습니다.',
        type: NotificationType.error,
      );
      return;
    }

    final originalScene = _scenes[sceneIndex];
    final selectedAltScene = plan.alternativeScenes[altIndex];

    // 대체 씬으로 교체 (원본 씬의 alternativeSceneId는 유지)
    final newScene = selectedAltScene.copyWith(
      // 원본 씬의 alternativeSceneId를 유지
      alternativeSceneId: originalScene.alternativeSceneId,
      // 체크 상태도 초기화
      checkedChecklistIndices: null,
    );

    setState(() {
      _scenes[sceneIndex] = newScene;
      _dataService.cueCards = List.from(_scenes);
    });

    // Firebase에 실시간 반영
    await _dataService.updateCurrentStoryboard().catchError((error) {
      print('Firebase 업데이트 실패: $error');
    });

    // 스토리보드 페이지가 열려있다면 업데이트 (Navigator를 통해 알림)
    // 실제로는 VlogDataService가 변경되었으므로 storyboard_page가 다시 빌드될 때 자동으로 반영됨

    // 성공 알림
    if (mounted) {
      AppNotification.show(
        context,
        '씬이 대체되었습니다!',
        type: NotificationType.success,
      );
    }
  }

  // 원화 포맷 변환
  String _formatCurrency(int amount) {
    if (amount == 0) return '0원';
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatted원';
  }

  // 씬 순서 변경
  void _reorderScenes(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    setState(() {
      final item = _scenes.removeAt(oldIndex);
      _scenes.insert(newIndex, item);
      // 데이터 서비스 업데이트
      _dataService.cueCards = List.from(_scenes);
      _draggingIndex = null; // 드래그 종료
    });
    
    // Firebase에 실시간 반영
    _dataService.updateCurrentStoryboard().catchError((error) {
      print('Firebase 업데이트 실패: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 키보드 높이 변화 감지를 별도로 처리하여 리빌드 최소화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      // 키보드가 내려갔을 때 포커스 해제
      if (_previousKeyboardHeight > 0 && keyboardHeight == 0) {
        if (mounted && _inputFocusNode.hasFocus) {
          _inputFocusNode.unfocus();
        }
      }
      if (mounted) {
        _previousKeyboardHeight = keyboardHeight;
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFCEDCD3),
      resizeToAvoidBottomInset: true, // 키보드 나타날 때 레이아웃 리사이즈 허용
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, screenWidth, screenHeight),
            Expanded(
              child: _buildSceneList(screenWidth, screenHeight),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomInputBar(screenWidth, screenHeight),
    );
  }

  // 상단 헤더
  Widget _buildHeader(BuildContext context, double screenWidth, double screenHeight) {
    final buttonSize = screenWidth * 0.117;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.042,
        vertical: screenHeight * 0.023,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 뒤로가기 버튼
          GestureDetector(
            onTap: () {
              // 키보드 닫기
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
            child: Container(
              width: buttonSize,
              height: buttonSize,
              child: Center(
                child: Image.asset(
                  'assets/icons/icon_arrow.png',
                  width: buttonSize,
                  height: buttonSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // 로고와 화면 이름
          Column(
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
                '씬 리스트',
                style: TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xFF1A1A1A).withOpacity(0.7),
                ),
              ),
            ],
          ),

          // 오른쪽 버튼 (편집 모드일 때는 완료 버튼, 아니면 촬영 버튼)
          _isEditMode
              ? GestureDetector(
                  onTap: _toggleEditMode,
                  child: Image.asset(
                    'assets/images/button_check.png',
                    width: buttonSize,
                    height: buttonSize,
                    fit: BoxFit.contain,
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    // 씬이 선택되지 않았으면 알림 표시
                    if (_expandedSceneIndex == null) {
                      AppNotification.show(
                        context,
                        '촬영할 씬을 선택하세요!',
                        type: NotificationType.warning,
                      );
                      return;
                    }

                    // 키보드 닫기
                    FocusScope.of(context).unfocus();

                    // 선택된 씬 정보 가져오기
                    final selectedScene = _scenes[_expandedSceneIndex!];

                    // 씬 정보와 함께 CameraModePage로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraModePage(
                          sceneNumber: _expandedSceneIndex! + 1,
                          shootingGuides: selectedScene.checklist,
                          sceneInfo: {
                            'sceneIndex': _expandedSceneIndex! + 1,
                            'totalScenes': _scenes.length,
                            'title': selectedScene.title,
                            'checklist': selectedScene.checklist,
                            'referenceVideoUrl': selectedScene.referenceVideoUrl ?? '',
                            'referenceVideoTimestamp': selectedScene.referenceVideoTimestamp ?? 0,
                          },
                        ),
                      ),
                    ).then((_) {
                      // 카메라 페이지에서 돌아왔을 때 체크 상태 동기화
                      _loadScenes();
                      setState(() {});
                    });
                  },
                  child: Image.asset(
                    'assets/images/button_camera.png',
                    width: buttonSize,
                    height: buttonSize,
                    fit: BoxFit.contain,
                  ),
                ),
        ],
      ),
    );
  }

  // 씬 리스트
  Widget _buildSceneList(double screenWidth, double screenHeight) {
    if (_scenes.isEmpty) {
      return Center(
        child: Text(
          '씬 데이터가 없습니다',
          style: TextStyle(
            fontFamily: 'Tmoney RoundWind',
            fontSize: screenWidth * 0.035,
            color: const Color(0xFFB2B2B2),
          ),
        ),
      );
    }

    // 펀치 구멍 및 연결선 크기
    final holeDiameter = screenWidth * 0.03;
    final holeRadius = holeDiameter / 2;
    final connectorWidth = screenWidth * 0.015;
    final cardSpacing = screenHeight * 0.03;

    if (_isEditMode) {
      // 편집 모드: ReorderableListView 사용
      return ReorderableListView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.032,
          vertical: screenHeight * 0.009,
        ),
        onReorder: _reorderScenes,
        onReorderStart: (index) {
          setState(() {
            _draggingIndex = index;
          });
        },
        onReorderEnd: (index) {
          setState(() {
            _draggingIndex = null;
          });
        },
        proxyDecorator: (child, index, animation) {
          // 드래그 중 배경 사각형 제거
          return Material(
            color: Colors.transparent,
            elevation: 0,
            child: child,
          );
        },
        children: List.generate(_scenes.length, (index) {
          final scene = _scenes[index];
          final isFirst = index == 0;
          final isLast = index == _scenes.length - 1;
          final isExpanded = _expandedSceneIndex == index;

          return RepaintBoundary(
            key: ValueKey('scene_$index'),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // 씬 카드 (편집 모드)
                    _buildSceneCard(
                      scene: scene,
                      index: index,
                      isExpanded: isExpanded,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      isEditMode: true,
                    ),

                    // 상단 펀치 구멍 (첫 번째 카드 제외)
                    if (!isFirst)
                      Positioned(
                        top: holeRadius,
                        child: Container(
                          width: holeDiameter,
                          height: holeDiameter,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                    // 하단 펀치 구멍 (마지막 카드 제외)
                    if (!isLast)
                      Positioned(
                        bottom: holeRadius * 2,
                        child: Container(
                          width: holeDiameter,
                          height: holeDiameter,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                    // 이전 카드에서 오는 연결선 (첫 번째 카드 제외, 드래그 중인 카드의 위쪽 연결선은 숨김)
                    if (!isFirst && _draggingIndex != index)
                      Positioned(
                        top: -(cardSpacing + holeRadius * 3),
                        child: Container(
                          width: connectorWidth,
                          height: cardSpacing + holeRadius * 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB2B2B2),
                            borderRadius: BorderRadius.circular(connectorWidth / 2),
                          ),
                        ),
                      ),
                  ],
                ),

                // 간격 유지
                if (!isLast)
                  SizedBox(height: cardSpacing)
                else
                  // 마지막 씬의 경우 하단 바 위에 표시되도록 여유 공간 추가
                  SizedBox(height: screenHeight * 0.1),
              ],
            ),
          );
        }),
      );
    } else {
      // 일반 모드: ListView.builder 사용
      return ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.032,
          vertical: screenHeight * 0.009,
        ),
        itemCount: _scenes.length,
        itemBuilder: (context, index) {
          final scene = _scenes[index];
          final isFirst = index == 0;
          final isLast = index == _scenes.length - 1;
          final isExpanded = _expandedSceneIndex == index;

          return RepaintBoundary(
            key: ValueKey('scene_$index'),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // 씬 카드
                    _buildSceneCard(
                      scene: scene,
                      index: index,
                      isExpanded: isExpanded,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      isEditMode: false,
                    ),

                    // 상단 펀치 구멍 (첫 번째 카드 제외)
                    if (!isFirst)
                      Positioned(
                        top: holeRadius,
                        child: Container(
                          width: holeDiameter,
                          height: holeDiameter,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                    // 하단 펀치 구멍 (마지막 카드 제외)
                    if (!isLast)
                      Positioned(
                        bottom: holeRadius * 2,
                        child: Container(
                          width: holeDiameter,
                          height: holeDiameter,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                    // 이전 카드에서 오는 연결선 (첫 번째 카드 제외)
                    if (!isFirst)
                      Positioned(
                        top: -(cardSpacing + holeRadius * 3),
                        child: Container(
                          width: connectorWidth,
                          height: cardSpacing + holeRadius * 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB2B2B2),
                            borderRadius: BorderRadius.circular(connectorWidth / 2),
                          ),
                        ),
                      ),
                  ],
                ),

                // 간격 유지
                if (!isLast)
                  SizedBox(height: cardSpacing)
                else
                  // 마지막 씬의 경우 하단 바 위에 표시되도록 여유 공간 추가
                  SizedBox(height: screenHeight * 0.1),
              ],
            ),
          );
        },
      );
    }
  }

  // 씬 카드
  Widget _buildSceneCard({
    required CueCard scene,
    required int index,
    required bool isExpanded,
    required double screenWidth,
    required double screenHeight,
    required bool isEditMode,
  }) {
    // 카드 크기 (기본 / 확장)
    final cardWidth = screenWidth * 0.928;
    final cardHeightCollapsed = screenHeight * 0.18; // 세로 사이즈 줄임 (0.238 -> 0.18)

    // 흔들거림 애니메이션
    Widget cardContent = Container(
      width: cardWidth,
      constraints: BoxConstraints(
        minHeight: cardHeightCollapsed,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.0075),
          top: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.0075),
          right: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.015),
          bottom: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.015),
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 기본 정보 (항상 표시)
              _buildBasicInfo(scene, index, screenWidth, screenHeight, isEditMode, isExpanded),

              // 확장 정보 (확장 시에만 표시)
              if (isExpanded)
                _buildExpandedInfo(scene, screenWidth, screenHeight),
            ],
          ),
          // 삭제 및 대체 버튼 (편집 모드일 때 모든 카드에 표시) - 우측 하단
          if (_isEditMode)
            Positioned(
              bottom: screenWidth * 0.05,
              right: screenWidth * 0.03,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 대체 버튼 (삭제 버튼 왼쪽)
                  GestureDetector(
                    onTap: () => _replaceScene(index),
                    child: Container(
                      width: screenWidth * 0.08,
                      height: screenWidth * 0.08,
                      margin: EdgeInsets.only(right: screenWidth * 0.015),
                      child: Image.asset(
                        'assets/images/button_replace.png',
                        width: screenWidth * 0.08,
                        height: screenWidth * 0.08,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // 삭제 버튼 (더 오른쪽)
                  GestureDetector(
                    onTap: () => _deleteScene(index),
                    child: Container(
                      width: screenWidth * 0.08,
                      height: screenWidth * 0.08,
                      child: Image.asset(
                        'assets/images/button_delete.png',
                        width: screenWidth * 0.08,
                        height: screenWidth * 0.08,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    // 편집 모드일 때는 GestureDetector를 제거하여 ReorderableListView의 드래그가 작동하도록 함
    if (isEditMode) {
      // 편집 모드에서는 드래그만 가능 (버튼은 항상 표시)
      // 회전 애니메이션 적용
      if (_rotationControllers.containsKey(index)) {
        return AnimatedBuilder(
          animation: _rotationControllers[index]!,
          builder: (context, child) {
            // 회전 각도: -1.5도 ~ +1.5도 (더 작은 각도)
            final rotationAngle = (_rotationControllers[index]!.value * 2 - 1) * 0.026; // 약 1.5도 (0.026 라디안)
            return Transform.rotate(
              angle: rotationAngle,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: cardContent,
              ),
            );
          },
        );
      }
      return AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: cardContent,
      );
    }
    
    // 일반 모드일 때만 길게 누르기와 탭 처리
    // 체크박스 영역은 별도로 처리하기 위해 child에 직접 GestureDetector 적용하지 않고
    // 전체를 감싸되, 체크박스 영역에서 이벤트가 전파되지 않도록 함
    return GestureDetector(
      onLongPress: () {
        // 길게 누르면 진동 피드백과 함께 편집 모드 활성화
        HapticFeedback.mediumImpact();
        setState(() {
          _isEditMode = true;
          _longPressedIndex = index;
          _expandedSceneIndex = null; // 확장된 카드 닫기
          // 모든 카드에 회전 애니메이션 시작
          for (int i = 0; i < _scenes.length; i++) {
            _startRotationAnimation(i);
          }
        });
      },
      onTap: () {
        // 편집 모드가 아닐 때만 확장/축소 가능
        if (!_isEditMode) {
          setState(() {
            _expandedSceneIndex = isExpanded ? null : index;
          });
        }
      },
      behavior: HitTestBehavior.translucent, // 자식 위젯이 터치를 가로챌 수 있도록
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: cardContent,
      ),
    );
  }

  // 기본 정보 (항상 표시)
  Widget _buildBasicInfo(CueCard scene, int index, double screenWidth, double screenHeight, bool isEditMode, bool isExpanded) {
    final thumbnailWidth = screenWidth * 0.4;
    final thumbnailHeight = screenHeight * 0.122;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.032,
        screenWidth * 0.05, // 상단 패딩 줄임
        screenWidth * 0.032,
        screenWidth * 0.005, // 하단 패딩 더 축소
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 썸네일과 제목/세부 내용을 가로로 배치
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 썸네일
              GestureDetector(
                onTap: scene.storyboardImageUrl != null
                    ? () => _showImageModal(context, scene.storyboardImageUrl!, screenWidth, screenHeight)
                    : null,
                child: Container(
                  width: thumbnailWidth,
                  height: thumbnailHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(15),
                    border: Border(
                      left: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.005),
                      top: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.005),
                      right: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.0087),
                      bottom: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.0087),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: scene.storyboardImageUrl != null
                        ? Image.network(
                            scene.storyboardImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // 403 에러는 이미지 URL 만료를 의미
                              print('[SCENE_LIST] 씬 이미지 로드 실패 (만료되었을 수 있음): $error');
                              return Container(
                                color: const Color(0xFFB2B2B2),
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: const Color(0xFF1A1A1A).withOpacity(0.3),
                                  size: 24,
                                ),
                              );
                            },
                          )
                        : Container(color: const Color(0xFFB2B2B2)),
                  ),
                ),
              ),

              SizedBox(width: screenWidth * 0.048),

              // 제목과 세부 내용
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 제목 (줄바꿈 허용) - 드롭다운 하지 않았을 때는 제목만 표시
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      '${index + 1}. ${scene.title}',
                      style: TextStyle(
                        fontFamily: 'Tmoney RoundWind',
                        fontSize: screenWidth * 0.045, // 제목 크기 늘림 (0.035 -> 0.042)
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                      softWrap: true,
                    ),
                    // 시간 표시 (아래쪽에)
                    if (!isExpanded)
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.015),
                        child: Text(
                          '${scene.allocatedSec ~/ 60}분',
                          style: TextStyle(
                            fontFamily: 'Tmoney RoundWind',
                            fontSize: screenWidth * 0.038, // 크기 증가 (0.032 -> 0.038)
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFB2B2B2),
                            height: 1.29,
                          ),
                        ),
                      ),
                    // 드롭다운 하지 않았을 때는 세부 내용 표시하지 않음
                    // 시간은 드롭다운이 열리지 않았을 때 표시하지 않음
                  ],
                ),
              ),
            ],
          ),
          
          // 드롭다운 시 세부 내용의 나머지 부분이 썸네일 밑으로 내려가는 부분 (전체 너비)
          if (isExpanded && scene.summary.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.02),
              child: Text(
                scene.summary.join(' '), // 줄바꿈 제거, 공백으로 연결
                style: TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1A1A1A),
                  height: 1.31,
                ),
                softWrap: true, // 너비 넘어갈 때만 줄바꿈
              ),
            ),
        ],
      ),
    );
  }

  // 확장 정보
  Widget _buildExpandedInfo(CueCard scene, double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.032, // left
        screenWidth * 0.045, // top - 세부 내용과 아이콘 사이 간격 살짝 증가 (0.032 -> 0.045)
        screenWidth * 0.032, // right
        screenWidth * 0.055, // bottom - 체크리스트 사각형과 카드 아래 경계(펀치구멍) 사이 간격
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
              // 아이콘 정보 - 아이콘 기준 정렬
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoIcon(
                    '${scene.allocatedSec ~/ 60}분',
                    'dropdown_time.png',
                    screenWidth,
                  ),
                  _buildInfoIcon(
                    scene.cost > 0 ? '${_formatCurrency(scene.cost)}' : '무료',
                    'dropdown_budget.png',
                    screenWidth,
                    subtitle: scene.cost > 0 ? '예산' : null,
                  ),
                  _buildInfoIcon(
                    scene.location.isNotEmpty ? scene.location : '장소',
                    'dropdown_location.png',
                    screenWidth,
                  ),
                  _buildInfoIcon(
                    '${scene.peopleCount}명',
                    'dropdown_people.png',
                    screenWidth,
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.025),

              // 체크리스트 (사각형으로 감싸기) - 개수에 따라 동적 높이
              if (scene.checklist.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.032),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.0075),
                      top: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.0075),
                      right: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.015),
                      bottom: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.015),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: scene.checklist.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isLast = index == scene.checklist.length - 1;
                      final isChecked = scene.checkedChecklistIndices?.contains(index) ?? false;

                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : screenHeight * 0.01),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 체크박스 터치 영역 확대
                            GestureDetector(
                              behavior: HitTestBehavior.opaque, // 터치 이벤트가 부모로 전파되지 않도록
                              onTap: () {
                                setState(() {
                                  // CueCard 업데이트
                                  final sceneIndex = _scenes.indexOf(scene);
                                  if (sceneIndex >= 0) {
                                    final currentCheckedIndices = Set<int>.from(scene.checkedChecklistIndices ?? {});
                                    if (isChecked) {
                                      currentCheckedIndices.remove(index);
                                    } else {
                                      currentCheckedIndices.add(index);
                                    }
                                    _scenes[sceneIndex] = scene.copyWith(
                                      checkedChecklistIndices: currentCheckedIndices.isEmpty ? null : currentCheckedIndices,
                                    );
                                    // 데이터 서비스 업데이트
                                    _dataService.cueCards = List.from(_scenes);
                                    // Firebase에 실시간 반영
                                    _dataService.updateCurrentStoryboard().catchError((error) {
                                      print('Firebase 업데이트 실패: $error');
                                    });
                                  }
                                });
                              },
                              child: Container(
                                width: screenWidth * 0.08,
                                height: screenWidth * 0.08,
                                alignment: Alignment.center,
                                child: Container(
                                  width: screenWidth * 0.047,
                                  height: screenWidth * 0.047,
                                  decoration: BoxDecoration(
                                    color: isChecked ? const Color(0xFFCEDCD3) : const Color(0xFFFAFAFA),
                                    border: Border.all(
                                      color: const Color(0xFF1A1A1A),
                                      width: screenWidth * 0.005,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: isChecked
                                      ? CustomPaint(
                                          painter: _CheckMarkPainter(),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.025),
                            // 텍스트 영역 - 체크 상태에 따라 색상 변경 (살짝 아래로)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: screenWidth * 0.012),
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontFamily: 'Tmoney RoundWind',
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w800,
                                    color: isChecked
                                        ? const Color(0xFFB2B2B2)
                                        : const Color(0xFF1A1A1A),
                                    height: 1.31,
                                    decoration: isChecked ? TextDecoration.lineThrough : null,
                                  ),
                                  softWrap: true, // 단어 단위 줄바꿈
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }

  // 정보 아이콘
  Widget _buildInfoIcon(String label, String assetPath, double screenWidth, {String? subtitle}) {
    return SizedBox(
      width: screenWidth * 0.2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 아이콘
          Image.asset(
            'assets/icons/$assetPath',
            width: screenWidth * 0.082,
            height: screenWidth * 0.082,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.error_outline,
                color: const Color(0xFF1A1A1A),
                size: screenWidth * 0.082,
              );
            },
          ),
          SizedBox(height: screenWidth * 0.02),
          // 메인 텍스트
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tmoney RoundWind',
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
              height: 1.33,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true, // 단어 단위 줄바꿈
          ),
          // 서브타이틀
          if (subtitle != null) ...[
            SizedBox(height: screenWidth * 0.01),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Tmoney RoundWind',
                fontSize: screenWidth * 0.0224,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFB2B2B2),
                height: 1.33,
              ),
              textAlign: TextAlign.center,
              softWrap: true, // 단어 단위 줄바꿈
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // 하단 입력 바
  Widget _buildBottomInputBar(double screenWidth, double screenHeight) {
    // 키보드 높이를 별도 위젯으로 분리하여 리빌드 최소화
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardHeight), // 키보드 높이만큼 패딩 추가
          child: Container(
        width: screenWidth,
        constraints: BoxConstraints(
          minHeight: screenHeight * 0.087, // 최소 높이
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          border: Border(
            top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 입력 필드
            Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 48,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    border: const Border(
                      left: BorderSide(color: Color(0xFF2C3E50), width: 3),
                      bottom: BorderSide(color: Color(0xFF2C3E50), width: 6),
                      right: BorderSide(color: Color(0xFF2C3E50), width: 6),
                      top: BorderSide(color: Color(0xFF2C3E50), width: 3),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 씬 번호 표시 (씬이 선택되었을 때만)
                      if (_expandedSceneIndex != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 12, right: 8),
                          child: Text(
                            '씬 #${_expandedSceneIndex! + 1}',
                            style: const TextStyle(
                              fontFamily: 'Tmoney RoundWind',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          focusNode: _inputFocusNode,
                          textAlignVertical: TextAlignVertical.top,
                          maxLines: _isInputExpanded ? null : 1,
                          minLines: 1,
                          textInputAction: TextInputAction.newline,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: '수정 내용을 입력하세요...',
                            hintStyle: const TextStyle(
                              fontFamily: 'Tmoney RoundWind',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFFB2B2B2),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              // 씬 번호가 있으면 왼쪽 패딩 줄이기
                              horizontal: _expandedSceneIndex != null ? 0 : 16,
                              vertical: 12,
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(
                            fontFamily: 'Tmoney RoundWind',
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      // X 버튼 (항상 표시)
                      GestureDetector(
                        onTap: _inputController.text.isNotEmpty
                            ? () {
                                _inputController.clear();
                                setState(() {
                                  _isInputExpanded = false;
                                });
                              }
                            : null,
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _inputController.text.isNotEmpty
                                ? const Color(0xFFB2B2B2).withOpacity(0.2)
                                : const Color(0xFFB2B2B2).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: _inputController.text.isNotEmpty
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFFB2B2B2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 17),
            // 전송 버튼
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () => _handleSendModification(),
                child: Image.asset(
                  'assets/images/button_send.png',
                  width: 45,
                  height: 45,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            ],
          ),
        ),
        );
      },
    );
  }

  // 수정 내용 전송 처리
  Future<void> _handleSendModification() async {
    // 1. 씬이 선택되지 않았으면 알림 표시
    if (_expandedSceneIndex == null) {
      AppNotification.show(
        context,
        '수정할 씬을 선택해주세요!',
        type: NotificationType.warning,
      );
      return;
    }

    // 2. 입력 내용이 비어있으면 무시
    final userInput = _inputController.text.trim();
    if (userInput.isEmpty) {
      AppNotification.show(
        context,
        '수정 내용을 입력해주세요!',
        type: NotificationType.warning,
      );
      return;
    }

    // 3. 씬 수정 API 호출
    final selectedSceneIndex = _expandedSceneIndex!;
    final selectedScene = _scenes[selectedSceneIndex];

    // 키보드 닫기
    FocusScope.of(context).unfocus();

    // 로딩 다이얼로그 표시
    showLoadingDialog(
      context,
      title: '씬 수정 중',
      message: '씬 #${selectedSceneIndex + 1} 수정 중...',
    );

    try {
      // 전체 스토리보드 정보 가져오기
      final currentStoryboard = {
        'plan': _dataService.plan?.toJson() ?? {},
        'scenes': _scenes.map((scene) => scene.toJson()).toList(),
        'user_input': _dataService.userInput ?? {},
      };

      // 개별 씬 수정을 위한 수정 요청 문구 생성
      final modificationRequest = '씬 #${selectedSceneIndex + 1} ("${selectedScene.title}")을 다음과 같이 수정해주세요:\n\n$userInput\n\n다른 씬들은 그대로 유지하세요.';

      // 스토리보드 수정 API 호출
      final storyboardJson = await OpenAIService.modifyStoryboardWithFineTunedModel(
        currentStoryboard: currentStoryboard,
        modificationRequest: modificationRequest,
      );

      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (storyboardJson != null) {
        // 스토리보드 파싱
        final result = await OpenAIService.parseStoryboard(storyboardJson);

        if (result != null && result.plan != null && result.cueCards != null) {
        // 성공: 씬 데이터 업데이트
        setState(() {
          _scenes = List.from(result.cueCards!);
          _dataService.cueCards = _scenes;
          if (result.plan != null) {
            _dataService.plan = result.plan;
          }
          // 입력창 초기화
          _inputController.clear();
        });

        // Firebase에 실시간 반영
        await _dataService.updateCurrentStoryboard().catchError((error) {
          print('Firebase 업데이트 실패: $error');
        });

          // 성공 알림
          if (mounted) {
            AppNotification.show(
              context,
              '씬 #${selectedSceneIndex + 1}이(가) 수정되었습니다!',
              type: NotificationType.success,
            );
          }
        } else {
          // 파싱 실패
          if (mounted) {
            AppNotification.show(
              context,
              '씬 수정 결과를 처리하는데 실패했습니다.',
              type: NotificationType.error,
            );
          }
        }
      } else {
        // 실패: 에러 알림
        if (mounted) {
          AppNotification.show(
            context,
            '씬 수정에 실패했습니다. 다시 시도해주세요.',
            type: NotificationType.error,
          );
        }
      }
    } catch (e) {
      print('씬 수정 오류: $e');

      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 에러 알림
      if (mounted) {
        AppNotification.show(
          context,
          '씬 수정 중 오류가 발생했습니다: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  // 대체 씬 선택 모달 표시
  void _showAlternativeSceneModal(int sceneIndex, List<CueCard> alternativeScenes) {
    print('[SCENE_LIST] _showAlternativeSceneModal 호출');
    print('[SCENE_LIST]   - sceneIndex: $sceneIndex');
    print('[SCENE_LIST]   - alternativeScenes 개수: ${alternativeScenes.length}');
    
    if (alternativeScenes.isEmpty) {
      print('[SCENE_LIST] ⚠️ alternativeScenes가 비어있어서 모달을 표시하지 않습니다');
      AppNotification.show(
        context,
        '대체 씬이 없습니다.',
        type: NotificationType.warning,
      );
      return;
    }
    
    for (var i = 0; i < alternativeScenes.length; i++) {
      final altScene = alternativeScenes[i];
      print('[SCENE_LIST]   - 대체 씬 #${i + 1}: ${altScene.title}');
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    print('[SCENE_LIST] ✅ 모달 표시 시작');
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8), // shadowing
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.05,
        ),
        child: Container(
          width: screenWidth * 0.9,
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 헤더
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border.all(
                    color: const Color(0xFF1A1A1A),
                    width: 3,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '대체 씬 선택',
                      style: TextStyle(
                        fontFamily: 'Tmoney RoundWind',
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB2B2B2).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 대체 씬 리스트
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCEDCD3),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: const Border(
                      left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
                      right: BorderSide(color: Color(0xFF1A1A1A), width: 3),
                      bottom: BorderSide(color: Color(0xFF1A1A1A), width: 3),
                    ),
                  ),
                  child: alternativeScenes.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            child: Text(
                              '대체 씬이 없습니다.',
                              style: TextStyle(
                                fontFamily: 'Tmoney RoundWind',
                                fontSize: screenWidth * 0.04,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          itemCount: alternativeScenes.length,
                          itemBuilder: (context, altIndex) {
                            print('[SCENE_LIST] ListView.builder - altIndex: $altIndex, title: ${alternativeScenes[altIndex].title}');
                            final altScene = alternativeScenes[altIndex];
                            return Padding(
                              padding: EdgeInsets.only(bottom: screenWidth * 0.04),
                              child: GestureDetector(
                                onTap: () {
                                  // 확인 팝업 표시
                                  _showReplaceConfirmationDialog(
                                    sceneIndex: sceneIndex,
                                    altIndex: altIndex,
                                    altSceneTitle: altScene.title,
                                    screenWidth: screenWidth,
                                  );
                                },
                                child: _buildAlternativeSceneCard(
                                  altScene: altScene,
                                  altIndex: altIndex,
                                  sceneIndex: sceneIndex,
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 대체 씬 카드 빌드 (확장된 형태)
  Widget _buildAlternativeSceneCard({
    required CueCard altScene,
    required int altIndex,
    required int sceneIndex,
    required double screenWidth,
    required double screenHeight,
  }) {
    final thumbnailWidth = screenWidth * 0.4;
    final thumbnailHeight = screenHeight * 0.122;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(screenWidth * 0.032),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.0075),
              top: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.0075),
              right: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.015),
              bottom: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.015),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 기본 정보
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 썸네일
                  Container(
                    width: thumbnailWidth,
                    height: thumbnailHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB2B2B2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border(
                        left: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.005),
                        top: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.005),
                        right: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.0087),
                        bottom: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.0087),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: altScene.storyboardImageUrl != null
                          ? Image.network(
                              altScene.storyboardImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFB2B2B2),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: const Color(0xFF1A1A1A).withOpacity(0.3),
                                    size: 24,
                                  ),
                                );
                              },
                            )
                          : Container(color: const Color(0xFFB2B2B2)),
                    ),
                  ),

                  SizedBox(width: screenWidth * 0.048),

                  // 제목
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          altScene.title,
                          style: TextStyle(
                            fontFamily: 'Tmoney RoundWind',
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                            height: 1.3,
                          ),
                          softWrap: true,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: screenHeight * 0.015),
                          child: Text(
                            '${altScene.allocatedSec ~/ 60}분',
                            style: TextStyle(
                              fontFamily: 'Tmoney RoundWind',
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFFB2B2B2),
                              height: 1.29,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 요약
              if (altScene.summary.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.02),
                  child: Text(
                    altScene.summary.join(' '),
                    style: TextStyle(
                      fontFamily: 'Tmoney RoundWind',
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF1A1A1A),
                      height: 1.31,
                    ),
                    softWrap: true,
                  ),
                ),

              // 체크리스트
              if (altScene.checklist.isNotEmpty) ...[
                SizedBox(height: screenHeight * 0.025),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.032),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.0075),
                      top: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.0075),
                      right: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.015),
                      bottom: BorderSide(color: const Color(0xFF1A1A1A), width: screenWidth * 0.015),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: altScene.checklist.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isLast = index == altScene.checklist.length - 1;

                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : screenHeight * 0.01),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: screenWidth * 0.047,
                              height: screenWidth * 0.047,
                              margin: EdgeInsets.only(top: screenWidth * 0.012),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                border: Border.all(
                                  color: const Color(0xFF1A1A1A),
                                  width: screenWidth * 0.005,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.025),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: screenWidth * 0.012),
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontFamily: 'Tmoney RoundWind',
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A1A1A),
                                    height: 1.31,
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),

      ],
    );
  }

  // 이미지 모달 표시
  void _showImageModal(BuildContext context, String imageUrl, double screenWidth, double screenHeight) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8), // 나머지 화면 어둡게
      barrierDismissible: true, // shadowing 부분 클릭 시 닫기
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.1,
        ),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(), // 이미지 클릭 시에도 닫기
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 이미지 비율을 1:1로 가정 (DALL-E는 1024x1024)
              // 박스는 이미지보다 살짝 크게 (padding 포함)
              final padding = screenWidth * 0.015;
              final maxImageSize = constraints.maxWidth - (padding * 2);
              final boxSize = maxImageSize + (padding * 2);
              
              return Container(
                width: boxSize,
                height: boxSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF1A1A1A),
                    width: 6,
                  ),
                ),
                padding: EdgeInsets.all(padding), // 테두리보다 살짝 작게
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFB2B2B2),
                        child: const Center(
                          child: Icon(Icons.error, color: Color(0xFF1A1A1A)),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// 체크마크 그리기
class _CheckMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.8, size.height * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
