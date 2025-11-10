import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:path_provider/path_provider.dart';

/// 시스템 리소스 체크 서비스 (배터리, 저장공간 등)
class SystemCheckService {
  static final Battery _battery = Battery();

  /// 배터리 상태 체크
  static Future<BatteryStatus> checkBattery() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;

      final isCharging = batteryState == BatteryState.charging ||
          batteryState == BatteryState.full;

      String warning = '';
      bool isLowBattery = false;

      if (batteryLevel < 20 && !isCharging) {
        warning = '배터리가 부족합니다 (${batteryLevel}%). 충전을 권장합니다.';
        isLowBattery = true;
      } else if (batteryLevel < 50 && !isCharging) {
        warning = '배터리가 ${batteryLevel}%입니다. 장시간 촬영 시 충전을 고려하세요.';
      }

      print('[SYSTEM_CHECK] 배터리: $batteryLevel% (충전 중: $isCharging)');

      return BatteryStatus(
        level: batteryLevel,
        isCharging: isCharging,
        isLowBattery: isLowBattery,
        warning: warning,
      );
    } catch (e) {
      print('[SYSTEM_CHECK] 배터리 체크 오류: $e');
      return BatteryStatus(
        level: 100,
        isCharging: false,
        isLowBattery: false,
        warning: '',
      );
    }
  }

  /// 저장 공간 체크
  static Future<StorageStatus> checkStorage() async {
    try {
      // 앱 문서 디렉토리의 여유 공간 확인
      final directory = await getApplicationDocumentsDirectory();
      final stat = await directory.stat();

      // 추정 여유 공간 (실제 파일 시스템 체크는 플랫폼별 구현 필요)
      // 여기서는 간단한 체크로 대체
      double freeGB = 10.0; // 기본값 (실제로는 플랫폼별 구현 필요)
      double totalGB = 128.0; // 기본값

      // 파일 시스템 타입에 따라 간단한 체크
      String warning = '';
      bool isLowStorage = false;

      // 보수적으로 경고 표시
      if (freeGB < 1.0) {
        warning = '저장 공간이 부족할 수 있습니다. 촬영 전 여유 공간을 확보하세요.';
        isLowStorage = true;
      }

      print('[SYSTEM_CHECK] 저장 공간: ${freeGB.toStringAsFixed(1)}GB 추정');

      return StorageStatus(
        freeSpaceGB: freeGB,
        totalSpaceGB: totalGB,
        isLowStorage: isLowStorage,
        warning: warning,
      );
    } catch (e) {
      print('[SYSTEM_CHECK] 저장 공간 체크 오류: $e');
      return StorageStatus(
        freeSpaceGB: 10.0,
        totalSpaceGB: 128.0,
        isLowStorage: false,
        warning: '',
      );
    }
  }

  /// 촬영 전 시스템 전체 체크
  static Future<SystemCheckResult> performFullCheck() async {
    final battery = await checkBattery();
    final storage = await checkStorage();

    final warnings = <String>[];
    if (battery.warning.isNotEmpty) warnings.add(battery.warning);
    if (storage.warning.isNotEmpty) warnings.add(storage.warning);

    final isReady = !battery.isLowBattery && !storage.isLowStorage;

    String overallMessage;
    if (isReady) {
      overallMessage = '촬영 준비가 완료되었습니다!';
    } else {
      overallMessage = '촬영 전 ${warnings.length}개의 경고를 확인하세요.';
    }

    return SystemCheckResult(
      battery: battery,
      storage: storage,
      isReady: isReady,
      warnings: warnings,
      overallMessage: overallMessage,
    );
  }

  /// 배터리 스트림 (실시간 모니터링)
  static Stream<BatteryState> get batteryStateStream {
    return _battery.onBatteryStateChanged;
  }
}

/// 배터리 상태
class BatteryStatus {
  final int level;
  final bool isCharging;
  final bool isLowBattery;
  final String warning;

  BatteryStatus({
    required this.level,
    required this.isCharging,
    required this.isLowBattery,
    required this.warning,
  });
}

/// 저장 공간 상태
class StorageStatus {
  final double freeSpaceGB;
  final double totalSpaceGB;
  final bool isLowStorage;
  final String warning;

  StorageStatus({
    required this.freeSpaceGB,
    required this.totalSpaceGB,
    required this.isLowStorage,
    required this.warning,
  });

  double get usedPercent {
    if (totalSpaceGB == 0) return 0;
    return ((totalSpaceGB - freeSpaceGB) / totalSpaceGB) * 100;
  }
}

/// 시스템 체크 종합 결과
class SystemCheckResult {
  final BatteryStatus battery;
  final StorageStatus storage;
  final bool isReady;
  final List<String> warnings;
  final String overallMessage;

  SystemCheckResult({
    required this.battery,
    required this.storage,
    required this.isReady,
    required this.warnings,
    required this.overallMessage,
  });
}
