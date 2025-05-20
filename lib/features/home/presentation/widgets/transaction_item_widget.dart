import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:monie/core/constants/category_icons.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/category_utils.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

class TransactionItemWidget extends StatelessWidget {
  final Transaction transaction;

  const TransactionItemWidget({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isExpense = transaction.amount < 0;
    final colorForType = isExpense ? AppColors.expense : AppColors.income;

    // Get the category name
    final categoryName =
        transaction.categoryName?.toLowerCase().trim() ?? 'other';

    // Get the icon path for the category
    final iconPath = CategoryIcons.getIconPath(categoryName);

    // Get the proper category color
    Color categoryColor;
    if (transaction.color != null) {
      // Use the stored category color if available
      categoryColor = Color(
        int.parse(transaction.color!.substring(1), radix: 16) + 0xFF000000,
      );
    } else {
      // Otherwise, get the color from our mapping
      categoryColor = CategoryUtils.getCategoryColor(categoryName);
    }

    // Create a light background based on the category color
    final backgroundColor = categoryColor.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? .1 : .05),
            blurRadius: isDarkMode ? 4 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Transaction icon with SVG
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: SvgPicture.asset(iconPath),
          ),
          const SizedBox(width: 16),

          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title.isEmpty
                      ? transaction.categoryName ?? 'Other'
                      : transaction.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description ?? '',
                  style: textTheme.bodySmall?.copyWith(
                    color:
                        isDarkMode ? AppColors.textSecondary : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Amount
          Text(
            isExpense
                ? '-${Formatters.formatCurrency(transaction.amount.abs())}'
                : Formatters.formatCurrency(transaction.amount),
            style: textTheme.titleMedium?.copyWith(
              color: colorForType,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
