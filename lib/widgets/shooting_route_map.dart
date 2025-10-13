import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

class ShootingRouteMap extends StatefulWidget {
  const ShootingRouteMap({super.key});

  @override
  State<ShootingRouteMap> createState() => _ShootingRouteMapState();
}

class _ShootingRouteMapState extends State<ShootingRouteMap> {
  GoogleMapController? _mapController;
  bool _isMapLoading = true;

  // 촬영 장소 예시 (카페 근처 위치 - 서울 시청 근처)
  final List<Map<String, dynamic>> _locations = [
    {
      'title': '1. 카페 입구',
      'position': const LatLng(37.5665, 126.9780),
    },
    {
      'title': '2. 테이블 자리',
      'position': const LatLng(37.5667, 126.9782),
    },
    {
      'title': '3. 주문 카운터',
      'position': const LatLng(37.5668, 126.9783),
    },
    {
      'title': '4. 창가 좌석',
      'position': const LatLng(37.5669, 126.9785),
    },
  ];

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _createMarkers();
    _createPolylines();
  }

  void _createMarkers() {
    _markers = _locations.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> location = entry.value;
      
      return Marker(
        markerId: MarkerId('marker_$index'),
        position: location['position'],
        infoWindow: InfoWindow(
          title: location['title'],
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          index == 0 ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueRed,
        ),
      );
    }).toSet();
  }

  void _createPolylines() {
    final polylineCoordinates = _locations
        .map((location) => location['position'] as LatLng)
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

  @override
  Widget build(BuildContext context) {
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
                  target: const LatLng(37.5666, 126.9782),
                  zoom: 17,
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
        
        // 동선 설명
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRouteItem(
              '1. 카페 입구',
              '친구들과 만나는 첫 장면을 촬영합니다. 밝은 표정으로 인사하는 모습을 담습니다.',
            ),
            const SizedBox(height: 16),
            _buildRouteItem(
              '2. 테이블 자리',
              '자리에 앉아 메뉴를 고르는 장면입니다. 메뉴판을 보며 대화하는 모습을 촬영합니다.',
            ),
            const SizedBox(height: 16),
            _buildRouteItem(
              '3. 주문 카운터',
              '음료를 주문하는 장면입니다. 카운터에서 주문하고 결제하는 과정을 담습니다.',
            ),
            const SizedBox(height: 16),
            _buildRouteItem(
              '4. 창가 좌석',
              '음료가 나온 후 본격적인 토크 타임입니다. 창밖 풍경과 함께 대화하는 모습을 촬영합니다.',
            ),
          ],
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
