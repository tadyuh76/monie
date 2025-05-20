import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';

class BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  
  const BudgetCard({
    super.key,
    required this.budget,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Parse color from hex string or use default
    Color cardColor;
    try {
      if (budget.color != null) {
        cardColor = Color(int.parse('0x${budget.color}'));
      } else {
        cardColor = isDarkMode ? AppColors.budgetBackground : const Color(0xFF4CAF50);
      }
    } catch (e) {
      cardColor = isDarkMode ? AppColors.budgetBackground : const Color(0xFF4CAF50);
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      budget.name,
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (value == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit, size: 18),
                                const SizedBox(width: 8),
                                Text(context.tr('common_edit')),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete, size: 18, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('common_delete'),
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '\$${budget.remainingAmount.toStringAsFixed(2)} ${context.tr('budgets_left_of')} \$${budget.totalAmount.toStringAsFixed(2)}',
                style: textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Progress indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${budget.progressPercentage.toStringAsFixed(1)}%',
                        style: textTheme.bodyMedium?.copyWith(color: Colors.white),
                      ),
                      Text(
                        '100%',
                        style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: budget.progressPercentage / 100,
                      backgroundColor: Colors.black26,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDarkMode ? AppColors.budgetProgress : Colors.white.withOpacity(0.9),
                      ),
                      minHeight: 12,
                    ),
                  ),
                ],
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
                    _buildDateIndicator(context, budget),
                    Text(
                      DateFormat('MMM d').format(budget.endDate),
                      style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Budget tags
              Wrap(
                spacing: 8,
                children: [
                  if (budget.isRecurring)
                    _buildTag(
                      context,
                      context.tr('budget_recurring'),
                      Icons.repeat,
                    ),
                  if (budget.isSaving)
                    _buildTag(
                      context,
                      context.tr('budget_saving'),
                      Icons.savings,
                    ),
                ],
              ),

              // Saving target
              if (budget.daysRemaining > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    context.tr('budget_saving_target')
                      .replaceAll('{amount}', '\$${budget.dailySavingTarget.toStringAsFixed(2)}')
                      .replaceAll('{days}', '${budget.daysRemaining}'),
                    style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDateIndicator(BuildContext context, Budget budget) {
    final now = DateTime.now();
    final isActive = now.isAfter(budget.startDate) && now.isBefore(budget.endDate);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isActive 
            ? context.tr('common_today')
            : now.isBefore(budget.startDate)
                ? context.tr('budget_upcoming')
                : context.tr('budget_ended'),
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark 
              ? AppColors.background 
              : const Color(0xFF388E3C),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
  
  Widget _buildTag(BuildContext context, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 