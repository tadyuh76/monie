import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget displaying financial health score as a gauge
class FinancialHealthGauge extends StatelessWidget {
  final int score;
  final double size;

  const FinancialHealthGauge({
    super.key,
    required this.score,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background arc
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(
              score: score,
              isDarkMode: isDarkMode,
            ),
          ),
          // Score text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(score),
                ),
              ),
              Text(
                _getScoreLabel(score),
                style: textTheme.bodySmall?.copyWith(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.amber;
    if (score >= 20) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Poor';
    return 'Critical';
  }
}

class _GaugePainter extends CustomPainter {
  final int score;
  final bool isDarkMode;

  _GaugePainter({
    required this.score,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15;
    const strokeWidth = 12.0;

    // Background arc
    final backgroundPaint = Paint()
      ..color = isDarkMode ? Colors.white12 : Colors.black12
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      backgroundPaint,
    );

    // Score arc
    final scoreColor = _getScoreColor(score);
    final scorePaint = Paint()
      ..shader = SweepGradient(
        colors: [
          scoreColor.withValues(alpha: 0.5),
          scoreColor,
        ],
        startAngle: 0,
        endAngle: math.pi,
        transform: const GradientRotation(math.pi * 0.75),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * math.pi * 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      sweepAngle,
      false,
      scorePaint,
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.amber;
    if (score >= 20) return Colors.orange;
    return Colors.red;
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.isDarkMode != isDarkMode;
  }
}
