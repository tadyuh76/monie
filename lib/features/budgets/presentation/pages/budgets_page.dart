import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/mock_data.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/core/localization/app_localizations.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.background : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.background : Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Text(
              context.tr('budgets_title'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.edit, color: isDarkMode ? Colors.white : Colors.black87),
              onPressed: () {}
            ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.budgetBackground : const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
            '\$${budget.remainingAmount} ${context.tr('budgets_left_of')} \$${budget.totalAmount}',
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
                isDarkMode ? AppColors.budgetProgress : const Color(0xFF388E3C),
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
                    context.tr('common_today'),
                    style: textTheme.bodySmall?.copyWith(
                      color: isDarkMode ? AppColors.background : const Color(0xFF388E3C),
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
            context.tr('budget_saving_target')
              .replaceAll('{amount}', '\$${budget.dailySavingTarget.toStringAsFixed(2)}')
              .replaceAll('{days}', '${budget.daysRemaining}'),
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBudgetCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.divider : Colors.grey.shade300, 
          width: 1
        ),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.add, 
          color: isDarkMode ? AppColors.textSecondary : Colors.grey.shade500, 
          size: 36
        ),
      ),
    );
  }
}
