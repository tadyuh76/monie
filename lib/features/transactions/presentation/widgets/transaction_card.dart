import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/constants/category_icons.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/category_utils.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.amount >= 0;
    final formatter = NumberFormat.currency(symbol: '\$');
    final formattedAmount = formatter.format(transaction.amount.abs());
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Format the category name for display
    final displayCategoryName = _getFormattedCategoryName();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
      color: isDarkMode ? AppColors.surface : Colors.white,
      elevation: isDarkMode ? 2 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: _buildCategoryIcon(),
        title: Text(
          transaction.title.isEmpty ? displayCategoryName : transaction.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (transaction.description != null &&
                transaction.description!.isNotEmpty)
              Text(
                transaction.description!,
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMMMd().format(transaction.date),
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isIncome ? formattedAmount : '- $formattedAmount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isIncome ? AppColors.income : AppColors.expense,
              ),
            ),
            if (onEdit != null || onDelete != null) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                onSelected: (value) {
                  if (value == 'edit' && onEdit != null) {
                    onEdit!();
                  } else if (value == 'delete' && onDelete != null) {
                    onDelete!();
                  }
                },
                itemBuilder:
                    (context) => [
                      if (onEdit != null)
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                size: 20,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete,
                                size: 20,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Get formatted category name for display
  String _getFormattedCategoryName() {
    // Get the raw category name
    String categoryName = transaction.categoryName ?? '';

    // Use our utility to format the category name
    return CategoryUtils.formatCategoryName(categoryName);
  }

  Widget _buildCategoryIcon() {
    // Get the category name
    String categoryName = transaction.categoryName ?? '';

    // Get the icon path for the category
    String iconPath = CategoryIcons.getIconPath(categoryName);

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
    Color backgroundColor = categoryColor.withValues(alpha: 0.2);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SvgPicture.asset(iconPath),
      ),
    );
  }
}
