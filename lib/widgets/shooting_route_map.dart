import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../services/vlog_data_service.dart';

class ShootingRouteMap extends StatefulWidget {
  const ShootingRouteMap({super.key});

  @override
  State<ShootingRouteMap> createState() => _ShootingRouteMapState();
}

class _ShootingRouteMapState extends State<ShootingRouteMap> {
  GoogleMapController? _mapController;
  bool _isMapLoading = true;
  final VlogDataService _dataService = VlogDataService();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _createMarkers();
    _createPolylines();
  }

  void _createMarkers() {
    final locations = _dataService.getShootingLocations();
    
    if (locations.isEmpty) return;
    
    _markers = locations.asMap().entries.map((entry) {
      int index = entry.key;
      final location = entry.value;
      
      return Marker(
        markerId: MarkerId('marker_${location.order}'),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: '${location.order}. ${location.name}',
          snippet: location.description,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          index == 0 
              ? BitmapDescriptor.hueGreen  // 시작점은 초록색
              : index == locations.length - 1
                  ? BitmapDescriptor.hueBlue  // 끝점은 파란색
                  : BitmapDescriptor.hueRed,  // 중간은 빨간색
        ),
      );
    }).toSet();
  }

  void _createPolylines() {
    final locations = _dataService.getShootingLocations();
    
    if (locations.isEmpty) return;
    
    final polylineCoordinates = locations
        .map((location) => LatLng(location.latitude, location.longitude))
        .toList();

    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: polylineCoordinates,
        color: AppColors.primary,
        width: 4,
      ),
    };
  }

  LatLng _getCameraPosition() {
    final locations = _dataService.getShootingLocations();
    if (locations.isEmpty) {
      return const LatLng(36.8109, 127.1498); // 기본값 (오월드)
    }
    // 첫 번째 위치를 중심으로
    return LatLng(locations.first.latitude, locations.first.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final locations = _dataService.getShootingLocations();
    final routeDescription = _dataService.getRouteDescription();
    
    return Column(
      children: [
        // 구글 지도
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: AppColors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _getCameraPosition(),
                  zoom: 16,
                ),
                markers: _markers,
                polylines: _polylines,
                mapType: MapType.normal,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                // 제스처 인식기 설정 - 지도가 터치를 우선적으로 처리
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                onMapCreated: (controller) {
                  _mapController = controller;
                  setState(() {
                    _isMapLoading = false;
                  });
                  debugPrint('✅ Google Maps created successfully');
                },
              ),
              // 로딩 인디케이터
              if (_isMapLoading)
                Container(
                  color: AppColors.cardBackground,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // 동선 요약
        if (routeDescription.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.route, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '촬영 동선',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  routeDescription,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_dataService.getEstimatedWalkingMinutes() > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: AppColors.textSecondary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '예상 이동 시간: ${_dataService.getEstimatedWalkingMinutes()}분',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        // 동선 설명
        if (locations.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: locations.asMap().entries.map((entry) {
              final index = entry.key;
              final location = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < locations.length - 1 ? 16.0 : 0),
                child: _buildRouteItem(
                  '${location.order}. ${location.name}',
                  location.description,
                ),
              );
            }).toList(),
          )
        else
          Text(
            '촬영 동선 정보가 없습니다.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildRouteItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                title.substring(0, 1), // "1", "2", etc.
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title.substring(3), // "카페 입구", etc.
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
