import 'package:geolocator/geolocator.dart';
import '../models/plan.dart';

/// GPS 위치 추적 및 지오펜싱 서비스
class LocationService {
  /// 위치 권한 요청
  static Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스 활성화 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('[LOCATION_SERVICE] 위치 서비스가 비활성화되어 있습니다');
      return false;
    }

    // 위치 권한 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('[LOCATION_SERVICE] 위치 권한이 거부되었습니다');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('[LOCATION_SERVICE] 위치 권한이 영구적으로 거부되었습니다');
      return false;
    }

    print('[LOCATION_SERVICE] 위치 권한이 승인되었습니다');
    return true;
  }

  /// 현재 위치 가져오기
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('[LOCATION_SERVICE] 현재 위치: (${position.latitude}, ${position.longitude})');
      return position;
    } catch (e) {
      print('[LOCATION_SERVICE] 위치 가져오기 오류: $e');
      return null;
    }
  }

  /// 두 지점 간 거리 계산 (미터 단위)
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// 촬영 장소에 진입했는지 확인 (지오펜싱)
  /// [currentPosition] 현재 위치
  /// [targetLocation] 목표 촬영 장소
  /// [radiusMeters] 진입 인정 반경 (기본 50m)
  static bool isWithinGeofence({
    required Position currentPosition,
    required LocationPoint targetLocation,
    double radiusMeters = 50.0,
  }) {
    final distance = calculateDistance(
      lat1: currentPosition.latitude,
      lon1: currentPosition.longitude,
      lat2: targetLocation.latitude,
      lon2: targetLocation.longitude,
    );

    final isWithin = distance <= radiusMeters;
    print('[LOCATION_SERVICE] 목표 장소까지 거리: ${distance.toStringAsFixed(1)}m (${isWithin ? "진입" : "미진입"})');
    return isWithin;
  }

  /// 실시간 위치 변화 감지 (스트림)
  static Stream<Position> getPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // 10m 이상 이동 시 업데이트
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// 촬영 장소 근처인지 체크 및 알림 필요 여부 반환
  static Future<GeofenceStatus> checkGeofenceStatus({
    required LocationPoint targetLocation,
    double radiusMeters = 50.0,
  }) async {
    final currentPosition = await getCurrentLocation();
    if (currentPosition == null) {
      return GeofenceStatus(
        isWithinRange: false,
        distanceMeters: null,
        message: '현재 위치를 가져올 수 없습니다',
      );
    }

    final distance = calculateDistance(
      lat1: currentPosition.latitude,
      lon1: currentPosition.longitude,
      lat2: targetLocation.latitude,
      lon2: targetLocation.longitude,
    );

    final isWithin = distance <= radiusMeters;

    String message;
    if (isWithin) {
      message = '촬영 장소에 도착했습니다! (${distance.toStringAsFixed(0)}m)';
    } else if (distance <= 200) {
      message = '촬영 장소가 가까워지고 있습니다 (${distance.toStringAsFixed(0)}m)';
    } else {
      message = '촬영 장소까지 ${distance.toStringAsFixed(0)}m 남았습니다';
    }

    return GeofenceStatus(
      isWithinRange: isWithin,
      distanceMeters: distance,
      message: message,
    );
  }
}

/// 지오펜스 상태
class GeofenceStatus {
  final bool isWithinRange;
  final double? distanceMeters;
  final String message;

  GeofenceStatus({
    required this.isWithinRange,
    required this.distanceMeters,
    required this.message,
  });
}
