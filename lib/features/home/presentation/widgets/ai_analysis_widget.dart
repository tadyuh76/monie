import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';

class AIAnalysisWidget extends StatelessWidget {
  const AIAnalysisWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isDarkMode
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDarkMode
                  ? [const Color(0xFF2E3747), const Color(0xFF1E2533)]
                  : [const Color(0xFFE9F7FF), const Color(0xFFD4EEFF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? const Color(0xFF3D4A63)
                          : const Color(0xFFBBE0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: isDarkMode ? Colors.cyanAccent : Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Insights',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              _buildPulsatingDot(),
            ],
          ),
          const SizedBox(height: 20),
          _buildInsightCard(
            context,
            title: 'Spending Forecast',
            content:
                'Based on your recent transactions, you may exceed your food budget by \$45 this month.',
            icon: Icons.trending_up,
            color: isDarkMode ? Colors.orangeAccent : Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            context,
            title: 'Savings Opportunity',
            content:
                'Reducing coffee purchases by 2 per week could save you \$28 monthly.',
            icon: Icons.savings,
            color: isDarkMode ? Colors.greenAccent : Colors.green,
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            context,
            title: 'Unusual Activity',
            content:
                'Your entertainment spending is 35% higher than your monthly average.',
            icon: Icons.warning_amber,
            color: isDarkMode ? Colors.amberAccent : Colors.amber,
          ),
          // const SizedBox(height: 20),
          // _buildAIActionButton(context),
        ],
      ),
    );
  }

  Widget _buildPulsatingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.greenAccent,
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.5 * (1 - value)),
                spreadRadius: 4.0 * value,
                blurRadius: 4.0 * value,
              ),
            ],
          ),
        );
      },
      onEnd: () {
        // Rebuild to restart animation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Force rebuild
        });
      },
    );
  }

  Widget _buildInsightCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
