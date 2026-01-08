import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/ai_insights/domain/entities/spending_pattern.dart';
import 'package:monie/features/ai_insights/presentation/bloc/spending_pattern_bloc.dart';
import 'package:monie/features/ai_insights/presentation/bloc/spending_pattern_event.dart';
import 'package:monie/features/ai_insights/presentation/bloc/spending_pattern_state.dart';
import 'package:monie/features/ai_insights/presentation/widgets/financial_health_gauge.dart';
import 'package:monie/features/ai_insights/presentation/widgets/category_donut_chart.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';

/// Full page for detailed spending analysis
class SpendingAnalysisPage extends StatefulWidget {
  const SpendingAnalysisPage({super.key});

  @override
  State<SpendingAnalysisPage> createState() => SpendingAnalysisPageState();
}

class SpendingAnalysisPageState extends State<SpendingAnalysisPage> {
  int selectedPeriodMonths = 3;

  @override
  void initState() {
    super.initState();
    loadAnalysis();
  }

  void loadAnalysis() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - selectedPeriodMonths, now.day);
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

  void refreshAnalysis() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - selectedPeriodMonths, now.day);
      final endDate = now;

      context.read<SpendingPatternBloc>().add(
            RefreshSpendingPatternEvent(
              userId: authState.user.id,
              startDate: startDate,
              endDate: endDate,
            ),
          );
    }
  }

  void changePeriod(int months) {
    if (selectedPeriodMonths != months) {
      setState(() {
        selectedPeriodMonths = months;
      });
      loadAnalysis();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.background : Colors.grey[100],
      appBar: AppBar(
        title: Text(context.tr('spending analysis')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshAnalysis,
          ),
        ],
      ),
      body: BlocBuilder<SpendingPatternBloc, SpendingPatternState>(
        builder: (context, state) {
          if (state is SpendingPatternLoading) {
            return buildLoadingView(isDarkMode, textTheme);
          }

          if (state is SpendingPatternLoaded) {
            return buildLoadedView(context, state.pattern, isDarkMode, textTheme);
          }

          if (state is SpendingPatternNoData) {
            return buildNoDataView(context, state.message, isDarkMode, textTheme);
          }

          if (state is SpendingPatternError) {
            return buildErrorView(context, state.message, isDarkMode, textTheme);
          }

          return buildLoadingView(isDarkMode, textTheme);
        },
      ),
    );
  }

  Widget buildPeriodSelector(bool isDarkMode, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Analysis Period'),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: buildPeriodButton(
                  label: context.tr('1 Month'),
                  months: 1,
                  isDarkMode: isDarkMode,
                  textTheme: textTheme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildPeriodButton(
                  label: context.tr('3 Months'),
                  months: 3,
                  isDarkMode: isDarkMode,
                  textTheme: textTheme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildPeriodButton(
                  label: context.tr('6 Months'),
                  months: 6,
                  isDarkMode: isDarkMode,
                  textTheme: textTheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPeriodButton({
    required String label,
    required int months,
    required bool isDarkMode,
    required TextTheme textTheme,
  }) {
    final isSelected = selectedPeriodMonths == months;
    return GestureDetector(
      onTap: () => changePeriod(months),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : (isDarkMode ? Colors.white10 : Colors.grey[200]),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : (isDarkMode ? Colors.white70 : Colors.black54),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCachedIndicator(bool isDarkMode, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cached, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            context.tr('Showing cached analysis'),
            style: textTheme.bodySmall?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
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
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('Analyzing your spending patterns...'),
            style: textTheme.titleMedium?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('This may take a few seconds'),
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
    SpendingPattern pattern,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    return RefreshIndicator(
      onRefresh: () async => refreshAnalysis(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analysis Period Selector
            buildPeriodSelector(isDarkMode, textTheme),
            const SizedBox(height: 16),

            // Cached indicator
            if (pattern.isCached) ...[
              buildCachedIndicator(isDarkMode, textTheme),
              const SizedBox(height: 16),
            ],

            // Financial Health Score Card
            buildHealthScoreCard(context, pattern, isDarkMode, textTheme),
            const SizedBox(height: 20),

            // AI Analysis Summary
            if (pattern.aiSummary != null && pattern.aiSummary!.isNotEmpty)
              buildAiSummaryCard(context, pattern.aiSummary!, isDarkMode, textTheme),
            if (pattern.aiSummary != null && pattern.aiSummary!.isNotEmpty)
              const SizedBox(height: 20),

            // Spending Overview Card
            buildSpendingOverviewCard(context, pattern, isDarkMode, textTheme),
            const SizedBox(height: 20),

            // Category Breakdown Card
            if (pattern.categoryBreakdown.isNotEmpty)
              buildCategoryBreakdownCard(context, pattern, isDarkMode, textTheme),
            if (pattern.categoryBreakdown.isNotEmpty)
              const SizedBox(height: 20),

            // Spending Trend Card
            buildTrendCard(context, pattern, isDarkMode, textTheme),
            const SizedBox(height: 20),

            // Unusual Patterns
            if (pattern.unusualPatterns.isNotEmpty)
              buildUnusualPatternsCard(
                  context, pattern.unusualPatterns, isDarkMode, textTheme),
            if (pattern.unusualPatterns.isNotEmpty) const SizedBox(height: 20),

            // Recommendations
            if (pattern.recommendations.isNotEmpty)
              buildRecommendationsCard(
                  context, pattern.recommendations, isDarkMode, textTheme),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget buildHealthScoreCard(
    BuildContext context,
    SpendingPattern pattern,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            context.tr('Financial Health Score'),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FinancialHealthGauge(
            score: pattern.financialHealthScore,
            size: 180,
          ),
          const SizedBox(height: 20),
          // Health score message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.thumb_up,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pattern.healthScoreMessage,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAiSummaryCard(
    BuildContext context,
    String summary,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
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
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome, color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('AI Analysis Summary'),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.secondary, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'AI',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            summary,
            style: textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSpendingOverviewCard(
    BuildContext context,
    SpendingPattern pattern,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    final dateFormat = DateFormat('MMM d');
    final periodText = '${dateFormat.format(pattern.periodStart)} - ${dateFormat.format(pattern.periodEnd)}';

    return buildCard(
      context,
      title: context.tr('Spending Overview'),
      icon: Icons.account_balance_wallet,
      iconColor: AppColors.primary,
      isDarkMode: isDarkMode,
      textTheme: textTheme,
      child: Column(
        children: [
          buildOverviewRow(
            icon: Icons.payments,
            label: context.tr('Total Spending'),
            value: Formatters.formatCurrency(pattern.totalSpending),
            valueColor: AppColors.expense,
            isDarkMode: isDarkMode,
            textTheme: textTheme,
          ),
          const Divider(height: 24),
          buildOverviewRow(
            icon: Icons.calendar_view_day,
            label: context.tr('Daily Average'),
            value: Formatters.formatCurrency(pattern.dailyAverage),
            valueColor: AppColors.expense,
            isDarkMode: isDarkMode,
            textTheme: textTheme,
          ),
          const Divider(height: 24),
          buildOverviewRow(
            icon: Icons.category,
            label: context.tr('Top Category'),
            value: pattern.topCategory,
            valueColor: AppColors.expense,
            isDarkMode: isDarkMode,
            textTheme: textTheme,
          ),
          const Divider(height: 24),
          buildOverviewRow(
            icon: Icons.calendar_today,
            label: context.tr('Peak Spending Day'),
            value: pattern.peakSpendingDay,
            valueColor: AppColors.expense,
            isDarkMode: isDarkMode,
            textTheme: textTheme,
          ),
          const Divider(height: 24),
          buildOverviewRow(
            icon: Icons.access_time,
            label: context.tr('Peak Spending Hour'),
            value: pattern.peakSpendingHour,
            valueColor: AppColors.expense,
            isDarkMode: isDarkMode,
            textTheme: textTheme,
          ),
          const Divider(height: 24),
          buildOverviewRow(
            icon: Icons.date_range,
            label: context.tr('Period'),
            value: periodText,
            valueColor: isDarkMode ? Colors.white70 : Colors.black54,
            isDarkMode: isDarkMode,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }

  Widget buildOverviewRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    required bool isDarkMode,
    required TextTheme textTheme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDarkMode ? Colors.white54 : Colors.black38,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget buildCategoryBreakdownCard(
    BuildContext context,
    SpendingPattern pattern,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    // Sort categories by amount
    final sortedCategories = pattern.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.amount.compareTo(a.value.amount));

    // Assign colors to categories
    final categoryColors = <String, Color>{};
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    for (var i = 0; i < sortedCategories.length; i++) {
      categoryColors[sortedCategories[i].key] = colors[i % colors.length];
    }

    return buildCard(
      context,
      title: context.tr('Category Breakdown'),
      icon: Icons.pie_chart,
      iconColor: Colors.blue,
      isDarkMode: isDarkMode,
      textTheme: textTheme,
      child: Column(
        children: [
          // Donut chart
          SizedBox(
            height: 200,
            child: CategoryDonutChart(
              categories: sortedCategories
                  .map((e) => CategoryData(
                        name: e.key,
                        amount: e.value.amount,
                        percentage: e.value.percentage,
                        color: categoryColors[e.key]!,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          // Category list
          ...sortedCategories.map((entry) {
            final color = categoryColors[entry.key]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.key,
                        style: textTheme.bodyMedium?.copyWith(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Formatters.formatCurrency(entry.value.amount),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.value.percentage / 100,
                            backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${entry.value.percentage.toStringAsFixed(1)}%',
                          style: textTheme.bodySmall?.copyWith(
                            color: isDarkMode ? Colors.white54 : Colors.black45,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildTrendCard(
    BuildContext context,
    SpendingPattern pattern,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    final trendIcon = pattern.spendingTrend == SpendingTrend.increasing
        ? Icons.trending_up
        : pattern.spendingTrend == SpendingTrend.decreasing
            ? Icons.trending_down
            : Icons.trending_flat;

    final trendColor = pattern.spendingTrend == SpendingTrend.increasing
        ? Colors.red
        : pattern.spendingTrend == SpendingTrend.decreasing
            ? Colors.green
            : Colors.amber;

    final trendMessage = pattern.spendingTrend == SpendingTrend.increasing
        ? context.tr('Your spending is increasing')
        : pattern.spendingTrend == SpendingTrend.decreasing
            ? context.tr('Your spending is decreasing')
            : context.tr('Your spending is stable');

    return buildCard(
      context,
      title: context.tr('Spending Trend'),
      icon: trendIcon,
      iconColor: trendColor,
      isDarkMode: isDarkMode,
      textTheme: textTheme,
      child: Text(
        trendMessage,
        style: textTheme.bodyMedium?.copyWith(
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget buildUnusualPatternsCard(
    BuildContext context,
    List<String> patterns,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
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
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('Unusual Patterns Detected'),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...patterns.map((pattern) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: textTheme.bodyMedium?.copyWith(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      pattern,
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildRecommendationsCard(
    BuildContext context,
    List<String> recommendations,
    bool isDarkMode,
    TextTheme textTheme,
  ) {
    return buildCard(
      context,
      title: context.tr('recommendations'),
      icon: Icons.lightbulb_outline,
      iconColor: Colors.green,
      isDarkMode: isDarkMode,
      textTheme: textTheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: recommendations.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          buildPeriodSelector(isDarkMode, textTheme),
          const SizedBox(height: 100),
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
            context.tr('Add more transactions to get AI-powered insights'),
            style: textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.white54 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
              context.tr('Analysis Failed'),
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
              onPressed: refreshAnalysis,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('Retry')),
            ),
          ],
        ),
      ),
    );
  }
}
