import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/vlog_data_service.dart';
import '../../models/cue_card.dart';
import 'scene_detail_page.dart';

class SceneListPage extends StatefulWidget {
  const SceneListPage({super.key});

  @override
  State<SceneListPage> createState() => _SceneListPageState();
}

class _SceneListPageState extends State<SceneListPage> {
  final VlogDataService _dataService = VlogDataService();
  List<CueCard> _scenes = [];
  
  @override
  void initState() {
    super.initState();
    _loadScenes();
  }
  
  void _loadScenes() {
    if (_dataService.cueCards != null) {
      setState(() {
        _scenes = List.from(_dataService.cueCards!);
      });
    }
  }
  
  // 더미 데이터 (API 연결 전 테스트용)
  List<Map<String, dynamic>> _dummyScenes = [
    {
      'id': '1',
      'title': '카페 입구에서 만남',
      'duration': '30초',
      'summary': '친구들과 반갑게 인사하며 카페로 들어가는 장면. 밝은 표정으로 자연스럽게 만남의 순간을 담아 영상의 오프닝을 장식합니다.',
      'thumbnail': Icons.meeting_room,
      'location': '카페 입구',
      'people': '3명',
      'cameraAngle': '미디엄 샷',
      'lighting': '자연광',
    },
    {
      'id': '2',
      'title': '자리 잡고 메뉴 선택',
      'duration': '1분 30초',
      'summary': '테이블에 앉아 메뉴판을 보며 주문할 음료를 고르는 장면. 친구들과의 소소한 대화를 통해 자연스러운 분위기를 연출합니다.',
      'thumbnail': Icons.menu_book,
      'location': '카페 창가 테이블',
      'people': '3명',
      'cameraAngle': '오버 숄더 샷',
      'lighting': '자연광 + 실내조명',
    },
    {
      'id': '3',
      'title': '주문 및 대화',
      'duration': '2분',
      'summary': '음료를 주문하고 최근 근황에 대해 이야기를 나누는 장면. 친구들 간의 케미를 보여주는 핵심 씬입니다.',
      'thumbnail': Icons.chat_bubble,
      'location': '카페 테이블',
      'people': '3명',
      'cameraAngle': '미디엄 샷',
      'lighting': '실내조명',
    },
    {
      'id': '4',
      'title': '음식 소개',
      'duration': '1분',
      'summary': '나온 음료와 디저트를 소개하고 먹방을 진행하는 장면. 음식의 비주얼과 맛에 대한 솔직한 리뷰를 담습니다.',
      'thumbnail': Icons.fastfood,
      'location': '카페 테이블',
      'people': '3명',
      'cameraAngle': '클로즈업',
      'lighting': '자연광',
    },
    {
      'id': '5',
      'title': '본격 토크 타임',
      'duration': '3분',
      'summary': '최근 있었던 재미있는 일들을 공유하며 웃는 장면. 진솔한 대화를 통해 시청자들에게 공감을 이끌어냅니다.',
      'thumbnail': Icons.favorite,
      'location': '카페 테이블',
      'people': '3명',
      'cameraAngle': '와이드 샷',
      'lighting': '실내조명',
    },
    {
      'id': '6',
      'title': '카페 분위기 촬영',
      'duration': '45초',
      'summary': '카페 내부 인테리어와 다른 손님들의 모습을 담는 장면. B-roll 컷으로 활용하기 좋은 씬입니다.',
      'thumbnail': Icons.camera,
      'location': '카페 내부',
      'people': '촬영자만',
      'cameraAngle': '패닝 샷',
      'lighting': '자연광 + 실내조명',
    },
    {
      'id': '7',
      'title': '창밖 풍경',
      'duration': '30초',
      'summary': '창가에 앉아 창밖 거리 풍경을 배경으로 촬영하는 장면. 감성적인 분위기를 더해줍니다.',
      'thumbnail': Icons.landscape,
      'location': '카페 창가',
      'people': '1-2명',
      'cameraAngle': '미디엄 샷',
      'lighting': '자연광',
    },
    {
      'id': '8',
      'title': '디저트 추가 주문',
      'duration': '1분 20초',
      'summary': '케이크를 추가로 주문하고 함께 나눠 먹는 장면. 달콤한 순간을 친구들과 공유하는 따뜻한 씬입니다.',
      'thumbnail': Icons.cake,
      'location': '카페 테이블',
      'people': '3명',
      'cameraAngle': '클로즈업 + 미디엄 샷',
      'lighting': '자연광',
    },
    {
      'id': '9',
      'title': '사진 촬영',
      'duration': '40초',
      'summary': '함께 셀카를 찍고 음식 사진을 찍는 모습. 요즘 카페 브이로그의 필수 요소를 담아냅니다.',
      'thumbnail': Icons.photo_camera,
      'location': '카페 테이블',
      'people': '3명',
      'cameraAngle': '오버 숄더 샷',
      'lighting': '자연광',
    },
    {
      'id': '10',
      'title': '마무리 및 퇴장',
      'duration': '50초',
      'summary': '계산을 하고 카페를 나서며 오늘 하루를 마무리하는 장면. 만족스러운 표정으로 영상을 마무리합니다.',
      'thumbnail': Icons.exit_to_app,
      'location': '카페 출구',
      'people': '3명',
      'cameraAngle': '미디엄 샷',
      'lighting': '자연광',
    },
  ];

