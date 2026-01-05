import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Data class for category in donut chart
class CategoryData {
  final String name;
  final double amount;
  final double percentage;
  final Color color;

  const CategoryData({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

/// Donut chart widget for category breakdown
class CategoryDonutChart extends StatelessWidget {
  final List<CategoryData> categories;
  final double strokeWidth;

  const CategoryDonutChart({
    super.key,
    required this.categories,
    this.strokeWidth = 30,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: Text('No data'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return Row(
          children: [
            // Donut chart
            SizedBox(
              width: size * 0.6,
              height: size,
              child: CustomPaint(
                painter: DonutChartPainter(
                  categories: categories,
                  strokeWidth: strokeWidth,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Legend
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: categories.take(5).map((category) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: category.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category.name,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<CategoryData> categories;
  final double strokeWidth;

  DonutChartPainter({
    required this.categories,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    double startAngle = -math.pi / 2; // Start from top

    for (final category in categories) {
      final sweepAngle = 2 * math.pi * (category.percentage / 100);
      
      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      // Draw percentage text on arc
      if (category.percentage >= 8) {
        final midAngle = startAngle + sweepAngle / 2;
        final textRadius = radius;
        final textX = center.dx + textRadius * 0.65 * math.cos(midAngle);
        final textY = center.dy + textRadius * 0.65 * math.sin(midAngle);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${category.percentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
        );
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
