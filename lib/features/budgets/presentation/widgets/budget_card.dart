import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_state.dart';

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

  // Helper method to format display text without underscores
  String _formatDisplayText(BuildContext context, String text) {
    if (text.contains('_')) {
      List<String> words = text.split('_');
      return words
          .map(
            (word) =>
                word.isNotEmpty
                    ? '${word[0].toUpperCase()}${word.substring(1)}'
                    : '',
          )
          .join(' ');
    }
    return text;
  }

  // Helper method to translate text and remove underscores for display
  String _trDisplay(BuildContext context, String key) {
    String translated = context.tr(key);
    // If translation failed (key is returned), format the key for display
    if (translated == key) {
      return _formatDisplayText(context, key);
    }
    return translated;
  }

  // Helper method to safely parse color from hex string
  Color _parseColor(String? colorHex, Color defaultColor) {
    if (colorHex == null || colorHex.isEmpty) {
      return defaultColor;
    }

    try {
      // Remove # prefix if present
      final cleanHex =
          colorHex.startsWith('#') ? colorHex.substring(1) : colorHex;
      return Color(int.parse('0xFF$cleanHex'));
    } catch (e) {
      return defaultColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Parse color from hex string or use default
    Color budgetColor;
    try {
      if (budget.color != null) {
        budgetColor = _parseColor(
          budget.color,
          isDarkMode ? AppColors.primary : const Color(0xFF4CAF50),
        );
      } else {
        budgetColor = isDarkMode ? AppColors.primary : const Color(0xFF4CAF50);
      }
    } catch (e) {
      budgetColor = isDarkMode ? AppColors.primary : const Color(0xFF4CAF50);
    }

    // Get spent amount and calculate percentage
    final progress = budget.progressPercentage;
    final progressPercentage = (progress * 100).toInt();

    // Determine color based on progress for text
    final progressTextColor =
        budget.isIncome
            ? progress >= 0.8
                ? Colors.green
                : progress >= 0.5
                ? Colors.orange
                : Colors.red
            : progress >= 0.8
            ? Colors.red
            : progress >= 0.5
            ? Colors.orange
            : Colors.green;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? AppColors.surface : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored header
            Container(
              decoration: BoxDecoration(
                color: budgetColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      budget.name,
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Budget type indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          budget.isIncome
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          budget.isIncome
                              ? context.tr('home_income')
                              : context.tr('home_expense'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: isDarkMode ? AppColors.surface : Colors.white,
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
                                    const Icon(Icons.edit, size: 18),
                                    const SizedBox(width: 8),
                                    Text(_trDisplay(context, 'common_edit')),
                                  ],
                                ),
                              ),
                            if (onDelete != null)
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _trDisplay(context, 'common_delete'),
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                    ),
                ],
              ),
            ),

            // Body content with white/dark background
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amounts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Spent amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _trDisplay(context, 'budget_spent'),
                            style: textTheme.bodySmall?.copyWith(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          Text(
                            budget.formattedSpentAmount,
                            style: textTheme.titleMedium?.copyWith(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Remaining amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _trDisplay(context, 'budget_remaining'),
                            style: textTheme.bodySmall?.copyWith(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          Text(
                            budget.formattedRemainingAmount,
                            style: textTheme.titleMedium?.copyWith(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${budget.formattedSpentAmount} ${context.tr('budgets_left_of')} ${budget.formattedAmount}',
                            style: textTheme.bodySmall?.copyWith(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          Text(
                            '$progressPercentage%',
                            style: textTheme.bodyMedium?.copyWith(
                              color: progressTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          // Background
                          Container(
                            width: double.infinity,
                            height: 10,
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? Colors.black26
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          // Progress
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: budgetColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Date range and days remaining
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _formatDateRange(
                              context,
                              budget.startDate,
                              budget.endDate,
                            ),
                            style: textTheme.bodySmall?.copyWith(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                        if (budget.endDate != null)
                          Text(
                            _formatDaysRemaining(context, budget.endDate),
                            style: textTheme.bodySmall?.copyWith(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to format date
  String _formatDate(BuildContext context, DateTime date) {
    final format = DateFormat('MMM d, yyyy');
    return format.format(date);
  }

  // Helper to format date range
  String _formatDateRange(BuildContext context, DateTime start, DateTime? end) {
    if (end == null) return _formatDate(context, start);

    final startFormat = DateFormat('MMM d');
    final endFormat = DateFormat('MMM d, yyyy');

    return context
        .tr('budget_date_range_display')
        .replaceAll('{start}', startFormat.format(start))
        .replaceAll('{end}', endFormat.format(end));
  }

  // Helper to calculate days remaining
  String _formatDaysRemaining(BuildContext context, DateTime? endDate) {
    if (endDate == null) return '';

    final daysRemaining = endDate.difference(DateTime.now()).inDays;
    if (daysRemaining < 0) return '';

    return context
        .tr('budget_days_remaining')
        .replaceAll('{days}', daysRemaining.toString());
  }
}

class _BudgetTransactionsModal extends StatefulWidget {
  final Budget budget;

  const _BudgetTransactionsModal({required this.budget});

  @override
  State<_BudgetTransactionsModal> createState() =>
      _BudgetTransactionsModalState();
}

class _BudgetTransactionsModalState extends State<_BudgetTransactionsModal> {
  @override
  void initState() {
    super.initState();
    // Load transactions for this budget
    context.read<TransactionBloc>().add(
      LoadTransactionsByBudgetEvent(widget.budget.budgetId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.background : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.budget.name} ${context.tr('home_transactions')}',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            // Budget summary
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _parseColor(widget.budget.color, AppColors.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('budget_spent'),
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        widget.budget.formattedSpentAmount,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        context.tr('budget_remaining'),
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        widget.budget.formattedRemainingAmount,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value:
                    widget.budget.amount > 0
                        ? ((widget.budget.spent ?? 0) / widget.budget.amount)
                            .clamp(0.0, 1.0)
                        : 0.0,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _parseColor(widget.budget.color, AppColors.primary),
                ),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 16),

            // Transactions list
            Expanded(
              child: BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  if (state is TransactionLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TransactionsLoaded) {
                    final transactions =
                        state.transactions
                            .where((t) => t.budgetId == widget.budget.budgetId)
                            .toList();

                    if (transactions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color:
                                  isDarkMode
                                      ? Colors.white30
                                      : Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.tr('transactions_no_transactions'),
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.white70
                                        : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        final isExpense = transaction.amount < 0;

                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _parseColor(
                                transaction.color,
                                const Color(0xFF9E9E9E),
                              ).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isExpense
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: _parseColor(
                                transaction.color,
                                const Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                          title: Text(transaction.title),
                          subtitle: Text(
                            DateFormat('MMM d, yyyy').format(transaction.date),
                          ),
                          trailing: Text(
                            '\$${transaction.amount.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isExpense ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    );
                  } else if (state is TransactionError) {
                    return Center(child: Text(state.message));
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to safely parse color from hex string
  Color _parseColor(String? colorHex, Color defaultColor) {
    if (colorHex == null || colorHex.isEmpty) {
      return defaultColor;
    }

    try {
      // Remove # prefix if present
      final cleanHex =
          colorHex.startsWith('#') ? colorHex.substring(1) : colorHex;
      return Color(int.parse('0xFF$cleanHex'));
    } catch (e) {
      return defaultColor;
    }
  }
}
