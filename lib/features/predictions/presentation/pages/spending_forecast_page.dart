import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/predictions/domain/entities/spending_prediction.dart';
import 'package:monie/features/predictions/presentation/bloc/prediction_bloc.dart';
import 'package:monie/features/predictions/presentation/bloc/prediction_event.dart';
import 'package:monie/features/predictions/presentation/bloc/prediction_state.dart';

/// Full page for detailed spending forecast
class SpendingForecastPage extends StatefulWidget {
  const SpendingForecastPage({super.key});

  @override
  State<SpendingForecastPage> createState() => SpendingForecastPageState();
}

class SpendingForecastPageState extends State<SpendingForecastPage> {
  @override
  void initState() {
    super.initState();
    loadPrediction();
  }

  void loadPrediction() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<PredictionBloc>().add(
            GeneratePredictionEvent(userId: authState.user.id),
          );
    }
  }

  void refreshPrediction() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<PredictionBloc>().add(
            RefreshPredictionEvent(userId: authState.user.id),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.background : Colors.grey[100],
      appBar: AppBar(
        title: Text(context.tr('spending forecast')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshPrediction,
          ),
        ],
      ),
      body: BlocBuilder<PredictionBloc, PredictionState>(
        builder: (context, state) {
          if (state is PredictionLoading) {
            return buildLoadingView(isDarkMode, textTheme);
          }

          if (state is PredictionLoaded) {
            return buildLoadedView(
                context, state.prediction, isDarkMode, textTheme);
          }

          if (state is PredictionNoData) {
            return buildNoDataView(
                context, state.message, isDarkMode, textTheme);
          }

          if (state is PredictionError) {
            return buildErrorView(
                context, state.message, isDarkMode, textTheme);
          }

          return buildLoadingView(isDarkMode, textTheme);
        },
      ),
    );
  }

  Widget buildLoadingView(bool isDarkMode, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('Generating spending forecast...'),
            style: textTheme.titleMedium?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('Analyzing your spending patterns'),
            style: textTheme.bodySmall?.copyWith(
              color: isDarkMode ? Colors.white54 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoadedView(
    BuildContext context,
    SpendingPrediction prediction,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    return RefreshIndicator(
      onRefresh: () async => refreshPrediction(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main prediction card
            buildPredictionCard(context, prediction, isDarkMode, textTheme),
            const SizedBox(height: 20),

            // Trend card
            buildTrendCard(context, prediction, isDarkMode, textTheme),
            const SizedBox(height: 20),

            // Category predictions
            if (prediction.categoryPredictions.isNotEmpty)
              buildCategoryPredictionsCard(
                  context, prediction, isDarkMode, textTheme),
            if (prediction.categoryPredictions.isNotEmpty)
              const SizedBox(height: 20),

            // Insights
            if (prediction.insights.isNotEmpty)
              buildInsightsCard(
                  context, prediction.insights, isDarkMode, textTheme),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget buildPredictionCard(
    BuildContext context,
    SpendingPrediction prediction,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF2E3747), const Color(0xFF1E2533)]
              : [Colors.white, const Color(0xFFF5F5F5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        children: [
          Text(
            context.tr('predicted spending'),
            style: textTheme.titleMedium?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            Formatters.formatCurrency(prediction.predictedAmount),
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            getPeriodLabel(prediction.period),
            style: textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 20),

          // Confidence indicator
          buildConfidenceIndicator(prediction, isDarkMode, textTheme),
        ],
      ),
    );
  }

  Widget buildConfidenceIndicator(
    SpendingPrediction prediction,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    final confidenceColor = prediction.confidenceScore >= 80
        ? Colors.green
        : prediction.confidenceScore >= 60
            ? Colors.orange
            : Colors.red;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 18,
              color: confidenceColor,
            ),
            const SizedBox(width: 8),
            Text(
              '${context.tr('confidence')}: ${prediction.confidenceLabel}',
              style: textTheme.bodyMedium?.copyWith(
                color: confidenceColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: prediction.confidenceScore / 100,
            backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
            valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${prediction.confidenceScore}%',
          style: textTheme.bodySmall?.copyWith(
            color: isDarkMode ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget buildTrendCard(
    BuildContext context,
    SpendingPrediction prediction,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    final trendIcon = prediction.trend == SpendingTrendType.increasing
        ? Icons.trending_up
        : prediction.trend == SpendingTrendType.decreasing
            ? Icons.trending_down
            : Icons.trending_flat;

    final trendColor = prediction.trend == SpendingTrendType.increasing
        ? Colors.red
        : prediction.trend == SpendingTrendType.decreasing
            ? Colors.green
            : Colors.amber;

    final trendLabel = prediction.trend == SpendingTrendType.increasing
        ? context.tr('increasing')
        : prediction.trend == SpendingTrendType.decreasing
            ? context.tr('decreasing')
            : context.tr('stable');

    final trendDescription = prediction.trend == SpendingTrendType.increasing
        ? context.tr('Your spending is expected to increase compared to recent months.')
        : prediction.trend == SpendingTrendType.decreasing
            ? context.tr('Your spending is expected to decrease compared to recent months.')
            : context.tr('Your spending is expected to remain stable.');

    return buildCard(
      context,
      title: context.tr('expected trend'),
      icon: trendIcon,
      iconColor: trendColor,
      isDarkMode: isDarkMode,
      textTheme: textTheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(trendIcon, color: trendColor, size: 20),
                const SizedBox(width: 6),
                Text(
                  trendLabel,
                  style: textTheme.bodyMedium?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            trendDescription,
            style: textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCategoryPredictionsCard(
    BuildContext context,
    SpendingPrediction prediction,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    // Sort categories by amount
    final sortedCategories = prediction.categoryPredictions.entries.toList()
      ..sort((a, b) => b.value.amount.compareTo(a.value.amount));

    return buildCard(
      context,
      title: context.tr('category forecast'),
      icon: Icons.category,
      iconColor: AppColors.primary,
      isDarkMode: isDarkMode,
      textTheme: textTheme,
      child: Column(
        children: sortedCategories.take(6).map((entry) {
          final change = entry.value.changePercent;
          final changeColor = change > 0
              ? Colors.red
              : change < 0
                  ? Colors.green
                  : Colors.grey;
          final changeIcon = change > 0
              ? Icons.arrow_upward
              : change < 0
                  ? Icons.arrow_downward
                  : Icons.remove;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    Formatters.formatCurrency(entry.value.amount),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(changeIcon, size: 14, color: changeColor),
                      const SizedBox(width: 2),
                      Text(
                        '${change.abs().toStringAsFixed(0)}%',
                        style: textTheme.bodySmall?.copyWith(
                          color: changeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildInsightsCard(
    BuildContext context,
    List<String> insights,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    return buildCard(
      context,
      title: context.tr('insights'),
      icon: Icons.lightbulb_outline,
      iconColor: Colors.amber,
      isDarkMode: isDarkMode,
      textTheme: textTheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: insights.map((insight) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: Colors.amber,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    insight,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDarkMode,
    required TextTheme textTheme,
    required Widget child,
  }) {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget buildNoDataView(
    BuildContext context,
    String message,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: isDarkMode ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: textTheme.titleMedium?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('Add more transactions to get AI-powered forecasts'),
              style: textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.white54 : Colors.black38,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildErrorView(
    BuildContext context,
    String message,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('Forecast Generation Failed'),
              style: textTheme.titleMedium?.copyWith(
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.white54 : Colors.black38,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: refreshPrediction,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('Retry')),
            ),
          ],
        ),
      ),
    );
  }

  String getPeriodLabel(String period) {
    switch (period) {
      case 'next_week':
        return context.tr('Next Week');
      case 'next_month':
        return context.tr('Next Month');
      case 'next_quarter':
        return context.tr('Next Quarter');
      default:
        return context.tr('Next Month');
    }
  }
}
