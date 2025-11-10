import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

/// 흔들림 감지 서비스
class ShakeDetectionService {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  final StreamController<ShakeEvent> _shakeController =
      StreamController<ShakeEvent>.broadcast();

  // 흔들림 임계값 설정
  static const double _accelerometerThreshold = 15.0; // 가속도계 임계값
  static const double _gyroscopeThreshold = 3.0; // 자이로스코프 임계값
  static const int _shakeDebounceMs = 500; // 흔들림 감지 최소 간격 (ms)

  DateTime? _lastShakeTime;
  bool _isMonitoring = false;

  /// 흔들림 감지 시작
  void startMonitoring({
    double accelerometerThreshold = _accelerometerThreshold,
    double gyroscopeThreshold = _gyroscopeThreshold,
  }) {
    if (_isMonitoring) {
      print('[SHAKE_DETECTION] 이미 모니터링 중입니다');
      return;
    }

    _isMonitoring = true;
    print('[SHAKE_DETECTION] 흔들림 감지 시작');

    // 가속도계 모니터링
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // 중력 제외 (9.8)
      final netMagnitude = magnitude - 9.8;

      if (netMagnitude.abs() > accelerometerThreshold) {
        _onShakeDetected(
          ShakeEvent(
            type: ShakeType.accelerometer,
            magnitude: netMagnitude,
            timestamp: DateTime.now(),
            severity: _calculateSeverity(netMagnitude, accelerometerThreshold),
          ),
        );
      }
    });

    // 자이로스코프 모니터링 (회전 감지)
    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      final rotationMagnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (rotationMagnitude > gyroscopeThreshold) {
        _onShakeDetected(
          ShakeEvent(
            type: ShakeType.gyroscope,
            magnitude: rotationMagnitude,
            timestamp: DateTime.now(),
            severity: _calculateSeverity(rotationMagnitude, gyroscopeThreshold),
          ),
        );
      }
    });
  }

  /// 흔들림 감지 중지
  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _isMonitoring = false;
    print('[SHAKE_DETECTION] 흔들림 감지 중지');
  }

  /// 흔들림 이벤트 처리 (디바운싱 적용)
  void _onShakeDetected(ShakeEvent event) {
    final now = DateTime.now();

    // 디바운싱: 최근 흔들림 감지 후 일정 시간 동안 무시
    if (_lastShakeTime != null &&
        now.difference(_lastShakeTime!).inMilliseconds < _shakeDebounceMs) {
      return;
    }

    _lastShakeTime = now;
    _shakeController.add(event);

    print('[SHAKE_DETECTION] 흔들림 감지! 타입: ${event.type}, 강도: ${event.magnitude.toStringAsFixed(2)}, 심각도: ${event.severity}');
  }

  /// 심각도 계산
  ShakeSeverity _calculateSeverity(double magnitude, double threshold) {
    final ratio = magnitude / threshold;

    if (ratio > 2.5) {
      return ShakeSeverity.severe;
    } else if (ratio > 1.5) {
      return ShakeSeverity.moderate;
    } else {
      return ShakeSeverity.mild;
    }
  }

  /// 흔들림 이벤트 스트림
  Stream<ShakeEvent> get shakeStream => _shakeController.stream;

  /// 리소스 해제
  void dispose() {
    stopMonitoring();
    _shakeController.close();
  }
}

/// 흔들림 이벤트
class ShakeEvent {
  final ShakeType type;
  final double magnitude;
  final DateTime timestamp;
  final ShakeSeverity severity;

  ShakeEvent({
    required this.type,
    required this.magnitude,
    required this.timestamp,
    required this.severity,
  });

  String get message {
    switch (severity) {
      case ShakeSeverity.mild:
        return '약간의 흔들림이 감지되었습니다';
      case ShakeSeverity.moderate:
        return '중간 정도의 흔들림이 감지되었습니다';
      case ShakeSeverity.severe:
        return '심한 흔들림이 감지되었습니다! 삼각대 사용을 권장합니다';
    }
  }

  String get emoji {
    switch (severity) {
      case ShakeSeverity.mild:
        return '⚠️';
      case ShakeSeverity.moderate:
        return '⚠️⚠️';
      case ShakeSeverity.severe:
        return '🚨';
    }
  }
}

/// 흔들림 타입
enum ShakeType {
  accelerometer, // 가속도계 (진동/흔들림)
  gyroscope, // 자이로스코프 (회전)
}

/// 흔들림 심각도
enum ShakeSeverity {
  mild, // 약함
  moderate, // 중간
  severe, // 심함
}
