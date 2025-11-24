import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 앱 전역에서 사용하는 Custom Notification Widget
/// 상단에서 슬라이드 다운되며 나타났다가 자동으로 사라짐
class AppNotification {
  static OverlayEntry? _currentEntry;
  static bool _isShowing = false;

  /// 알림 표시
  /// [context] - BuildContext
  /// [message] - 표시할 메시지
  /// [type] - 알림 타입 (info, warning, error, success)
  /// [onTap] - 알림 탭 시 실행할 콜백 (선택사항, 체크 버튼과 동일)
  /// [showActions] - 체크/X 버튼 표시 여부 (기본 true)
  static void show(
    BuildContext context,
    String message, {
    NotificationType type = NotificationType.info,
    VoidCallback? onTap,
    bool showActions = true,
  }) {
    // 이미 알림이 표시 중이면 무시
    if (_isShowing) return;

    _isShowing = true;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _NotificationWidget(
        message: message,
        type: type,
        onDismiss: () {
          entry.remove();
          _currentEntry = null;
          _isShowing = false;
        },
        onTap: onTap,
        showActions: showActions,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// 현재 표시 중인 알림 즉시 제거
  static void dismiss() {
    if (_currentEntry != null) {
      _currentEntry!.remove();
      _currentEntry = null;
      _isShowing = false;
    }
  }
}

enum NotificationType {
  info,
  warning,
  error,
  success,
}

class _NotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;
  final bool showActions;

  const _NotificationWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    this.onTap,
    this.showActions = true,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // 슬라이드 애니메이션 (위에서 아래로)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // 페이드 애니메이션
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // 애니메이션 시작
    _controller.forward();
  }

  void _dismiss() async {
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case NotificationType.info:
        return AppColors.background;
      case NotificationType.warning:
        return const Color(0xFFFFF4E5);
      case NotificationType.error:
        return const Color(0xFFFFE5E5);
      case NotificationType.success:
        return const Color(0xFFE5F5E5);
    }
  }

  Color _getBorderColor() {
    switch (widget.type) {
      case NotificationType.info:
        return AppColors.black;
      case NotificationType.warning:
        return const Color(0xFFFF9800);
      case NotificationType.error:
        return const Color(0xFFF44336);
      case NotificationType.success:
        return const Color(0xFF4CAF50);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.success:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                width: screenWidth - 32,
                constraints: const BoxConstraints(minHeight: 60),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(),
                  border: Border(
                    left: BorderSide(color: _getBorderColor(), width: 2),
                    bottom: BorderSide(color: _getBorderColor(), width: 3.5),
                    right: BorderSide(color: _getBorderColor(), width: 3.5),
                    top: BorderSide(color: _getBorderColor(), width: 2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // 아이콘
                      Icon(
                        _getIcon(),
                        color: _getBorderColor(),
                        size: 28,
                      ),
                      const SizedBox(width: 12),

                      // 메시지
                      Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            fontFamily: 'Tmoney RoundWind',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.black,
                            height: 1.4,
                          ),
                        ),
                      ),

                      // 액션 버튼들 (체크와 X)
                      if (widget.showActions) ...[
                        // 체크 버튼 (onTap이 있을 때만 표시)
                        if (widget.onTap != null)
                          GestureDetector(
                            onTap: () {
                              widget.onTap!();
                              _dismiss();
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.black,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 18,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        
                        // X 버튼
                        GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.black,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ] else ...[
                        // showActions가 false일 때는 기존 닫기 버튼만 표시
                        GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.black.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
