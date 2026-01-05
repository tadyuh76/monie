import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:monie/features/predictions/domain/entities/spending_prediction.dart';
import 'package:monie/features/predictions/presentation/bloc/prediction_bloc.dart';
import 'package:monie/features/predictions/presentation/bloc/prediction_event.dart';
import 'package:monie/features/predictions/presentation/bloc/prediction_state.dart';
import 'package:monie/features/predictions/presentation/pages/spending_forecast_page.dart';

/// Widget showing next month spending forecast on home page
class NextMonthForecastWidget extends StatefulWidget {
  const NextMonthForecastWidget({super.key});

  @override
  State<NextMonthForecastWidget> createState() =>
      _NextMonthForecastWidgetState();
}

class _NextMonthForecastWidgetState extends State<NextMonthForecastWidget> {
  @override
  void initState() {
    super.initState();
    _loadPrediction();
  }

  void _loadPrediction() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<PredictionBloc>().add(
            GeneratePredictionEvent(userId: authState.user.id),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => _navigateToForecastPage(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.cardDark : Colors.white,
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
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('Next Month Forecast'),
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
            BlocBuilder<PredictionBloc, PredictionState>(
              builder: (context, state) {
                if (state is PredictionLoading) {
                  return _buildLoadingContent(isDarkMode, textTheme);
                }

                if (state is PredictionLoaded) {
                  return _buildLoadedContent(
                      context, state.prediction, isDarkMode, textTheme);
                }

                if (state is PredictionNoData) {
                  return _buildNoDataContent(
                      context, state.message, isDarkMode, textTheme);
                }

                if (state is PredictionError) {
                  return _buildErrorContent(isDarkMode, textTheme);
                }

                return _buildInitialContent(isDarkMode, textTheme);
              },
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                context.tr('tap to view detailed forecast'),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.secondary,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shimmer for predicted amount
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(isDarkMode, width: 60, height: 12),
                const SizedBox(height: 4),
                _buildShimmerBox(isDarkMode, width: 120, height: 28),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildShimmerBox(isDarkMode, width: 80, height: 12),
                const SizedBox(height: 4),
                _buildShimmerBox(isDarkMode, width: 60, height: 16),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Shimmer for confidence bar
        _buildShimmerBox(isDarkMode, width: double.infinity, height: 6),
        const SizedBox(height: 8),
        _buildShimmerBox(isDarkMode, width: 150, height: 12),
      ],
    );
  }

  Widget _buildShimmerBox(bool isDarkMode, {required double width, required double height}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      Colors.white.withValues(alpha: value * 0.1),
                      Colors.white.withValues(alpha: value * 0.2),
                      Colors.white.withValues(alpha: value * 0.1),
                    ]
                  : [
                      Colors.grey.withValues(alpha: value * 0.2),
                      Colors.grey.withValues(alpha: value * 0.3),
                      Colors.grey.withValues(alpha: value * 0.2),
                    ],
            ),
          ),
        );
      },
      onEnd: () {},
    );
  }

  Widget _buildLoadedContent(
    BuildContext context,
    SpendingPrediction prediction,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    // Get total budget if available
    double? totalBudget;
    final budgetsState = context.read<BudgetsBloc>().state;
    if (budgetsState is BudgetsLoaded) {
      totalBudget = budgetsState.budgets
          .where((b) => _isBudgetActive(b))
          .fold<double>(0, (sum, b) => sum + b.amount);
    }

    final percentOfBudget = totalBudget != null && totalBudget > 0
        ? (prediction.predictedAmount / totalBudget * 100)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Predicted amount
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('predicted'),
                  style: textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? Colors.white54 : Colors.black45,
                  ),
                ),
                Text(
                  Formatters.formatCurrency(prediction.predictedAmount),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (totalBudget != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    context.tr('budget'),
                    style: textTheme.bodySmall?.copyWith(
                      color: isDarkMode ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(totalBudget),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Progress bar
        if (percentOfBudget != null) ...[
          Text(
            '${percentOfBudget.toStringAsFixed(0)}% of budget',
            style: textTheme.bodySmall?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percentOfBudget / 100).clamp(0, 1),
              backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentOfBudget > 100
                    ? Colors.red
                    : percentOfBudget > 80
                        ? Colors.orange
                        : AppColors.secondary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Confidence
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: isDarkMode ? Colors.white54 : Colors.black45,
            ),
            const SizedBox(width: 6),
            Text(
              '${context.tr('confidence')}: ${prediction.confidenceLabel} (${prediction.confidenceScore}%)',
              style: textTheme.bodySmall?.copyWith(
                color: isDarkMode ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ],
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
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[100],
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

  Widget _buildErrorContent(bool isDarkMode, TextTheme textTheme) {
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
              'Failed to generate forecast',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.red[400],
              ),
            ),
          ),
          TextButton(
            onPressed: _loadPrediction,
            child: const Text('Retry'),
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
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.trending_up,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap to generate spending forecast',
              style: textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isBudgetActive(Budget budget) {
    final now = DateTime.now();
    final endDate = budget.endDate ?? DateTime(2099);
    return budget.startDate.isBefore(now) && endDate.isAfter(now);
  }

  void _navigateToForecastPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SpendingForecastPage(),
      ),
    );
  }
}
