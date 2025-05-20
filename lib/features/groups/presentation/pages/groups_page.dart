import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/mock_data.dart';
import 'package:monie/features/groups/domain/entities/expense_group.dart';
import 'package:monie/core/localization/app_localizations.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode
              ? AppColors.background
              : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            isDarkMode
                ? AppColors.background
                : Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          context.tr('groups_title'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGroupsOverview(context),
          const SizedBox(height: 24),
          ..._buildGroupsList(context),
        ],
      ),
    );
  }

  Widget _buildGroupsOverview(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groups = MockData.expenseGroups;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final totalAmount = groups.fold<double>(
      0,
      (sum, group) => sum + group.totalAmount,
    );

    final activeAmount = groups
        .where((g) => !g.isSettled)
        .fold<double>(0, (sum, group) => sum + group.totalAmount);

    final settledAmount = groups
        .where((g) => g.isSettled)
        .fold<double>(0, (sum, group) => sum + group.totalAmount);

    return Container(
      padding: const EdgeInsets.all(16),
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
            context.tr('groups_total_shared_expenses'),
            style: textTheme.titleLarge?.copyWith(
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${totalAmount.toStringAsFixed(0)}',
            style: textTheme.headlineMedium?.copyWith(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "${context.tr('groups_active')}: \$${activeAmount.toStringAsFixed(0)}",
                style: textTheme.bodyMedium?.copyWith(
                  color:
                      isDarkMode
                          ? AppColors.textSecondary
                          : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color:
                      isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "${context.tr('groups_settled')}: \$${settledAmount.toStringAsFixed(0)}",
                style: textTheme.bodyMedium?.copyWith(
                  color:
                      isDarkMode
                          ? AppColors.textSecondary
                          : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupsList(BuildContext context) {
    final groups = MockData.expenseGroups;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          context.tr('groups_your_groups'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ...groups.map(
        (group) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildGroupCard(context, group),
        ),
      ),

      // Add empty group card as the last item
      _buildEmptyGroupCard(context),
    ];
  }

  Widget _buildGroupCard(BuildContext context, ExpenseGroup group) {
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            group.isSettled
                ? Border.all(
                  color:
                      isDarkMode
                          ? AppColors.textSecondary
                          : Colors.grey.shade400,
                  width: 1,
                )
                : null,
        boxShadow:
            !isDarkMode && !group.isSettled
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: textTheme.titleLarge?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (group.isSettled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isDarkMode
                            ? AppColors.textSecondary
                            : Colors.grey.shade400)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    context.tr('groups_settled'),
                    style: textTheme.bodySmall?.copyWith(
                      color:
                          isDarkMode
                              ? AppColors.textSecondary
                              : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${context.tr('groups_total')}: \$${group.totalAmount.toStringAsFixed(0)}',
            style: textTheme.titleMedium?.copyWith(
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${context.tr('groups_created')}: ${DateFormat('MMM d, yyyy').format(group.createdAt)}',
            style: textTheme.bodyMedium?.copyWith(
              color:
                  isDarkMode ? AppColors.textSecondary : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          // Members
          Text(
            '${context.tr('groups_members')} (${group.members.length})',
            style: textTheme.titleSmall?.copyWith(
              color:
                  isDarkMode ? AppColors.textSecondary : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                group.members.map((member) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode ? AppColors.surface : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      member,
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
          ),

          if (!group.isSettled) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                    side: BorderSide(
                      color: isDarkMode ? Colors.white30 : Colors.grey.shade400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(context.tr('groups_view_details')),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(context.tr('groups_add_expense')),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyGroupCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.divider : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow:
            !isDarkMode
                ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_add,
            size: 48,
            color: isDarkMode ? Colors.white54 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('groups_create_new'),
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
