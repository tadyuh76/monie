import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/budgets/data/models/budget_model.dart';
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
    Color cardColor;
    try {
      if (budget.color != null) {
        cardColor = _parseColor(
          budget.color,
          isDarkMode ? AppColors.budgetBackground : const Color(0xFF4CAF50),
        );
      } else {
        cardColor =
            isDarkMode ? AppColors.budgetBackground : const Color(0xFF4CAF50);
      }
    } catch (e) {
      cardColor =
          isDarkMode ? AppColors.budgetBackground : const Color(0xFF4CAF50);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              const SizedBox(height: 4),
              Text(
                '\$${budget.remainingAmount.toStringAsFixed(2)} ${_trDisplay(context, 'budgets_left_of')} \$${budget.amount.toStringAsFixed(2)}',
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
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '100%',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
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
                        isDarkMode
                            ? AppColors.budgetProgress
                            : Colors.white.withValues(alpha: 0.9),
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
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    _buildDateIndicator(context, budget),
                    Text(
                      DateFormat('MMM d').format(budget.effectiveEndDate),
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
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
                      _trDisplay(context, 'budget_recurring'),
                      Icons.repeat,
                    ),
                  if (budget.isSaving)
                    _buildTag(
                      context,
                      _trDisplay(context, 'budget_saving'),
                      Icons.savings,
                    ),
                ],
              ),

              // Saving target
              if (budget.daysRemaining > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _trDisplay(context, 'budget_saving_target')
                        .replaceAll(
                          '{amount}',
                          '\$${budget.dailySavingTarget.toStringAsFixed(2)}',
                        )
                        .replaceAll('{days}', '${budget.daysRemaining}'),
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),

              // View transactions button
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextButton.icon(
                  onPressed: () {
                    // Show transactions modal
                    _showBudgetTransactions(context);
                  },
                  icon: const Icon(Icons.receipt_long, color: Colors.white),
                  label: Text(
                    _trDisplay(context, 'budget_view_transactions'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBudgetTransactions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BudgetTransactionsModal(budget: budget),
    );
  }

  Widget _buildDateIndicator(BuildContext context, Budget budget) {
    final now = DateTime.now();
    final isActive =
        now.isAfter(budget.startDate) && now.isBefore(budget.effectiveEndDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isActive
            ? _trDisplay(context, 'common_today')
            : now.isBefore(budget.startDate)
            ? _trDisplay(context, 'budget_upcoming')
            : _trDisplay(context, 'budget_ended'),
        style: TextStyle(
          color:
              Theme.of(context).brightness == Brightness.dark
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
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
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
                  '${widget.budget.name} Transactions',
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
                        'Spent',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        '\$${widget.budget.spentAmount.toStringAsFixed(2)}',
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
                        'Remaining',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        '\$${widget.budget.remainingAmount.toStringAsFixed(2)}',
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
                value: widget.budget.progressPercentage / 100,
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
                              'No transactions for this budget yet',
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
