import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';

// Custom painter for the line chart
class LineChartPainter extends CustomPainter {
  final bool isDarkMode;

  LineChartPainter({this.isDarkMode = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.chartLine
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

    // Grid lines
    final gridPaint =
        Paint()
          ..color = isDarkMode ? AppColors.chartGrid : Colors.grey[300]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Draw grid lines
    for (int i = 0; i < 4; i++) {
      final y = size.height - (i * (size.height / 3));

      // Dashed line
      final dashPath = Path();
      dashPath.moveTo(0, y);
      for (double x = 0; x < size.width; x += 12) {
        dashPath.moveTo(x, y);
        dashPath.lineTo(x + 6, y);
      }

      canvas.drawPath(dashPath, gridPaint);
    }

    // Line path
    final path = Path();

    // Define the points on the curve (values normalized to fit the chart)
    final points = [
      Offset(0, size.height), // 0
      Offset(size.width * 0.25, size.height * 0.5), // 90
      Offset(size.width * 0.5, size.height * 0.01), // 179
      Offset(size.width * 0.75, size.height * 0.02), // 178
      Offset(size.width, size.height * 0.02), // 178
    ];

    // Move to the first point
    path.moveTo(points[0].dx, points[0].dy);

    // Create a smooth curve through the points
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      // Simple curve - in real app use bezier curves for smoothness
      path.quadraticBezierTo((p1.dx + p2.dx) / 2, p1.dy, p2.dx, p2.dy);
    }

    // Draw the line
    canvas.drawPath(path, paint);

    // Fill area under the curve
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint =
        Paint()
          ..color = AppColors.chartLine.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Triangle painter for the indicator
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    // Draw a downward-pointing triangle
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
