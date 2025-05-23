import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/home/presentation/widgets/chart_painters.dart';
import 'package:monie/core/localization/app_localizations.dart';

class NetWorthSectionWidget extends StatelessWidget {
  final double netWorth;
  final int transactionsCount;

  const NetWorthSectionWidget({
    super.key,
    required this.netWorth,
    required this.transactionsCount,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            !isDarkMode
                ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('home_net_worth'),
            style: textTheme.titleLarge?.copyWith(
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatCurrency(netWorth),
            style: textTheme.headlineMedium?.copyWith(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$transactionsCount ${context.tr('home_transactions')}',
            style: textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? AppColors.textSecondary : Colors.black54,
            ),
          ),

          // Line chart
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: _buildLineChart(isDarkMode),
            ),
          ),

          // Chart labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final labels = ['Apr 10', 'Apr 18', 'Apr 25', 'May 3', 'May 10'];
              return Text(
                labels[index],
                style: textTheme.bodySmall?.copyWith(
                  color: isDarkMode ? AppColors.textSecondary : Colors.black54,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(bool isDarkMode) {
    // Creating a simple line chart
    return CustomPaint(
      size: const Size(double.infinity, 180),
      painter: LineChartPainter(isDarkMode: isDarkMode),
    );
  }
}
