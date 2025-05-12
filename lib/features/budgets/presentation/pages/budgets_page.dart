import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/mock_data.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Budgets',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBudgetCard(context, MockData.budgets.first),
          const SizedBox(height: 24),
          _buildEmptyBudgetCard(context),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, Budget budget) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.budgetBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            budget.name,
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${budget.remainingAmount} left of \$${budget.totalAmount}',
            style: textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),

          // Progress indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: budget.progressPercentage / 100,
              backgroundColor: Colors.black26,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.budgetProgress,
              ),
              minHeight: 12,
            ),
          ),

          // Date range
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d').format(budget.startDate),
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Today',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.background,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMM d').format(budget.endDate),
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),

          // Saving target
          Text(
            'You should save \$${budget.dailySavingTarget.toStringAsFixed(2)}/day for ${budget.daysRemaining} more days',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBudgetCard(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Center(
        child: Icon(Icons.add, color: AppColors.textSecondary, size: 36),
      ),
    );
  }
}
