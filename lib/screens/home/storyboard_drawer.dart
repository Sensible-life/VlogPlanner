import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/vlog_data_service.dart';
import '../storyboard/storyboard_page.dart';

class StoryboardDrawer extends StatefulWidget {
  final VoidCallback? onClose;
  
  const StoryboardDrawer({super.key, this.onClose});

  @override
  State<StoryboardDrawer> createState() => _StoryboardDrawerState();
}

class _StoryboardDrawerState extends State<StoryboardDrawer> {
  final TextEditingController _searchController = TextEditingController();
  final VlogDataService _dataService = VlogDataService();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToStoryboard(BuildContext context, String storyboardId) {
    // 스토리보드 로드
    _dataService.loadStoryboard(storyboardId);
    
    // 사이드바 닫기
    widget.onClose?.call();
    
    // 스토리보드 페이지로 이동
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StoryboardPage()),
    );
  }

  List<SavedStoryboard> get _filteredStoryboards {
    final storyboards = _dataService.getSavedStoryboards();
    if (_searchQuery.isEmpty) {
      return storyboards;
    }
    return storyboards.where((storyboard) {
      return storyboard.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('yyyy.MM.dd').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.paper,
      child: SafeArea(
        child: Column(
          children: [
            // 검색창
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '검색...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.paperLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: AppColors.filmBorder.withOpacity(0.4),
                      width: 0.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: AppColors.filmBorder.withOpacity(0.4),
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: AppColors.filmBorder.withOpacity(0.6),
                      width: 0.8,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 스토리보드 리스트
            Expanded(
              child: _filteredStoryboards.isEmpty
                  ? Center(
                      child: Text(
                        '검색 결과가 없습니다',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _filteredStoryboards.length,
                      itemBuilder: (context, index) {
                        final storyboard = _filteredStoryboards[index];
                        return InkWell(
                          onTap: () {
                            widget.onClose?.call();
                            _navigateToStoryboard(context, storyboard.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.filmBorder.withOpacity(0.5),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      storyboard.title,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: AppColors.filmBlack,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(storyboard.createdAt),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.filmLightGray,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ],
                                ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
