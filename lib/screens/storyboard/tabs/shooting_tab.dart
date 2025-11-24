import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/vlog_data_service.dart';
import '../../../ui/styles.dart';
import '../../scene/scene_list_page.dart';

class ShootingTab extends StatefulWidget {
  final VlogDataService dataService;

  const ShootingTab({
    super.key,
    required this.dataService,
  });

  @override
  State<ShootingTab> createState() => _ShootingTabState();
}

class _ShootingTabState extends State<ShootingTab> {
  int _selectedSceneIndex = 0;
  late PageController _scenePageController;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _scenePageController = PageController(
      viewportFraction: 0.85, // 양옆 카드가 살짝 보이도록
    );
  }

  @override
  void dispose() {
    _scenePageController.dispose();
    super.dispose();
  }

  void _onSceneChanged(int index) {
    setState(() {
      _selectedSceneIndex = index;
    });
    
    // PageView로 이동
    _scenePageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    // 지도 마커로 이동
    _updateMapCamera(index);
  }

  void _updateMapCamera(int sceneIndex) {
    final locations = widget.dataService.getShootingLocations();
    final cueCards = widget.dataService.cueCards;
    
    if (_mapController == null || locations.isEmpty || cueCards == null || sceneIndex >= cueCards.length) {
      return;
    }
    
    // 해당 씬의 location 이름 찾기
    final sceneLocation = cueCards[sceneIndex].location;
    if (sceneLocation.isEmpty) {
      return;
    }
    
    // locations에서 해당 씬의 location 이름과 일치하는 마커 찾기
    LocationPoint? targetLocation;
    for (final loc in locations) {
      if (loc.name == sceneLocation || loc.sceneIds.contains('scene_${sceneIndex + 1}')) {
        targetLocation = loc;
        break;
      }
    }
    
    if (targetLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(targetLocation.latitude, targetLocation.longitude),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.dataService.plan;
    final cueCards = widget.dataService.cueCards;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (plan == null || cueCards == null) {
      return Center(child: Text('데이터를 불러올 수 없습니다'));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: screenWidth * 0.928, // 373/402
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.036),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 촬영 동선 소제목
            Padding(
              padding: EdgeInsets.only(left: screenWidth * (12 / 402)),
              child: Text(
                '촬영 동선',
                style: const TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  height: 1.29,
                  letterSpacing: -0.72,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            SizedBox(height: AppDims.marginSubtitleToContent(screenHeight)),

            // Google Maps
            RepaintBoundary(
              child: _buildGoogleMap(plan, screenWidth),
            ),

            SizedBox(height: screenHeight * (25 / 904)), // 피그마 기준 55

            // 씬 선택 인디케이터
            _buildSceneIndicator(cueCards.length),

            SizedBox(height: screenHeight * (25 / 904)), // 피그마 기준 55

            // 씬 정보 카드 (가로 스크롤 - PageView)
            SizedBox(
              height: screenHeight * (156.61 / 904), // 피그마 기준 156.61
              child: PageView.builder(
                controller: _scenePageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _selectedSceneIndex = index;
                  });
                  _updateMapCamera(index);
                },
                itemCount: cueCards.length,
                itemBuilder: (context, index) {
                  return RepaintBoundary(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                      child: GestureDetector(
                        onTap: () => _navigateToSceneList(context, index),
                        child: _buildSceneCard(cueCards[index], index, screenWidth, screenHeight),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            SizedBox(height: screenHeight * 0.03),
          ],
        ),
      ),
    );
  }

  // Google Maps 위젯
  Widget _buildGoogleMap(dynamic plan, double screenWidth) {
    final locations = widget.dataService.getShootingLocations();
    
    // 피그마 기준 373 * 272
    final mapWidth = screenWidth * (373 / 402);
    final mapHeight = mapWidth * (272 / 373);

    if (locations.isEmpty) {
      return Container(
        height: mapHeight,
        width: mapWidth,
        decoration: BoxDecoration(
          color: Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
            bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
            right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
            top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 48, color: Color(0xFFB2B2B2)),
              SizedBox(height: 8),
              Text(
                '촬영 장소 정보 없음',
                style: TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontSize: 14,
                  color: Color(0xFFB2B2B2),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 마커 생성
    final markers = locations.asMap().entries.map((entry) {
      int index = entry.key;
      final location = entry.value;

      return Marker(
        markerId: MarkerId('marker_${location.order}'),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: location.name,
          snippet: location.description,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          index == 0
              ? BitmapDescriptor.hueGreen
              : index == locations.length - 1
                  ? BitmapDescriptor.hueBlue
                  : BitmapDescriptor.hueRed,
        ),
      );
    }).toSet();

    // 폴리라인 생성
    final polylineCoordinates = locations
        .map((location) => LatLng(location.latitude, location.longitude))
        .toList();

    final polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: polylineCoordinates,
        color: Color(0xFF1A1A1A),
        width: 4,
      ),
    };

    // 카메라 위치
    final cameraPosition = LatLng(
      locations.first.latitude,
      locations.first.longitude,
    );

    return Container(
      height: mapHeight,
      width: mapWidth,
      decoration: BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
          bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
          right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
          top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4), // 테두리 안쪽 여백 (오른쪽 2px 늘림)
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6), // 내부 둥근 모서리
          child: GoogleMap(
        onMapCreated: (controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: cameraPosition,
          zoom: 15,
        ),
        markers: markers,
        polylines: polylines,
        mapType: MapType.normal,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: true,
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(
            () => EagerGestureRecognizer(),
          ),
        },
          ),
        ),
      ),
    );
  }

  // 씬 인디케이터
  Widget _buildSceneIndicator(int sceneCount) {
    if (sceneCount == 0) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    // 피그마 기준: 작은 원 17, 큰 원 34, 선 두께 5
    final smallCircle = screenWidth * (17 / 402);
    final largeCircle = screenWidth * (34 / 402);
    final lineThickness = screenWidth * (5 / 402);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 가로 라인
          Positioned(
            left: 16,
            right: 16,
            child: Container(
              height: lineThickness,
              color: Color(0xFF1A1A1A),
            ),
          ),
          // 동그라미들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(sceneCount, (index) {
              final isSelected = index == _selectedSceneIndex;
              return GestureDetector(
                onTap: () => _onSceneChanged(index),
                child: Container(
                  width: isSelected ? largeCircle : smallCircle,
                  height: isSelected ? largeCircle : smallCircle,
                  decoration: BoxDecoration(
                    color: Color(0xFFFAFAFA),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Color(0xFF2C3E50) : Color(0xFF1A1A1A),
                      width: isSelected ? 4 : 2,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // 선택된 씬의 위치 정보
  Widget _buildSelectedSceneLocation(dynamic cueCard) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: Color(0xFF1A1A1A), width: 2),
          bottom: BorderSide(color: Color(0xFF1A1A1A), width: 3),
          right: BorderSide(color: Color(0xFF1A1A1A), width: 3),
          top: BorderSide(color: Color(0xFF1A1A1A), width: 2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Color(0xFF455D75),
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFF1A1A1A), width: 2),
            ),
            child: Center(
              child: Text(
                '${_selectedSceneIndex + 1}',
                style: TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Color(0xFFFAFAFA),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cueCard.title,
                  style: TextStyle(
                    fontFamily: 'Tmoney RoundWind',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (cueCard.summary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      cueCard.summary.first,
                      style: TextStyle(
                        fontFamily: 'Tmoney RoundWind',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 씬 카드 (가로 스크롤용) - 씬 리스트 스타일로 변경
  Widget _buildSceneCard(dynamic cueCard, int index, double screenWidth, double screenHeight) {
    // 씬 리스트와 동일한 썸네일 크기
    final thumbnailWidth = screenWidth * 0.4;
    final thumbnailHeight = screenHeight * 0.122;
    
    // 카드 크기 조정
    final cardWidth = screenWidth * (317 / 402);
    final cardHeight = screenHeight * 0.18; // 씬 리스트와 비슷한 높이
    
    return Container(
      width: cardWidth,
      height: cardHeight,
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
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          screenWidth * 0.032,
          screenWidth * 0.05,
          screenWidth * 0.032,
          screenWidth * 0.005,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일
            GestureDetector(
              onTap: cueCard.storyboardImageUrl != null && cueCard.storyboardImageUrl!.isNotEmpty
                  ? () => _showImageModal(context, cueCard.storyboardImageUrl!, screenWidth, screenHeight)
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
                  child: cueCard.storyboardImageUrl != null && cueCard.storyboardImageUrl!.isNotEmpty
                      ? Image.network(
                          cueCard.storyboardImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: const Color(0xFFB2B2B2));
                          },
                        )
                      : Container(color: const Color(0xFFB2B2B2)),
                ),
              ),
            ),

            SizedBox(width: screenWidth * 0.048),

            // 제목과 시간
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 제목
                  SizedBox(height: screenHeight * 0.01),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontFamily: 'Tmoney RoundWind',
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                          height: 1.3,
                        ),
                      ),
                      Text(
                        cueCard.title,
                        style: TextStyle(
                          fontFamily: 'Tmoney RoundWind',
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                          height: 1.3,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                  // 시간 표시
                  Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.015),
                    child: Text(
                      '${cueCard.allocatedSec ~/ 60}분',
                      style: TextStyle(
                        fontFamily: 'Tmoney RoundWind',
                        fontSize: screenWidth * 0.038,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFB2B2B2),
                        height: 1.29,
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 이미지 모달 표시
  void _showImageModal(BuildContext context, String imageUrl, double screenWidth, double screenHeight) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      barrierDismissible: true, // shadow 클릭 시 닫기
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final maxDimension = constraints.biggest.shortestSide * 0.9;
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(), // shadow 클릭 시 닫기
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // 이미지 클릭 시는 닫지 않음
                  child: Container(
                    width: maxDimension,
                    height: maxDimension,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF1A1A1A),
                        width: 6,
                      ),
                    ),
                    padding: EdgeInsets.all(maxDimension * 0.015),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
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
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 씬 리스트 페이지로 이동 (해당 씬 드롭다운 상태로)
  void _navigateToSceneList(BuildContext context, int sceneIndex) {
    // 키보드 닫기
    FocusScope.of(context).unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SceneListPage(initialExpandedIndex: sceneIndex),
      ),
    );
  }
}
