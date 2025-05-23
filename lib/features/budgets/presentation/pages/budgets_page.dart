import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:monie/features/budgets/presentation/widgets/budget_card.dart';
import 'package:monie/features/budgets/presentation/widgets/budget_form.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  bool _showActiveOnly = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  void _loadBudgets() {
    if (_showActiveOnly) {
      context.read<BudgetsBloc>().add(const LoadActiveBudgets());
    } else {
      context.read<BudgetsBloc>().add(const LoadBudgets());
    }
  }

  void _showAddBudgetForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BudgetForm(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showEditBudgetForm(Budget budget) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BudgetForm(budget: budget),
        fullscreenDialog: true,
      ),
    );
  }

  void _confirmDeleteBudget(Budget budget) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.tr('budget_delete_title')),
            content: Text(
              context
                  .tr('budget_delete_confirmation')
                  .replaceAll('{name}', budget.name),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('common_cancel')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<BudgetsBloc>().add(
                    DeleteBudget(budget.budgetId),
                  );
                },
                child: Text(
                  context.tr('common_delete'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  // Helper method to format display text without underscores
  String _formatDisplayText(String text) {
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
  String _trDisplay(String key) {
    String translated = context.tr(key);
    // If translation failed (key is returned), format the key for display
    if (translated == key) {
      return _formatDisplayText(key);
    }
    return translated;
  }

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
          context.tr('budgets_title'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Toggle between active and all budgets
          IconButton(
            icon: Icon(
              _showActiveOnly ? Icons.filter_list : Icons.filter_list_off,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              setState(() {
                _showActiveOnly = !_showActiveOnly;
                _loadBudgets();
              });
            },
            tooltip:
                _showActiveOnly
                    ? context.tr('budget_show_all')
                    : context.tr('budget_show_active'),
          ),
        ],
      ),
      body: BlocConsumer<BudgetsBloc, BudgetsState>(
        listener: (context, state) {
          if (state is BudgetsError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is BudgetsInitial) {
            _loadBudgets();
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BudgetsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BudgetsLoaded) {
            final budgets = state.budgets;

            if (budgets.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadBudgets();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Budget summary
                  _buildBudgetSummary(state),
                  const SizedBox(height: 24),

                  // Budget list
                  ...budgets.map(
                    (budget) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: BudgetCard(
                        budget: budget,
                        onTap: () => _showEditBudgetForm(budget),
                        onEdit: () => _showEditBudgetForm(budget),
                        onDelete: () => _confirmDeleteBudget(budget),
                      ),
                    ),
                  ),

                  // Add budget button
                  _buildAddBudgetButton(context),
                ],
              ),
            );
          }

          return _buildEmptyState();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBudgetForm,
        backgroundColor: AppColors.primary,
        heroTag: 'budgetAddFab',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBudgetSummary(BudgetsLoaded state) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDarkMode ? AppColors.surface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _trDisplay('budget_summary'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Total budgeted amount
            _buildSummaryItem(
              context,
              _trDisplay('budget_total_budgeted'),
              '\$${state.totalBudgeted.toStringAsFixed(2)}',
              AppColors.primary,
            ),

            // Total spent amount
            _buildSummaryItem(
              context,
              _trDisplay('budget_total_spent'),
              '\$${state.totalSpent.toStringAsFixed(2)}',
              AppColors.expense,
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(
                color: isDarkMode ? AppColors.divider : Colors.grey.shade300,
              ),
            ),

            // Total remaining
            _buildSummaryItem(
              context,
              _trDisplay('budget_total_remaining'),
              '\$${state.totalRemaining.toStringAsFixed(2)}',
              state.totalRemaining >= 0 ? AppColors.income : AppColors.expense,
              isLarge: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    Color valueColor, {
    bool isLarge = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: (isLarge
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.bodyLarge)
                ?.copyWith(
                  color: valueColor,
                  fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: isDarkMode ? Colors.white38 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _showActiveOnly
                ? _trDisplay('budget_no_active_budgets')
                : _trDisplay('budget_no_budgets'),
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddBudgetForm,
            icon: const Icon(Icons.add),
            label: Text(_trDisplay('budget_create')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBudgetButton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context);
    final isVietnamese = locale.languageCode == 'vi';

    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 80),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.divider : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow:
            isDarkMode
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: InkWell(
        onTap: _showAddBudgetForm,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                isVietnamese ? "Thêm ngân sách mới" : "Add New Budget",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
