import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/ai_insights/domain/entities/spending_pattern.dart';
import 'package:monie/features/ai_insights/presentation/bloc/spending_pattern_bloc.dart';
import 'package:monie/features/ai_insights/presentation/bloc/spending_pattern_event.dart';
import 'package:monie/features/ai_insights/presentation/bloc/spending_pattern_state.dart';
import 'package:monie/features/ai_insights/presentation/pages/spending_analysis_page.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';

/// Widget displaying AI spending insights on the home page
class AISpendingInsightsWidget extends StatefulWidget {
  const AISpendingInsightsWidget({super.key});

  @override
  State<AISpendingInsightsWidget> createState() =>
      _AISpendingInsightsWidgetState();
}

class _AISpendingInsightsWidgetState extends State<AISpendingInsightsWidget> {
  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  void _loadAnalysis() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = now;

      context.read<SpendingPatternBloc>().add(
            AnalyzeSpendingPatternEvent(
              userId: authState.user.id,
              startDate: startDate,
              endDate: endDate,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => _navigateToAnalysisPage(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [const Color(0xFF2E3747), const Color(0xFF1E2533)]
                : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('AI Spending Insights'),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDarkMode ? Colors.white54 : Colors.black45,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content based on state
            BlocBuilder<SpendingPatternBloc, SpendingPatternState>(
              builder: (context, state) {
                if (state is SpendingPatternLoading) {
                  return _buildLoadingContent(isDarkMode, textTheme);
                }

                if (state is SpendingPatternLoaded) {
                  return _buildLoadedContent(
                      context, state.pattern, isDarkMode, textTheme);
                }

                if (state is SpendingPatternNoData) {
                  return _buildNoDataContent(
                      context, state.message, isDarkMode, textTheme);
                }

                if (state is SpendingPatternError) {
                  return _buildErrorContent(
                      context, state.message, isDarkMode, textTheme);
                }

                return _buildInitialContent(isDarkMode, textTheme);
              },
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                context.tr('tap to view full analysis'),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingContent(bool isDarkMode, TextTheme textTheme) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Analyzing your spending...',
              style: textTheme.bodySmall?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent(
    BuildContext context,
    SpendingPattern pattern,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    return Column(
      children: [
        // Financial Health
        _buildInsightItem(
          context,
          icon: Icons.favorite,
          iconColor: _getHealthScoreColor(pattern.financialHealthScore),
          title: context.tr('financial health'),
          content: pattern.summary,
          isDarkMode: isDarkMode,
          textTheme: textTheme,
        ),
        const SizedBox(height: 12),

        // Show unusual patterns if any
        if (pattern.unusualPatterns.isNotEmpty)
          _buildInsightItem(
            context,
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.amber,
            title: context.tr('unusual activity'),
            content: pattern.unusualPatterns.first,
            isDarkMode: isDarkMode,
            textTheme: textTheme,
          ),
      ],
    );
  }

  Widget _buildInsightItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required bool isDarkMode,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
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
                  style: textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataContent(
    BuildContext context,
    String message,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: isDarkMode ? Colors.white54 : Colors.black45,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(
    BuildContext context,
    String message,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Failed to analyze spending',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.red[400],
              ),
            ),
          ),
          TextButton(
            onPressed: _loadAnalysis,
            child: Text(context.tr('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialContent(bool isDarkMode, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap to get AI-powered spending insights',
              style: textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.amber;
    if (score >= 20) return Colors.orange;
    return Colors.red;
  }

  void _navigateToAnalysisPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SpendingAnalysisPage(),
      ),
    );
  }
}
