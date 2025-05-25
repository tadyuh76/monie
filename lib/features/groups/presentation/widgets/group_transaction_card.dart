import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:monie/core/constants/category_icons.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/category_utils.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/groups/domain/entities/group_transaction.dart';

class GroupTransactionCard extends StatelessWidget {
  final GroupTransaction transaction;
  final String? paidByName; // Display name of the person who paid
  final VoidCallback? onTap;
  final Function(String, bool)? onApprove; // Function to approve/reject
  final bool showApprovalButtons;
  final String? categoryName; // Optional category name override

  const GroupTransactionCard({
    super.key,
    required this.transaction,
    this.paidByName,
    this.onTap,
    this.onApprove,
    this.showApprovalButtons = false,
    this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determine if this is an income transaction based on amount sign
    final bool isIncome = transaction.amount > 0;
    final colorForType = isIncome ? AppColors.income : AppColors.expense;

    // Get the category name from the transaction or use default
    final actualCategoryName = categoryName ?? 'Group';

    // Get the icon path for the category
    final iconPath = CategoryIcons.getIconPath(
      actualCategoryName.toLowerCase(),
    );

    // Get the proper category color
    Color categoryColor = CategoryUtils.getCategoryColor(actualCategoryName);

    // Create a light background based on the category color
    final backgroundColor = categoryColor.withValues(alpha: 0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.1 : 0.05),
            blurRadius: isDarkMode ? 4 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main card content
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
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
                              ? actualCategoryName
                              : transaction.title,
                          style: textTheme.titleMedium?.copyWith(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (paidByName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 14,
                                  color:
                                      isDarkMode
                                          ? AppColors.textSecondary
                                          : Colors.black54,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  paidByName ?? '',
                                  style: textTheme.bodySmall?.copyWith(
                                    color:
                                        isDarkMode
                                            ? AppColors.textSecondary
                                            : Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isIncome
                            ? '+${Formatters.formatCurrency(transaction.amount)}'
                            : Formatters.formatCurrency(transaction.amount),
                        style: textTheme.titleMedium?.copyWith(
                          color: colorForType,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(context, transaction.approvalStatus),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Description if available
          if (transaction.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                transaction.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppColors.textSecondary : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Approval buttons if transaction is pending and showApprovalButtons is true
          if (showApprovalButtons && transaction.approvalStatus == 'pending')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Reject button
                  OutlinedButton(
                    onPressed: () => onApprove?.call(transaction.id, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(context.tr('groups_reject')),
                  ),
                  const SizedBox(width: 12),
                  // Approve button
                  ElevatedButton(
                    onPressed: () => onApprove?.call(transaction.id, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(context.tr('groups_approve')),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color badgeColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'approved':
        badgeColor = Colors.green;
        statusText = context.tr('groups_approved');
        break;
      case 'rejected':
        badgeColor = Colors.red;
        statusText = context.tr('groups_rejected');
        break;
      case 'pending':
        badgeColor = Colors.orange;
        statusText = context.tr('groups_pending');
        break;
      case 'settled':
        badgeColor = Colors.blue;
        statusText = context.tr('groups_settled');
        break;
      default:
        badgeColor = Colors.grey;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
