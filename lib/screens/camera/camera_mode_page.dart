import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../ui/styles.dart';
import '../../services/video_storage_service.dart';
import '../../services/youtube_search_service.dart';
import '../../services/dalle_image_service.dart';
import '../../services/vlog_data_service.dart';
import '../../widgets/app_notification.dart';
import '../home_page.dart';

// 이미지 생성 상태
enum ImageGenerationStatus {
  none,       // 생성되지 않음
  generating, // 생성 중
  completed,  // 생성 완료
}

class CameraModePage extends StatefulWidget {
  final int sceneNumber;
  final int takeNumber;
  final List<String> shootingGuides;
  final Map<String, dynamic>? sceneInfo; // 씬 정보 전달

  const CameraModePage({
    super.key,
    this.sceneNumber = 3,
    this.takeNumber = 2,
    this.shootingGuides = const [
      '야경 분수 촬영',
      '러닝하는 사람들 촬영',
      '셀프 카메라 전환으로 마무리',
    ],
    this.sceneInfo,
  });

  @override
  State<CameraModePage> createState() => _CameraModePageState();
}

class _CameraModePageState extends State<CameraModePage> {
  CameraController? _cameraController;
  bool _isGuideOn = true;
  bool _isRecording = false;
  bool _showReference = false; // 오른쪽 YouTube 레퍼런스
  bool _showPreviousTake = false; // 왼쪽 이전 Take
  Set<int> _checkedChecklistIndices = {}; // 체크된 체크리스트 항목 인덱스

  // 구도 이미지 관련
  int? _selectedChecklistIndex; // 선택된 체크리스트 인덱스
  bool _showCompositionImage = false; // 구도 이미지 표시 여부
  final VlogDataService _dataService = VlogDataService();

  // 체크리스트 항목별 이미지 생성 상태
  final Map<int, ImageGenerationStatus> _imageGenerationStatus = {};

  // YouTube 플레이어 관련
  YoutubePlayerController? _youtubeController;
  Offset _youtubePosition = Offset(0, 0); // 초기 위치 (나중에 화면 크기에 따라 설정)
  VideoOrientation _videoOrientation = VideoOrientation.unknown; // 영상 방향

  // 이전 Take 관련
  List<File> _previousTakes = [];
  int _currentTakeIndex = 0;
  VideoPlayerController? _videoPlayerController;

  int _currentSceneNumber = 0;
  int _currentTakeNumber = 1;

  // 흔들림 감지 관련
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _lastAcceleration = 0.0;
  DateTime _lastShakeWarning = DateTime(1970); // 마지막 경고 시간
  static const double _shakeThreshold = 2.5; // 흔들림 임계값 (m/s²)
  static const Duration _warningCooldown = Duration(seconds: 2); // 경고 쿨다운 시간

  @override
  void initState() {
    super.initState();
    _currentSceneNumber = widget.sceneInfo?['sceneIndex'] ?? widget.sceneNumber;
    _initCamera();
    _loadPreviousTakes();
    _initYoutubePlayer();
    _initChecklistImageStatus();
    _loadChecklistStatus();
  }

  // 저장된 체크리스트 상태 로드
  void _loadChecklistStatus() {
    final sceneIndex = _currentSceneNumber - 1;
    if (_dataService.cueCards != null && sceneIndex >= 0 && sceneIndex < _dataService.cueCards!.length) {
      final scene = _dataService.cueCards![sceneIndex];
      if (scene.checkedChecklistIndices != null) {
        _checkedChecklistIndices = Set<int>.from(scene.checkedChecklistIndices!);
      } else {
        _checkedChecklistIndices = {};
      }
    } else {
      _checkedChecklistIndices = {};
    }
  }

  // 체크리스트 상태 저장
  void _saveChecklistStatus() {
    final sceneIndex = _currentSceneNumber - 1;
    if (_dataService.cueCards != null && sceneIndex >= 0 && sceneIndex < _dataService.cueCards!.length) {
      final scene = _dataService.cueCards![sceneIndex];
      final updatedScene = scene.copyWith(
        checkedChecklistIndices: Set<int>.from(_checkedChecklistIndices),
      );
      _dataService.cueCards![sceneIndex] = updatedScene;
      
      // Firebase에 실시간 반영
      _dataService.updateCurrentStoryboard().catchError((error) {
        print('Firebase 업데이트 실패: $error');
      });
    }
  }

