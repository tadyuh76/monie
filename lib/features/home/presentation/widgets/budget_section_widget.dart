import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/core/localization/app_localizations.dart';

class BudgetSectionWidget extends StatelessWidget {
  final Budget budget;

  const BudgetSectionWidget({super.key, required this.budget});

  // Format số tiền lớn theo cách dễ đọc hơn
  String _formatLargeAmount(double amount) {
    if (amount >= 1000000000) {
      // Tỷ
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      // Triệu
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      // Nghìn
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Chuyển đổi màu từ chuỗi hexadecimal sang Color
    Color budgetColor;
    if (budget.color != null && budget.color!.isNotEmpty) {
      try {
        // Cắt bỏ # nếu có và chuyển đổi sang số nguyên với 0xFF làm prefix
        final colorValue = int.parse(
          '0xFF${budget.color!.replaceFirst('#', '')}',
        );
        budgetColor = Color(colorValue);
      } catch (e) {
        // Nếu có lỗi, sử dụng màu mặc định
        budgetColor =
            isDarkMode ? AppColors.budgetBackground : const Color(0xFF4CAF50);
      }
    } else {
      // Nếu không có màu, sử dụng màu mặc định
      budgetColor =
          isDarkMode ? AppColors.budgetBackground : const Color(0xFF4CAF50);
    }

    // Định dạng số tiền để hiển thị phù hợp với không gian
    final bool isLargeAmount = budget.totalAmount > 100000;
    String amountText;

    if (isLargeAmount) {
      amountText =
          '\$${_formatLargeAmount(budget.remainingAmount)} left of \$${_formatLargeAmount(budget.totalAmount)}';
    } else {
      amountText =
          '${Formatters.formatCurrency(budget.remainingAmount)} left of ${Formatters.formatCurrency(budget.totalAmount)}';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: budgetColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            !isDarkMode
                ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
                : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Giảm thiểu kích thước theo chiều dọc
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            budget.name,
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis, // Cắt ngắn nếu tên quá dài
          ),
          const SizedBox(height: 4),
          Text(
            amountText,
            style: textTheme.titleLarge?.copyWith(color: Colors.white),
            overflow: TextOverflow.ellipsis, // Cắt ngắn nếu text quá dài
          ),
          const SizedBox(height: 16),

          // Progress indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: budget.progressPercentage / 100,
              backgroundColor: Colors.black26,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.8),
              ),
              minHeight: 12,
            ),
          ),

          // Date range
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatShortDate(budget.startDate),
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
                      color: budgetColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  Formatters.formatShortDate(budget.endDate),
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),

          // Saving target - Dùng FittedBox để đảm bảo văn bản luôn vừa với không gian
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              context
                  .tr('budget_saving_target')
                  .replaceAll(
                    '{amount}',
                    isLargeAmount
                        ? '\$${_formatLargeAmount(budget.dailySavingTarget)}'
                        : Formatters.formatCurrency(budget.dailySavingTarget),
                  )
                  .replaceAll('{days}', '${budget.daysRemaining}'),
              style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
