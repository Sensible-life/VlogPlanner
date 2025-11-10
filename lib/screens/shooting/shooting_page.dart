import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../models/cue_card.dart';
import '../../models/take.dart';
import '../../models/shooting_session.dart';
import '../../services/shake_detection_service.dart';
import '../../services/system_check_service.dart';
import '../../widgets/shooting_overlay.dart';

/// 촬영 화면
class ShootingPage extends StatefulWidget {
  final CueCard scene;
  final ShootingSession? existingSession;

  const ShootingPage({
    super.key,
    required this.scene,
    this.existingSession,
  });

  @override
  State<ShootingPage> createState() => _ShootingPageState();
}

class _ShootingPageState extends State<ShootingPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;

  // 촬영 세션
  late ShootingSession _session;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // 흔들림 감지
  final ShakeDetectionService _shakeDetector = ShakeDetectionService();
  StreamSubscription<ShakeEvent>? _shakeSubscription;
  ShakeEvent? _lastShakeEvent;

  // 시스템 상태
  BatteryStatus? _batteryStatus;
  StorageStatus? _storageStatus;

  // UI 상태
  bool _showReferenceOverlay = false;
  double _referenceOpacity = 0.5;
  bool _showScript = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 세션 초기화
    _session = widget.existingSession ??
        ShootingSession(
          sceneId: widget.scene.title,
          sceneName: widget.scene.title,
          startTime: DateTime.now(),
          takes: [],
          checklist: _createChecklist(),
          targetTakeCount: 5,
          requiredCircleTakes: 1,
        );

    _initializeCamera();
    _initializeSensors();
    _checkSystemStatus();
  }

  /// 체크리스트 생성
  Map<String, bool> _createChecklist() {
    final checklist = <String, bool>{};
    for (final item in widget.scene.checklist) {
      checklist[item] = false;
    }
    return checklist;
  }

  /// 카메라 초기화
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showError('카메라를 찾을 수 없습니다');
        return;
      }

      _cameraController = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      print('[SHOOTING] 카메라 초기화 완료');
    } catch (e) {
      print('[SHOOTING] 카메라 초기화 오류: $e');
      _showError('카메라 초기화 실패: $e');
    }
  }

  /// 센서 초기화 (흔들림 감지)
  void _initializeSensors() {
    _shakeDetector.startMonitoring();
    _shakeSubscription = _shakeDetector.shakeStream.listen((event) {
      if (_isRecording) {
        setState(() {
          _lastShakeEvent = event;
        });

        // 3초 후 경고 자동 숨김
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              if (_lastShakeEvent == event) {
                _lastShakeEvent = null;
              }
            });
          }
        });
      }
    });
  }

  /// 시스템 상태 체크
  Future<void> _checkSystemStatus() async {
    final result = await SystemCheckService.performFullCheck();
    if (mounted) {
      setState(() {
        _batteryStatus = result.battery;
        _storageStatus = result.storage;
      });

      if (!result.isReady) {
        _showWarningDialog(result.warnings);
      }
    }

    // 주기적 체크 (30초마다)
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) _checkSystemStatus();
    });
  }

  /// 녹화 시작
  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError('카메라가 준비되지 않았습니다');
      return;
    }

    if (_isRecording) return;

    try {
      await _cameraController!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
        _lastShakeEvent = null;
      });

      // 녹화 시간 타이머
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });
      });

      print('[SHOOTING] 녹화 시작');
    } catch (e) {
      print('[SHOOTING] 녹화 시작 오류: $e');
      _showError('녹화 시작 실패: $e');
    }
  }

  /// 녹화 중지 및 저장
  Future<void> _stopRecording({TakeQuality quality = TakeQuality.neutral}) async {
    if (!_isRecording) return;

    try {
      _recordingTimer?.cancel();

      final videoFile = await _cameraController!.stopVideoRecording();

      // 파일명 변경 (자동 태깅)
      final newPath = await _renameVideoFile(videoFile);

      // Take 생성
      final take = Take(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        takeNumber: _session.takes.length + 1,
        sceneId: _session.sceneId,
        timestamp: DateTime.now(),
        filePath: newPath,
        durationSeconds: _recordingSeconds,
        quality: quality,
        isCircleTake: quality == TakeQuality.good,
      );

      setState(() {
        _isRecording = false;
        _session = _session.copyWith(
          takes: [..._session.takes, take],
          status: SceneStatus.inProgress,
        );
      });

      print('[SHOOTING] 녹화 완료: Take ${take.takeNumber}');

      // 테이크 평가 다이얼로그
      _showTakeEvaluationDialog(take);
    } catch (e) {
      print('[SHOOTING] 녹화 중지 오류: $e');
      _showError('녹화 중지 실패: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  /// 파일명 자동 태깅
  Future<String> _renameVideoFile(XFile videoFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final sceneNumber = _session.sceneId.replaceAll(' ', '_');
    final takeNumber = _session.takes.length + 1;
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');

    final newFileName =
        'S${sceneNumber}_T${takeNumber.toString().padLeft(2, '0')}_Plotto_$timestamp.mp4';
    final newPath = '${directory.path}/$newFileName';

    final file = File(videoFile.path);
    await file.copy(newPath);
    await file.delete();

    print('[SHOOTING] 파일명 태깅: $newFileName');
    return newPath;
  }

  /// 테이크 평가 다이얼로그
  void _showTakeEvaluationDialog(Take take) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Take ${take.takeNumber} 평가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('촬영 시간: ${take.durationSeconds}초'),
            const SizedBox(height: 20),
            const Text('테이크 품질을 평가하세요:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _updateTakeQuality(take, TakeQuality.bad);
              Navigator.pop(context);
            },
            child: Text('👎 나쁨', style: TextStyle(color: AppColors.error)),
          ),
          TextButton(
            onPressed: () {
              _updateTakeQuality(take, TakeQuality.neutral);
              Navigator.pop(context);
            },
            child: Text('👌 보통', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              _updateTakeQuality(take, TakeQuality.good, isCircle: true);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('⭐ OK 컷'),
          ),
        ],
      ),
    );
  }

  /// 테이크 품질 업데이트
  void _updateTakeQuality(Take take, TakeQuality quality, {bool isCircle = false}) {
    final updatedTake = take.copyWith(
      quality: quality,
      isCircleTake: isCircle,
    );

    final updatedTakes = _session.takes.map((t) {
      return t.id == take.id ? updatedTake : t;
    }).toList();

    setState(() {
      _session = _session.copyWith(takes: updatedTakes);
    });

    // 완료 조건 체크
    if (_session.isReadyToComplete) {
      _showCompletionDialog();
    }
  }

  /// 씬 완료 다이얼로그
  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 촬영 완료 조건 달성!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('총 테이크: ${_session.totalTakeCount}개'),
            Text('OK 컷: ${_session.circleTakeCount}개'),
            Text('체크리스트: ${_session.checklistProgress.toStringAsFixed(0)}%'),
            const SizedBox(height: 16),
            const Text('이 씬의 촬영을 완료하시겠습니까?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('계속 촬영'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeScene();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }

  /// 씬 촬영 완료
  void _completeScene() {
    final completedSession = _session.copyWith(
      status: SceneStatus.completed,
      endTime: DateTime.now(),
    );

    Navigator.pop(context, completedSession);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                '카메라 준비 중...',
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 카메라 프리뷰
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),

          // 레퍼런스 이미지 오버레이
          if (_showReferenceOverlay && widget.scene.thumbnailUrl != null)
            Positioned.fill(
              child: Opacity(
                opacity: _referenceOpacity,
                child: Image.network(
                  widget.scene.thumbnailUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // 촬영 정보 오버레이
          ShootingOverlay(
            session: _session,
            scene: widget.scene,
            isRecording: _isRecording,
            recordingSeconds: _recordingSeconds,
            batteryStatus: _batteryStatus,
            storageStatus: _storageStatus,
            lastShakeEvent: _lastShakeEvent,
            onChecklistToggle: _toggleChecklistItem,
          ),

          // 하단 컨트롤
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  /// 체크리스트 항목 토글
  void _toggleChecklistItem(String item) {
    final updatedChecklist = Map<String, bool>.from(_session.checklist);
    updatedChecklist[item] = !updatedChecklist[item]!;

    setState(() {
      _session = _session.copyWith(checklist: updatedChecklist);
    });
  }

  /// 하단 컨트롤 UI
  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 레퍼런스 토글
          _buildControlButton(
            icon: Icons.image,
            label: '레퍼런스',
            onPressed: () {
              setState(() {
                _showReferenceOverlay = !_showReferenceOverlay;
              });
            },
            isActive: _showReferenceOverlay,
          ),

          // 녹화 버튼
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? AppColors.error : AppColors.primary,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.circle,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          // 대본 토글
          _buildControlButton(
            icon: Icons.subject,
            label: '대본',
            onPressed: () {
              // TODO: 대본 표시 구현
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showWarningDialog(List<String> warnings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 주의사항'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: warnings.map((w) => Text('• $w')).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _recordingTimer?.cancel();
    _shakeDetector.dispose();
    _shakeSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }
}
