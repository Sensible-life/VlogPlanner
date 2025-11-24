import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../ui/styles.dart';
import '../../config/api_config.dart';
import '../../services/template_metadata_service.dart';
import '../home_page.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  // 커스텀 페이지 전환 애니메이션 (오른쪽에서 슬라이드)
  static Route<void> route() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return const UserInfoPage();
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // 오른쪽에서 시작
        const end = Offset.zero; // 원래 위치
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      fullscreenDialog: true,
    );
  }

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  List<Map<String, String>> _referenceVideos = [];
  bool _isLoadingVideos = true;
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _loadReferenceVideos();
  }

  Future<void> _loadReferenceVideos() async {
    try {
      final videos = await TemplateMetadataService.getAllTemplateVideos();
      setState(() {
        _referenceVideos = videos;
        _isLoadingVideos = false;
      });
    } catch (e) {
      print('[USER_INFO] 비디오 목록 로드 실패: $e');
      setState(() {
        _isLoadingVideos = false;
      });
    }
  }

  String _maskApiKey(String? apiKey) {
    if (apiKey == null || apiKey.isEmpty) {
      return '설정되지 않음';
    }
    if (apiKey.length <= 8) {
      return '****';
    }
    return '${apiKey.substring(0, 4)}${'*' * (apiKey.length - 8)}${apiKey.substring(apiKey.length - 4)}';
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      // canLaunchUrl 체크 없이 직접 시도
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        print('[USER_INFO] URL을 열 수 없습니다: $url');
        // 사용자에게 알림 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('링크를 열 수 없습니다: $url'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('[USER_INFO] URL 열기 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('링크 열기 실패: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFCEDCD3),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            _buildHeader(context, screenWidth, screenHeight),
            // 메인 컨텐츠 영역
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.042,
                  vertical: screenHeight * 0.03,
                ),
                child: Column(
                  children: [
                    // 사용자 정보 아이콘
                    _buildUserIcon(screenWidth, screenHeight),
                    SizedBox(height: screenHeight * 0.03),
                    // 사용자 이름
                    _buildUserName(screenWidth),
                    SizedBox(height: screenHeight * 0.02),
                    // OpenAI API 키
                    _buildApiKey(screenWidth),
                    SizedBox(height: screenHeight * 0.03),
                    // 레퍼런스 비디오 드롭다운
                    _buildReferenceVideosDropdown(screenWidth, screenHeight),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 상단 헤더
  Widget _buildHeader(BuildContext context, double screenWidth, double screenHeight) {
    final buttonSize = screenWidth * 0.117;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.042,
        vertical: screenHeight * 0.023,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 뒤로가기 버튼
          GestureDetector(
            onTap: () {
              // 키보드 닫기
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
            child: Container(
              width: buttonSize,
              height: buttonSize,
              child: Center(
                child: Image.asset(
                  'assets/icons/icon_arrow.png',
                  width: buttonSize,
                  height: buttonSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // 로고와 화면 이름
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 (클릭 시 홈으로 이동)
              GestureDetector(
                onTap: () {
                  // 키보드 닫기
                  FocusScope.of(context).unfocus();
                  
                  // 네비게이션 스택을 모두 제거하고 홈으로 이동
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
                  );
                },
                child: Image.asset(
                  'assets/images/logo_text.png',
                  width: screenWidth * 0.25, // 더 작게
                  fit: BoxFit.contain,
                ),
              ),
              // 화면 이름 (작은 글씨)
              Text(
                '사용자 정보',
                style: TextStyle(
                  fontFamily: 'Tmoney RoundWind',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xFF1A1A1A).withOpacity(0.7),
                ),
              ),
            ],
          ),

          // 오른쪽 빈 공간 (대칭을 위해)
          SizedBox(width: buttonSize),
        ],
      ),
    );
  }

  // 사용자 정보 아이콘
  Widget _buildUserIcon(double screenWidth, double screenHeight) {
    return Center(
      child: Image.asset(
        'assets/images/photo_user.png',
        width: screenWidth * 0.25,
        height: screenWidth * 0.25,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('[USER_INFO] photo_user.png 로드 실패: $error');
          // 폴백: button_user.png 사용
          return Image.asset(
            'assets/images/button_user.png',
            width: screenWidth * 0.25,
            height: screenWidth * 0.25,
            fit: BoxFit.contain,
            errorBuilder: (context, error2, stackTrace2) {
              print('[USER_INFO] button_user.png도 로드 실패: $error2');
              // 최종 폴백: 아이콘 표시
              return Icon(
                Icons.person,
                size: screenWidth * 0.25,
                color: const Color(0xFF1A1A1A),
              );
            },
          );
        },
      ),
    );
  }

  // 사용자 이름
  Widget _buildUserName(double screenWidth) {
    return Center(
      child: Text(
        '조성원',
        style: TextStyle(
          fontFamily: 'Tmoney RoundWind',
          fontSize: screenWidth * 0.055,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  // OpenAI API 키
  Widget _buildApiKey(double screenWidth) {
    final apiKey = ApiConfig.apiKey;
    final maskedKey = _maskApiKey(apiKey);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.04,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
          bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
          right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
          top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
        ),
      ),
      child: Row(
        children: [
          Text(
            'OpenAI API Key: ',
            style: TextStyle(
              fontFamily: 'Tmoney RoundWind',
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          Expanded(
            child: Text(
              maskedKey,
              style: TextStyle(
                fontFamily: 'Tmoney RoundWind',
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1A1A1A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 레퍼런스 비디오 드롭다운
  Widget _buildReferenceVideosDropdown(double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: Color(0xFF1A1A1A), width: 3),
          bottom: BorderSide(color: Color(0xFF1A1A1A), width: 6),
          right: BorderSide(color: Color(0xFF1A1A1A), width: 6),
          top: BorderSide(color: Color(0xFF1A1A1A), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 드롭다운 헤더
          GestureDetector(
            onTap: () {
              setState(() {
                _isDropdownOpen = !_isDropdownOpen;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenWidth * 0.04,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '레퍼런스 비디오 링크',
                    style: TextStyle(
                      fontFamily: 'Tmoney RoundWind',
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Icon(
                    _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF1A1A1A),
                    size: screenWidth * 0.06,
                  ),
                ],
              ),
            ),
          ),
          // 드롭다운 리스트
          if (_isDropdownOpen)
            Container(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.4,
              ),
              child: _isLoadingVideos
                  ? Padding(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    )
                  : _referenceVideos.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          child: Center(
                            child: Text(
                              '비디오 목록이 없습니다',
                              style: TextStyle(
                                fontFamily: 'Tmoney RoundWind',
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFFB2B2B2),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenWidth * 0.02,
                          ),
                          itemCount: _referenceVideos.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: const Color(0xFFB2B2B2).withOpacity(0.3),
                          ),
                          itemBuilder: (context, index) {
                            final video = _referenceVideos[index];
                            return GestureDetector(
                              onTap: () {
                                _openUrl(video['url']!);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: screenWidth * 0.03,
                                ),
                                child: Text(
                                  video['title']!,
                                  style: TextStyle(
                                    fontFamily: 'Tmoney RoundWind',
                                    fontSize: screenWidth * 0.038,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF2C3E50),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
        ],
      ),
    );
  }
}

