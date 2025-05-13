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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('home_net_worth'),
            style: textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatCurrency(netWorth),
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$transactionsCount ${context.tr('home_transactions')}',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          // Line chart
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: _buildLineChart(),
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
                  color: AppColors.textSecondary,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    // Creating a simple line chart
    return CustomPaint(
      size: const Size(double.infinity, 180),
      painter: LineChartPainter(),
    );
  }
}
