import 'package:flutter/material.dart';
import '../widgets/progress_notification.dart';

class ProgressNotificationService {
  static final ProgressNotificationService _instance = ProgressNotificationService._internal();
  factory ProgressNotificationService() => _instance;
  ProgressNotificationService._internal();

  OverlayEntry? _overlayEntry;
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _isShowing = false;
  
  double _progress = 0.0;
  String _currentTask = '';

  // 초기화 (main.dart에서 호출)
  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  // 현재 context 가져오기
  BuildContext? get _context {
    return _navigatorKey?.currentContext;
  }

  // 진행 상황 표시 시작
  void show({double progress = 0.0, String task = '초기화 중...'}) {
    if (_navigatorKey == null) {
      print('[PROGRESS] NavigatorKey가 초기화되지 않았습니다.');
      return;
    }

    final navigatorState = _navigatorKey!.currentState;
    if (navigatorState == null) {
      print('[PROGRESS] NavigatorState를 찾을 수 없습니다.');
      return;
    }

    final overlay = navigatorState.overlay;
    if (overlay == null) {
      print('[PROGRESS] Overlay를 찾을 수 없습니다.');
      return;
    }

    _progress = progress;
    _currentTask = task;
    
    if (_isShowing) {
      // 이미 표시 중이면 업데이트만
      _updateOverlay();
      return;
    }

    try {
      _isShowing = true;
      _overlayEntry = _createOverlayEntry();
      
      // Overlay에 추가
      overlay.insert(_overlayEntry!);
      print('[PROGRESS] ✅ 진행 상황 알림 표시: $task (${(progress * 100).toInt()}%)');
    } catch (e, stackTrace) {
      print('[PROGRESS] ❌ Overlay 삽입 실패: $e');
      print('[PROGRESS] 스택 트레이스: $stackTrace');
      _isShowing = false;
      _overlayEntry = null;
    }
  }

  // 진행 상황 업데이트
  void update({required double progress, required String task}) {
    _progress = progress;
    _currentTask = task;
    
    if (_isShowing) {
      _updateOverlay();
      print('[PROGRESS] 📊 진행 상황 업데이트: $task (${(progress * 100).toInt()}%)');
    } else {
      show(progress: progress, task: task);
    }
  }

  // 진행 상황 숨기기
  void hide() {
    if (_overlayEntry != null && _isShowing) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isShowing = false;
      _progress = 0.0;
      _currentTask = '';
      print('[PROGRESS] ✅ 진행 상황 알림 숨김');
    }
  }

  // OverlayEntry 생성
  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      maintainState: true,
      opaque: false, // 투명하게 만들어서 뒤의 요소 클릭 가능하도록
      builder: (overlayContext) {
        // MediaQuery를 사용하기 위해 navigatorKey의 context 사용
        final context = _navigatorKey?.currentContext ?? overlayContext;
        final padding = MediaQuery.of(context).padding;
        // 상단바 텍스트와 동일한 위치 (상단바 높이 79, 텍스트는 세로 중앙 약 39.5 위치)
        final topPosition = padding.top + 10; // 상단바 텍스트와 동일한 위치
        
        print('[PROGRESS] OverlayEntry 빌드 중... top: $topPosition');
        
        return Positioned(
          top: topPosition,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: true, // 클릭 이벤트 무시 (뒤의 요소 클릭 가능)
            child: Material(
              color: Colors.transparent,
              elevation: 1000, // 다른 위젯 위에 표시되도록 높은 elevation
              child: Center(
                child: ProgressNotification.fromService(),
              ),
            ),
          ),
        );
      },
    );
  }

  // Overlay 업데이트
  void _updateOverlay() {
    if (_overlayEntry != null && _isShowing) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  // 현재 상태 확인
  bool get isShowing => _isShowing;
  double get progress => _progress;
  String get currentTask => _currentTask;
}