  String? _expandedSceneId;
  String? _selectedForAlternative;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '세부 씬',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _scenes.isEmpty
          ? Center(
              child: Text(
                '씬 데이터가 없습니다.\n사용자 입력을 완료하고 시나리오를 생성해주세요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : ReorderableListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _scenes.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = _scenes.removeAt(oldIndex);
            _scenes.insert(newIndex, item);
            // 데이터 서비스에도 반영
            _dataService.setCueCards(_scenes);
          });
        },
        itemBuilder: (context, index) {
          final scene = _scenes[index];
          final sceneId = index.toString();
          final isExpanded = _expandedSceneId == sceneId;
          final isSelected = _selectedForAlternative == sceneId;
          
          return Dismissible(
            key: ValueKey(sceneId),
            direction: DismissDirection.endToStart,
            dismissThresholds: const {
              DismissDirection.endToStart: 0.4,
            },
            background: Container(
              color: AppColors.error,
              child: const Center(
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: AppColors.cardBackground,
                    title: Text(
                      '씬 삭제',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    content: Text(
                      '이 씬을 삭제하시겠습니까?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          '취소',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          '삭제',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) {
              final deletedScene = _scenes[index];
              setState(() {
                _scenes.removeAt(index);
                _dataService.setCueCards(_scenes);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${deletedScene.title} 삭제됨'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            child: GestureDetector(
              onTap: () {
                // 단일 탭: 상세 페이지로 이동 (전체 씬 리스트와 현재 인덱스 전달)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SceneDetailPage(
                      scenes: _scenes,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              onDoubleTap: () {
                setState(() {
                  if (_expandedSceneId == sceneId) {
                    _expandedSceneId = null;
                    _selectedForAlternative = null;
                  } else {
                    _expandedSceneId = sceneId;
                    _selectedForAlternative = sceneId;
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.cardBackground,
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.primary
                        : AppColors.grey.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    // 씬 정보
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 상단: 썸네일 + 제목/시간 + 드래그 핸들
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 썸네일 (가로 비율 증가)
                              Container(
                                width: 120,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: scene.thumbnailUrl != null && scene.thumbnailUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: CachedNetworkImage(
                                          imageUrl: scene.thumbnailUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                AppColors.primary.withOpacity(0.5),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Center(
                                            child: Text(
                                              '씬 ${index + 1}',
                                              style: AppTextStyles.heading3.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          '씬 ${index + 1}',
                                          style: AppTextStyles.heading3.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              // 제목 및 시간
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      scene.title,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${scene.allocatedSec}초 | ${scene.trigger}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 드래그 핸들
                              Icon(
                                Icons.drag_handle,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                          // 하단: 요약
                          const SizedBox(height: 8),
                          Text(
                            scene.summary.isNotEmpty 
                                ? scene.summary.join(' · ')
                                : '씬 요약 정보가 없습니다.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // 대체 씬 드롭다운
                    if (isExpanded)
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: AppColors.background.withOpacity(0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '대체 씬 정보',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (scene.fallback.isNotEmpty)
                              _buildAlternativeOption(scene.fallback)
                            else
                              Text(
                                '대체 씬 정보가 없습니다.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlternativeOption(String title) {
    return InkWell(
      onTap: () {
        setState(() {
          _expandedSceneId = null;
          _selectedForAlternative = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('대체 씬으로 변경: $title'),
            backgroundColor: AppColors.primary,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
        ),
        child: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

