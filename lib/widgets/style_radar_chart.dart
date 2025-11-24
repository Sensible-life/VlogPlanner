import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/vlog_data_service.dart';

class StyleRadarChart extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onTap;

  const StyleRadarChart({
    super.key,
    this.selectedIndex = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dataService = VlogDataService();

    // 데이터 가져오기
    final values = [
      (dataService.getMovement() + dataService.getIntensity()) / 2,
      dataService.getLocationDiversity().toDouble(),
      dataService.getExcitementSurprise().toDouble(),
      dataService.getExcitementSurprise().toDouble(), // 색감/질감
      dataService.getSpeedRhythm().toDouble(),
      dataService.getEmotionalExpression().toDouble(),
    ];

    return GestureDetector(
      onTapUp: (details) {
        if (onTap == null) return;

        // 탭 위치를 기반으로 어느 축을 선택했는지 계산
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final center = Offset(box.size.width / 2, box.size.height / 2);
        final dx = localPosition.dx - center.dx;
        final dy = localPosition.dy - center.dy;

        // 각도 계산 (12시 방향이 0도)
        var angle = (math.atan2(dx, -dy) * 180 / math.pi);
        if (angle < 0) angle += 360;

        // 6개 축으로 나누기 (60도씩)
        final index = ((angle + 30) / 60).floor() % 6;
        onTap!(index);
      },
      child: CustomPaint(
        painter: CustomRadarChartPainter(
          values: values,
          selectedIndex: selectedIndex,
        ),
        child: Container(),
      ),
    );
  }
}

class CustomRadarChartPainter extends CustomPainter {
  final List<double> values;
  final int selectedIndex;

  CustomRadarChartPainter({
    required this.values,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.75; // 70% 크기로 축소

    // 1. 축선 그리기 (dashed, 육각형보다 길게)
    _drawRadialLines(canvas, center, radius, radius * 1.2);

    // 2. 동심원 육각형 그리기 (5개)
    _drawHexagonGrids(canvas, center, radius);

    // 3. 데이터 영역 그리기
    _drawDataArea(canvas, center, radius);

    // 4. 포인트 그리기
    _drawDataPoints(canvas, center, radius);
  }

  void _drawRadialLines(Canvas canvas, Offset center, double maxRadius, double extendedRadius) {
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * math.pi / 180;
      final endX = center.dx + extendedRadius * math.sin(angle);
      final endY = center.dy - extendedRadius * math.cos(angle);

      final paint = Paint()
        ..color = i == selectedIndex ? const Color(0xFF1A1A1A) : const Color(0xFFB2B2B2)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      if (i == selectedIndex) {
        // 선택된 축: 중심~포인트(dashed) + 포인트~끝(실선)

        // 포인트 위치 계산
        final value = values[i].clamp(0.0, 5.0);
        final valueRadius = maxRadius * (value / 5);
        final pointX = center.dx + valueRadius * math.sin(angle);
        final pointY = center.dy - valueRadius * math.cos(angle);

        // 중심 ~ 포인트: dashed line
        _drawDashedLine(
          canvas,
          paint,
          center,
          Offset(pointX, pointY),
          dashLength: 4,
          dashSpace: 4,
        );

        // 포인트 ~ 끝: 실선
        canvas.drawLine(Offset(pointX, pointY), Offset(endX, endY), paint);
      } else {
        // 선택되지 않은 축: dashed line
        _drawDashedLine(
          canvas,
          paint,
          center,
          Offset(endX, endY),
          dashLength: 4,
          dashSpace: 4,
        );
      }
    }
  }

  void _drawHexagonGrids(Canvas canvas, Offset center, double maxRadius) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // 5개의 레벨 (1/5, 2/5, 3/5, 4/5, 5/5)
    for (int level = 1; level <= 5; level++) {
      final levelRadius = maxRadius * (level / 5);
      final path = _createHexagonPath(center, levelRadius);
      canvas.drawPath(path, paint);
    }
  }

  void _drawDataArea(Canvas canvas, Offset center, double maxRadius) {
    final fillPaint = Paint()
      ..color = const Color(0xFF2C3E50).withOpacity(0.75)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * math.pi / 180;
      final value = values[i].clamp(0.0, 5.0); // 0-5 범위로 제한
      final valueRadius = maxRadius * (value / 5);
      final x = center.dx + valueRadius * math.sin(angle);
      final y = center.dy - valueRadius * math.cos(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawDataPoints(Canvas canvas, Offset center, double maxRadius) {
    final fillPaint = Paint()
      ..color = const Color(0xFFFAFAFA)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * math.pi / 180;
      final value = values[i].clamp(0.0, 5.0);
      final valueRadius = maxRadius * (value / 5);
      final x = center.dx + valueRadius * math.sin(angle);
      final y = center.dy - valueRadius * math.cos(angle);

      final strokePaint = Paint()
        ..color = i == selectedIndex ? const Color(0xFF1A1A1A) : const Color(0xFFB2B2B2)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(x, y), 3, fillPaint);
      canvas.drawCircle(Offset(x, y), 3, strokePaint);
    }
  }

  Path _createHexagonPath(Offset center, double radius) {
    final path = Path();

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * math.pi / 180;
      final x = center.dx + radius * math.sin(angle);
      final y = center.dy - radius * math.cos(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    return path;
  }

  void _drawDashedLine(
    Canvas canvas,
    Paint paint,
    Offset start,
    Offset end,
    {required double dashLength,
    required double dashSpace}
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final dashCount = (distance / (dashLength + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startFraction = (i * (dashLength + dashSpace)) / distance;
      final endFraction = ((i * (dashLength + dashSpace)) + dashLength) / distance;

      canvas.drawLine(
        Offset(
          start.dx + dx * startFraction,
          start.dy + dy * startFraction,
        ),
        Offset(
          start.dx + dx * endFraction,
          start.dy + dy * endFraction,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomRadarChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.selectedIndex != selectedIndex;
  }
}