  // 체크리스트 이미지 생성 상태 초기화
  void _initChecklistImageStatus() {
    final checklist = widget.sceneInfo?['checklist'] as List<dynamic>? ?? widget.shootingGuides;
    final sceneId = widget.sceneInfo?['id']?.toString() ?? 'scene_${widget.sceneNumber}';

    for (int i = 0; i < checklist.length; i++) {
      // 이미 생성된 이미지가 있는지 확인
      if (_dataService.hasCompositionImage(sceneId, i)) {
        _imageGenerationStatus[i] = ImageGenerationStatus.completed;
      } else {
        _imageGenerationStatus[i] = ImageGenerationStatus.none;
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.high,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  // YouTube 플레이어 초기화
  void _initYoutubePlayer() async {
    final referenceUrl = widget.sceneInfo?['referenceVideoUrl'] as String?;
    final timestamp = widget.sceneInfo?['referenceVideoTimestamp'] as int? ?? 0;

    if (referenceUrl != null && referenceUrl.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(referenceUrl);

      print('[YOUTUBE_PLAYER] 레퍼런스 URL: $referenceUrl');
      print('[YOUTUBE_PLAYER] 비디오 ID: $videoId');
      print('[YOUTUBE_PLAYER] 시작 시간: $timestamp초');

      // 영상 방향 감지
      print('[YOUTUBE_PLAYER] 영상 방향 감지 중...');
      final orientation = await YoutubeSearchService.getVideoOrientation(referenceUrl);
      setState(() {
        _videoOrientation = orientation;
      });
      print('[YOUTUBE_PLAYER] 감지된 방향: $_videoOrientation');

      if (videoId != null) {
        try {
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: YoutubePlayerFlags(
              autoPlay: true, // 자동 재생
              mute: false,
              startAt: timestamp,
              loop: true,
              enableCaption: false,
              isLive: false,
              forceHD: false,
              hideControls: false,
              controlsVisibleAtStart: true,
            ),
          );

          // 플레이어 상태 리스너 추가
          _youtubeController!.addListener(() {
            if (_youtubeController!.value.isReady) {
              print('[YOUTUBE_PLAYER] ✅ 플레이어 준비 완료');
            }
            if (_youtubeController!.value.hasError) {
              print('[YOUTUBE_PLAYER] ❌ 에러 발생: ${_youtubeController!.value.errorCode}');
            }
          });

          print('[YOUTUBE_PLAYER] ✅ 컨트롤러 생성 완료');
        } catch (e) {
          print('[YOUTUBE_PLAYER] ❌ 컨트롤러 생성 실패: $e');
        }
      } else {
        print('[YOUTUBE_PLAYER] ❌ 비디오 ID를 추출할 수 없음');
      }
    } else {
      print('[YOUTUBE_PLAYER] ⚠️ 레퍼런스 URL이 없음');
    }
  }

  // 이전 Take 비디오 로드
  Future<void> _loadPreviousTakes() async {
    final takes = await VideoStorageService.getPreviousTakes(
      sceneNumber: _currentSceneNumber,
    );
    
    setState(() {
      _previousTakes = takes;
    });

    // 다음 Take 번호 계산
    final nextTake = await VideoStorageService.getNextTakeNumber(
      sceneNumber: _currentSceneNumber,
    );
    setState(() {
      _currentTakeNumber = nextTake;
    });

    // 첫 번째 이전 Take 비디오 플레이어 초기화
    if (_previousTakes.isNotEmpty) {
      _initVideoPlayer(_previousTakes[0]);
    }
  }

  // 로컬 비디오 플레이어 초기화
  void _initVideoPlayer(File videoFile) {
    _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.file(videoFile)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoPlayerController?.setLooping(true);
          if (_showPreviousTake) {
            _videoPlayerController?.play();
          }
        }
      });
  }

  // 다음 이전 Take로 전환 (스와이프)
  void _nextPreviousTake() {
    if (_previousTakes.isEmpty) return;
    
    setState(() {
      _currentTakeIndex = (_currentTakeIndex + 1) % _previousTakes.length;
    });
    _initVideoPlayer(_previousTakes[_currentTakeIndex]);
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _cameraController?.dispose();
    _youtubeController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _toggleRecording() async {
    if (_isRecording) {
      // 녹화 중지
      _stopShakeDetection();
      
      try {
        final videoFile = await _cameraController?.stopVideoRecording();
        
        if (videoFile != null) {
          // 표준화된 파일명으로 저장
          final savedPath = await VideoStorageService.saveVideo(
            sourcePath: videoFile.path,
            sceneNumber: _currentSceneNumber,
            takeNumber: _currentTakeNumber,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('비디오 저장 완료: ${VideoStorageService.generateFileName(
                sceneNumber: _currentSceneNumber,
                takeNumber: _currentTakeNumber,
              )}')),
            );
          }
          
          // 이전 Take 목록 새로고침
          await _loadPreviousTakes();
        }
      } catch (e) {
        print('녹화 중지 오류: $e');
      }
      
      setState(() {
        _isRecording = false;
      });
    } else {
      // 녹화 시작
      try {
        await _cameraController?.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
        _startShakeDetection();
      } catch (e) {
        print('녹화 시작 오류: $e');
      }
    }
  }

  // 흔들림 감지 시작
  void _startShakeDetection() {
    _lastAcceleration = 0.0;
    _lastShakeWarning = DateTime(1970);
    
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        if (!_isRecording) return; // 촬영 중이 아니면 무시
        
        // 가속도의 크기 계산 (3축 벡터의 크기)
        final acceleration = sqrt(
          event.x * event.x + 
          event.y * event.y + 
          event.z * event.z
        );
        
        // 이전 가속도와의 차이 계산 (변화량)
        final delta = (acceleration - _lastAcceleration).abs();
        _lastAcceleration = acceleration;
        
        // 흔들림 감지: 변화량이 임계값을 넘으면 경고
        if (delta > _shakeThreshold) {
          final now = DateTime.now();
          // 쿨다운 시간이 지났는지 확인
          if (now.difference(_lastShakeWarning) > _warningCooldown) {
            _lastShakeWarning = now;
            _showShakeWarning();
          }
        }
      },
      onError: (error) {
        print('[SHAKE_DETECTION] 센서 오류: $error');
      },
    );
  }

  // 흔들림 감지 중지
  void _stopShakeDetection() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  // 흔들림 경고 표시
  void _showShakeWarning() {
    if (!mounted) return;
    
    AppNotification.show(
      context,
      '⚠️ 카메라가 흔들리고 있습니다!\n손을 더 안정적으로 잡아주세요.',
      type: NotificationType.warning,
      showActions: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final topPadding = MediaQuery.of(context).padding.top;
    
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      resizeToAvoidBottomInset: false, // 키보드 나타날 때 불필요한 리렌더링 방지
      body: Stack(
        children: [
          // 카메라 프리뷰 (배경) - 상단 바 아래로 살짝 이동
          Positioned(
            top: topPadding + 79 + 10, // 상단 SafeArea + 상단 바 높이 + 여백
            left: 0,
            right: 0,
            bottom: 120, // 하단 바 높이만큼 위에서 끝나도록
            child: _buildCameraPreview(screenWidth, screenHeight),
          ),

          // 상단 SafeArea 영역 배경색
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPadding,
            child: Container(
              color: const Color(0xFFCEDCD3),
            ),
          ),

          // SafeArea 안의 UI 요소들 (상단만)
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // 구도 이미지 오버레이 (오른쪽)
                if (_showCompositionImage && _selectedChecklistIndex != null)
                  _buildCompositionImageOverlay(screenWidth, screenHeight),

                // 이전 Take 오버레이 (왼쪽)
                if (_showPreviousTake && _previousTakes.isNotEmpty)
                  _buildPreviousTakeOverlay(screenWidth, screenHeight),

                // 상단 바 (알림 리스트 + 촬영 가이드 텍스트 + ON/OFF 토글 + 카메라 회전)
                _buildTopBar(screenWidth, screenHeight),

                // 씬/테이크 정보 (가이드 ON일 때만)
                if (_isGuideOn) _buildSceneTakeInfo(screenWidth, screenHeight),

                // 촬영 가이드 체크리스트
                if (_isGuideOn) _buildShootingGuideChecklist(screenWidth, screenHeight),
              ],
            ),
          ),

          // 하단 영역 (촬영 버튼 + 양쪽 오버레이) - SafeArea 밖, 화면 맨 아래
          _buildBottomControls(screenWidth, screenHeight, bottomPadding),
        ],
      ),
    );
  }

  // 카메라 프리뷰
  Widget _buildCameraPreview(double screenWidth, double screenHeight) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        width: screenWidth,
        height: screenHeight,
        color: AppColors.black,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.white),
        ),
      );
    }

    return CameraPreview(_cameraController!);
  }

  // 구도 이미지 오버레이 (오른쪽)
  Widget _buildCompositionImageOverlay(double screenWidth, double screenHeight) {
    final sceneId = widget.sceneInfo?['id']?.toString() ?? 'scene_${widget.sceneNumber}';
    final imageUrl = _dataService.getCompositionImage(sceneId, _selectedChecklistIndex!);

    if (imageUrl == null) return SizedBox.shrink();

    final playerWidth = screenWidth * 0.45;
    final playerHeight = screenHeight * 0.25;

    return Positioned(
      top: 110,
      right: 10,
      child: GestureDetector(
        onTap: () {
          // 탭하면 크게 보기
          _showCompositionImageModal(imageUrl, screenWidth, screenHeight);
        },
        child: Container(
          width: playerWidth,
          height: playerHeight,
          decoration: BoxDecoration(
            color: AppColors.black,
            border: Border.all(color: AppColors.primary, width: 3),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 구도 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: playerWidth,
                  height: playerHeight,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.primary,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // 403 에러는 이미지 URL 만료를 의미
                    print('[CAMERA] 구도 이미지 로드 실패 (만료되었을 수 있음): $error');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, color: AppColors.white, size: 24),
                          SizedBox(height: 4),
                          Text(
                            '이미지 만료',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontFamily: 'Tmoney RoundWind',
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '다시 생성 필요',
                            style: TextStyle(
                              color: AppColors.white.withOpacity(0.7),
                              fontSize: 9,
                              fontFamily: 'Tmoney RoundWind',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 탭하여 크게 보기 힌트 (상단 중앙)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '탭하여 크게 보기',
                      style: TextStyle(
                        fontFamily: 'Tmoney RoundWind',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // X 버튼 (닫기)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showCompositionImage = false;
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.black, width: 1.5),
                    ),
                    child: Icon(Icons.close, size: 14, color: AppColors.black),
                  ),
                ),
              ),

              // 구도 이미지 라벨
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.white, width: 1),
                    ),
                    child: Text(
                      '구도 예시',
                      style: TextStyle(
                        fontFamily: 'Tmoney RoundWind',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 구도 이미지 크게 보기 모달
  void _showCompositionImageModal(String imageUrl, double screenWidth, double screenHeight) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.1,
        ),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: LayoutBuilder(
            builder: (context, constraints) {
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
                padding: EdgeInsets.all(padding),
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
                      // 403 에러는 이미지 URL 만료를 의미
                      print('[CAMERA] 구도 이미지 모달 로드 실패 (만료되었을 수 있음): $error');
                      return Container(
                        color: const Color(0xFFB2B2B2),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh, color: const Color(0xFF1A1A1A), size: 32),
                              SizedBox(height: 8),
                              Text(
                                '이미지가 만료되었습니다',
                                style: TextStyle(
                                  fontFamily: 'Tmoney RoundWind',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '다시 생성해주세요',
                                style: TextStyle(
                                  fontFamily: 'Tmoney RoundWind',
                                  fontSize: 12,
                                  color: const Color(0xFF1A1A1A).withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
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

  // YouTube 레퍼런스 오버레이 (드래그 가능한 소형화 플레이어)
  Widget _buildYoutubeOverlay(double screenWidth, double screenHeight) {
    // YouTube 플레이어 크기 - 영상 방향에 따라 동적 조정
    double playerWidth;
    double playerHeight;

    // 감지된 영상 방향에 따라 플레이어 크기 설정
    switch (_videoOrientation) {
      case VideoOrientation.vertical:
        // 세로 영상 (9:16 비율)
        playerWidth = 160.0;
        playerHeight = 284.0;
        print('[YOUTUBE_PLAYER] 세로 영상 플레이어 크기: ${playerWidth}x$playerHeight');
        break;

      case VideoOrientation.horizontal:
        // 가로 영상 (16:9 비율)
        playerWidth = 240.0;
        playerHeight = 135.0;
        print('[YOUTUBE_PLAYER] 가로 영상 플레이어 크기: ${playerWidth}x$playerHeight');
        break;

      case VideoOrientation.square:
        // 정사각형 영상 (1:1 비율)
        playerWidth = 200.0;
        playerHeight = 200.0;
        print('[YOUTUBE_PLAYER] 정사각형 영상 플레이어 크기: ${playerWidth}x$playerHeight');
        break;

      case VideoOrientation.unknown:
      default:
        // 기본값: 가로 영상으로 설정
        playerWidth = 240.0;
        playerHeight = 135.0;
        print('[YOUTUBE_PLAYER] 기본 플레이어 크기: ${playerWidth}x$playerHeight');
        break;
    }
    
    // 초기 위치 설정 (우측 상단)
    if (_youtubePosition == Offset.zero) {
      _youtubePosition = Offset(
        screenWidth - playerWidth - 10, // 오른쪽에서 10px 여백
        80, // 상단 바 아래
      );
    }

    return Positioned(
      left: _youtubePosition.dx,
      top: _youtubePosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            // 드래그 시 위치 업데이트 (경계 체크)
            double newX = _youtubePosition.dx + details.delta.dx;
            double newY = _youtubePosition.dy + details.delta.dy;

            // 화면 경계 체크 (대략적인 높이 300으로 설정)
            newX = newX.clamp(0.0, screenWidth - playerWidth);
            newY = newY.clamp(66.0, screenHeight - 300); // 상단바와 하단 컨트롤 고려

            _youtubePosition = Offset(newX, newY);
          });
        },
        child: Container(
          width: playerWidth,
          decoration: BoxDecoration(
            color: AppColors.black,
            border: Border.all(color: AppColors.primary, width: 3),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // YouTube 플레이어 (비율 자동 유지)
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: YoutubePlayer(
                  controller: _youtubeController!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: AppColors.primary,
                  width: playerWidth,
                  onReady: () {
                    print('[YOUTUBE_PLAYER] ✅ 플레이어 준비됨 - 자동 재생');
                    setState(() {}); // 상태 업데이트
                  },
                  onEnded: (metadata) {
                    print('[YOUTUBE_PLAYER] ✅ 재생 완료');
                  },
                ),
              ),
              
              // 에러 표시
              if (_youtubeController!.value.hasError)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 24),
                      SizedBox(height: 4),
                      Text(
                        '재생 불가',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 9,
                          fontFamily: 'Tmoney RoundWind',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // 드래그 힌트 (상단 중앙)
              Positioned(
                top: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              
              // 닫기 버튼
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () {
                    _youtubeController?.pause();
                    setState(() {
                      _showReference = false;
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.black, width: 1.5),
                    ),
                    child: Icon(Icons.close, size: 14, color: AppColors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 이전 Take 오버레이 (왼쪽)
  Widget _buildPreviousTakeOverlay(double screenWidth, double screenHeight) {
    return Positioned(
      top: 110,
      left: 10,
      child: GestureDetector(
        onTap: _nextPreviousTake, // 탭하면 다음 Take로 전환
        child: Container(
          width: screenWidth * 0.45,
          height: screenHeight * 0.25,
          decoration: BoxDecoration(
            color: AppColors.black,
            border: Border.all(color: AppColors.primary, width: 3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // 비디오 플레이어
              if (_videoPlayerController != null &&
                  _videoPlayerController!.value.isInitialized)
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoPlayerController!.value.size.width,
                        height: _videoPlayerController!.value.size.height,
                        child: VideoPlayer(_videoPlayerController!),
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              
              // Take 정보
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary, width: 1),
                  ),
                  child: Text(
                    'Take ${_currentTakeIndex + 1}/${_previousTakes.length}',
                    style: TextStyle(
                      fontFamily: 'Tmoney RoundWind',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              
              // 닫기 버튼
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    _videoPlayerController?.pause();
                    setState(() {
                      _showPreviousTake = false;
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.black, width: 1.5),
                    ),
                    child: Icon(Icons.close, size: 16, color: AppColors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 상단 바
  Widget _buildTopBar(double screenWidth, double screenHeight) {
    return Positioned(
      top: 0,
      left: 0,
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

            // 중앙 화면 이름 + ON/OFF 토글
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 화면 이름
                  Text(
                    '촬영 가이드',
                    style: TextStyle(
                      fontFamily: 'Tmoney RoundWind',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // ON/OFF 토글 버튼
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isGuideOn = !_isGuideOn;
                      });
                    },
                    child: Container(
                      width: 80,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border(
                          left: BorderSide(color: AppColors.black, width: 1),
                          bottom: BorderSide(color: AppColors.black, width: 2.5),
                          right: BorderSide(color: AppColors.black, width: 2.5),
                          top: BorderSide(color: AppColors.black, width: 1),
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Stack(
                        children: [
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: _isGuideOn ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              width: 40,
                              height: 26,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                border: Border.all(color: AppColors.black, width: 1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  _isGuideOn ? 'on' : 'off',
                                  style: TextStyle(
                                    fontFamily: 'Tmoney RoundWind',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 오른쪽 카메라 회전 버튼
            Positioned(
              right: 17,
              top: 15,
              child: GestureDetector(
                onTap: _switchCamera,
                child: Image.asset(
                  'assets/images/button_cturn.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 카메라 전환
  void _switchCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용 가능한 카메라가 하나만 있습니다')),
        );
        return;
      }

      final currentCameraIndex = cameras.indexOf(_cameraController!.description);
      final newCameraIndex = (currentCameraIndex + 1) % cameras.length;

      await _cameraController?.dispose();
      _cameraController = CameraController(
        cameras[newCameraIndex],
        ResolutionPreset.high,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Camera switch error: $e');
    }
  }

  // 씬/테이크 정보
  Widget _buildSceneTakeInfo(double screenWidth, double screenHeight) {
    final sceneNum = widget.sceneInfo?['sceneIndex'] ?? widget.sceneNumber;
    final totalScenes = widget.sceneInfo?['totalScenes'] ?? 0;
    final sceneTitle = widget.sceneInfo?['title'] ?? '';

    // 체크리스트 높이 계산
    final checklist = widget.sceneInfo?['checklist'] as List<dynamic>? ?? widget.shootingGuides;
    final itemCount = checklist.length;
    final checklistHeight = (itemCount * 52) + 20 + 10; // 항목 높이 * 개수 + padding (조정된 크기)

    // 체크리스트 bottom(140) + 체크리스트 높이 + 여백(30)
    final sceneInfoBottom = 160.0 + checklistHeight + 30;

    return Positioned(
      left: 15,
      bottom: sceneInfoBottom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            totalScenes > 0 
                ? '씬 #$sceneNum / $totalScenes | 테이크 #$_currentTakeNumber'
                : '씬 #${widget.sceneNumber} / 테이크 #$_currentTakeNumber',
            style: TextStyle(
              fontFamily: 'Tmoney RoundWind',
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: AppColors.white,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.5),
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          if (sceneTitle.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              sceneTitle,
              style: TextStyle(
                fontFamily: 'Tmoney RoundWind',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.white,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.5),
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 촬영 가이드 체크리스트
  Widget _buildShootingGuideChecklist(double screenWidth, double screenHeight) {
    final checklist = widget.sceneInfo?['checklist'] as List<dynamic>? ?? widget.shootingGuides;
    final checklistStrings = checklist.map((item) => item.toString()).toList();

    return Positioned(
      left: 15,
      bottom: 160,
      child: Container(
        width: screenWidth - 30,
        constraints: BoxConstraints(maxWidth: 371),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.75),
          border: Border(
            left: BorderSide(color: AppColors.black, width: 2),
            bottom: BorderSide(color: AppColors.black, width: 3.5),
            right: BorderSide(color: AppColors.black, width: 3.5),
            top: BorderSide(color: AppColors.black, width: 2),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(checklistStrings.length, (index) {
              final isCompleted = _checkedChecklistIndices.contains(index);
              final sceneId = widget.sceneInfo?['id']?.toString() ?? 'scene_${widget.sceneNumber}';
              final imageStatus = _imageGenerationStatus[index] ?? ImageGenerationStatus.none;

              return Padding(
                padding: EdgeInsets.only(bottom: 1),
                child: Row(
                  children: [
                    // 체크박스 터치 영역 확대 (52x52)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_checkedChecklistIndices.contains(index)) {
                            _checkedChecklistIndices.remove(index);
                          } else {
                            _checkedChecklistIndices.add(index);
                          }
                          _saveChecklistStatus();
                        });
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.primary.withOpacity(0.2)
                                : AppColors.white,
                            border: Border.all(
                              color: isCompleted
                                  ? AppColors.primary
                                  : AppColors.black,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: isCompleted
                              ? CustomPaint(
                                  painter: _CheckMarkPainter(),
                                )
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // 텍스트 영역 - 탭 시 이미지 생성
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onChecklistItemTap(index, checklistStrings[index]),
                        child: Text(
                          checklistStrings[index],
                          style: TextStyle(
                            fontFamily: 'Tmoney RoundWind',
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: isCompleted
                                ? const Color(0xFFB2B2B2)
                                : const Color(0xFF1A1A1A),
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ),
                    // 이미지 생성 상태 표시 (오른쪽) - 탭 시 구도 이미지 표시
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _onChecklistItemTap(index, checklistStrings[index]),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: imageStatus == ImageGenerationStatus.generating
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              )
                            : (imageStatus == ImageGenerationStatus.completed
                                ? Icon(Icons.check_circle, size: 20, color: AppColors.primary)
                                : SizedBox.shrink()),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // 하단 컨트롤 영역
  Widget _buildBottomControls(double screenWidth, double screenHeight, double bottomPadding) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFCEDCD3),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: 24, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 좌측 - 이전 테이크 오버레이 토글
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: _buildPreviousTakeButton(),
              ),

              // 중앙 - 촬영 버튼
              _buildRecordButton(),

              // 우측 - 화면 캡처 버튼
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: _buildScreenshotButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 좌측 하단 - 이전 테이크 버튼
  Widget _buildPreviousTakeButton() {
    final hasPreviousTakes = _previousTakes.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (!hasPreviousTakes) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이전 Take가 없습니다')),
          );
          return;
        }

        setState(() {
          _showPreviousTake = !_showPreviousTake;
        });

        if (_showPreviousTake && _videoPlayerController != null) {
          _videoPlayerController?.play();
        } else {
          _videoPlayerController?.pause();
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
          border: Border.all(
            color: _showPreviousTake ? AppColors.primary : (hasPreviousTakes ? AppColors.black : AppColors.gray),
            width: _showPreviousTake ? 3 : 2,
          ),
        ),
        child: ClipOval(
          child: Stack(
            children: [
              // 썸네일 (비디오 플레이어로 표시)
              if (hasPreviousTakes && _videoPlayerController != null && _videoPlayerController!.value.isInitialized)
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoPlayerController!.value.size.width,
                      height: _videoPlayerController!.value.size.height,
                      child: VideoPlayer(_videoPlayerController!),
                    ),
                  ),
                )
              else
                Container(
                  color: AppColors.gray.withOpacity(0.3),
                  child: Center(
                    child: Icon(
                      Icons.history,
                      color: AppColors.gray,
                      size: 24,
                    ),
                  ),
                ),

              // 반투명 오버레이 (선택되지 않았을 때)
              if (!_showPreviousTake)
                Container(
                  color: AppColors.black.withOpacity(0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 중앙 - 촬영 버튼
  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _toggleRecording,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFF7375),
        ),
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
              color: AppColors.white,
              borderRadius: _isRecording ? BorderRadius.circular(4) : null,
            ),
          ),
        ),
      ),
    );
  }

  // 우측 하단 - 사진 촬영 버튼
  Widget _buildScreenshotButton() {
    return GestureDetector(
      onTap: _takePicture,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
          border: Border.all(
            color: AppColors.black,
            width: 2,
          ),
        ),
      ),
    );
  }

  // 사진 촬영 기능
  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카메라가 준비되지 않았습니다')),
      );
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      
      // 저장 경로 생성
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'photo_${_currentSceneNumber}_${_currentTakeNumber}_$timestamp.jpg';
      final filePath = '${directory.path}/$fileName';
      
      // 이미지 파일 저장
      await photo.saveTo(filePath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사진 저장 완료: $fileName'),
            duration: Duration(seconds: 2),
          ),
        );
        print('[CAMERA] 사진 저장: $filePath');
      }
    } catch (e) {
      print('[CAMERA] 사진 촬영 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 촬영 중 오류 발생: $e')),
        );
      }
    }
  }

  // 체크리스트 항목 탭 핸들러
  void _onChecklistItemTap(int index, String checklistItem) {
    final sceneId = widget.sceneInfo?['id']?.toString() ?? 'scene_${widget.sceneNumber}';
    final hasImage = _dataService.hasCompositionImage(sceneId, index);

    if (hasImage) {
      // 이미지가 있으면 표시
      setState(() {
        _selectedChecklistIndex = index;
        _showCompositionImage = true;
        _showReference = false; // YouTube 레퍼런스 끄기
      });
    } else {
      // 이미지가 없으면 생성 확인 다이얼로그 표시
      _showCompositionDialog(index, checklistItem);
    }
  }

  // 구도 이미지 생성 확인 다이얼로그
  Future<void> _showCompositionDialog(int index, String checklistItem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: AppColors.black, width: 3),
        ),
        title: Text(
          '구도 예시 이미지',
          style: TextStyle(
            fontFamily: 'Tmoney RoundWind',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.black,
          ),
        ),
        content: Text(
          '이 촬영 구도의 예시 이미지를 생성할까요?\n\n"$checklistItem"',
          style: TextStyle(
            fontFamily: 'Tmoney RoundWind',
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: AppColors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: TextStyle(
                fontFamily: 'Tmoney RoundWind',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.gray,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '생성',
              style: TextStyle(
                fontFamily: 'Tmoney RoundWind',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // 확인을 누르면 백그라운드로 이미지 생성
      _generateCompositionImage(index, checklistItem);
    }
  }

  // 구도 이미지 생성 (백그라운드)
  Future<void> _generateCompositionImage(int index, String checklistItem) async {
    // 이미지 생성 상태를 'generating'으로 설정
    setState(() {
      _imageGenerationStatus[index] = ImageGenerationStatus.generating;
    });

    // 로딩 알림 표시
    if (mounted) {
      AppNotification.show(
        context,
        '구도 이미지를 생성하고 있습니다...',
        type: NotificationType.info,
        showActions: false, // 로딩 중이므로 버튼 숨김
      );
    }

    try {
      final sceneId = widget.sceneInfo?['id']?.toString() ?? 'scene_${widget.sceneNumber}';
      final sceneTitle = widget.sceneInfo?['title']?.toString() ?? '씬 ${widget.sceneNumber}';
      final location = widget.sceneInfo?['location']?.toString() ?? '';
      final vlogTitle = _dataService.plan?.vlogTitle;
      final sceneDescription = widget.sceneInfo?['description']?.toString();

      // DALL-E로 이미지 생성
      final imageUrl = await DalleImageService.generateCompositionImage(
        sceneTitle: sceneTitle,
        checklistItem: checklistItem,
        location: location,
        vlogTitle: vlogTitle,
        sceneDescription: sceneDescription,
      );

      if (imageUrl != null && mounted) {
        // 이미지 저장
        _dataService.setCompositionImage(sceneId, index, imageUrl);

        // 성공 알림
        AppNotification.dismiss(); // 로딩 알림 제거
        AppNotification.show(
          context,
          '구도 이미지가 생성되었습니다!',
          type: NotificationType.success,
        );

        // UI 업데이트
        setState(() {
          _imageGenerationStatus[index] = ImageGenerationStatus.completed;
          _selectedChecklistIndex = index;
          _showCompositionImage = true;
          _showReference = false;
        });
      } else if (mounted) {
        // 실패 시 상태를 'none'으로 되돌림
        setState(() {
          _imageGenerationStatus[index] = ImageGenerationStatus.none;
        });

        // 실패 알림
        AppNotification.dismiss();
        AppNotification.show(
          context,
          '이미지 생성에 실패했습니다',
          type: NotificationType.error,
        );
      }
    } catch (e) {
      print('[CAMERA] 구도 이미지 생성 오류: $e');
      if (mounted) {
        // 오류 시 상태를 'none'으로 되돌림
        setState(() {
          _imageGenerationStatus[index] = ImageGenerationStatus.none;
        });

        AppNotification.dismiss();
        AppNotification.show(
          context,
          '이미지 생성 중 오류가 발생했습니다',
          type: NotificationType.error,
        );
      }
    }
  }
}

// 체크마크 그리기
class _CheckMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.2, size.width * 0.5)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..lineTo(size.width * 0.8, size.height * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

