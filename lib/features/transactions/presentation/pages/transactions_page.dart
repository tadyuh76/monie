import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/authentication/domain/entities/user.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/presentation/bloc/categories_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/categories_event.dart';
import 'package:monie/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:monie/features/transactions/presentation/widgets/add_transaction_form.dart';
import 'package:monie/features/transactions/presentation/widgets/transaction_card.dart';
import 'package:monie/features/transactions/presentation/widgets/transaction_form.dart';
import 'package:monie/core/localization/app_localizations.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  DateTime _selectedMonth = DateTime.now();
  // We don't need the _showSnackBar method anymore as snackbars are handled globally

  @override
  void initState() {
    super.initState();
    // Load transactions for the current month
    _filterByMonth(_selectedMonth);

    // Load categories
    context.read<CategoriesBloc>().add(const LoadCategories());
  }

  void _filterByMonth(DateTime month) {
    context.read<TransactionsBloc>().add(FilterTransactionsByMonth(month));
    setState(() {
      _selectedMonth = month;
    });
  }

  void _filterByType(String? type) {
    context.read<TransactionsBloc>().add(FilterTransactionsByType(type));
    setState(() {});
  }

  void _showAddTransactionSheet(BuildContext context, User user) {
    // Use outer context's bloc
    final transactionsBloc = BlocProvider.of<TransactionsBloc>(context);
    final categoriesBloc = BlocProvider.of<CategoriesBloc>(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return BlocProvider.value(
          value: transactionsBloc,
          child: BlocProvider.value(
            value: categoriesBloc,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: AddTransactionForm(
                onSubmit: (Map<String, dynamic> transaction) {
                  // Dispatch add transaction event using the parent context's bloc
                  transactionsBloc.add(
                    AddNewTransaction(
                      amount: transaction['amount'],
                      description: transaction['description'] ?? '',
                      title: transaction['title'],
                      date: DateTime.parse(transaction['date']),
                      userId: user.id,
                      categoryName: transaction['category_name'],
                      categoryColor: transaction['category_color'],
                      accountId: null,
                      budgetId: null,
                      isIncome: transaction['amount'] >= 0,
                    ),
                  );

                  // Note: We don't need to show a success message or refresh data here
                  // That will be handled by the BlocListener in the page
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditTransactionSheet(
    BuildContext context,
    User user,
    Transaction transaction,
  ) {
    // Get references to the blocs before opening the modal
    final transactionsBloc = BlocProvider.of<TransactionsBloc>(context);
    final categoriesBloc = BlocProvider.of<CategoriesBloc>(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: transactionsBloc),
            BlocProvider.value(value: categoriesBloc),
          ],
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: TransactionForm(userId: user.id, transaction: transaction),
          ),
        );
      },
    );
  }

  void _confirmDeleteTransaction(BuildContext context, String transactionId) {
    // Get reference to the transactions bloc
    final transactionsBloc = BlocProvider.of<TransactionsBloc>(context);

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(context.tr('transactions_delete')),
            content: Text(
              context.tr('transactions_delete_confirm'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.tr('common_cancel')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  // Use the captured bloc reference
                  transactionsBloc.add(
                    DeleteExistingTransaction(transactionId),
                  );
                },
                child: Text(context.tr('common_delete')),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is Authenticated) {
          return _buildScaffold(context, authState.user);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildScaffold(BuildContext context, User user) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          context.tr('transactions_title'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'all') {
                _filterByType(null);
              } else {
                _filterByType(value);
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'all',
                    child: Text(context.tr('transactions_all')),
                  ),
                  PopupMenuItem(
                    value: 'income', 
                    child: Text(context.tr('transactions_income'))
                  ),
                  PopupMenuItem(
                    value: 'expense',
                    child: Text(context.tr('transactions_expense')),
                  ),
                ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: BlocConsumer<TransactionsBloc, TransactionsState>(
        listener: (context, state) {
          if (state is TransactionActionSuccess) {
            // Refresh UI after a successful action
            _filterByMonth(_selectedMonth);
          } else if (state is TransactionsError) {
            // No need to show error, it will be handled globally
          }
        },
        builder: (context, state) {
          if (state is TransactionsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TransactionsLoaded) {
            return _buildContent(context, state, user);
          } else if (state is TransactionsError) {
            return Center(child: Text('${context.tr('common_error')}: ${state.message}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TransactionsLoaded state,
    User user,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthSelector(context),
          _buildSummaryBar(context, state),
          const SizedBox(height: 16),
          _buildTransactionsList(context, state, user),
          const SizedBox(height: 100), // Extra space at the bottom
        ],
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final currentMonth = DateTime.now();
    List<DateTime> months = [];

    // Generate the last 3 months and next 3 months
    for (int i = -3; i <= 3; i++) {
      months.add(DateTime(currentMonth.year, currentMonth.month + i, 1));
    }

    return Container(
      height: 60,
      alignment: Alignment.center,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: months.length,
        itemBuilder: (context, index) {
          final month = months[index];
          final monthName = DateFormat('MMMM').format(month);
          final isSelected =
              month.month == _selectedMonth.month &&
              month.year == _selectedMonth.year;

          return GestureDetector(
            onTap: () => _filterByMonth(month),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    monthName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 24,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryBar(BuildContext context, TransactionsLoaded state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Expense
          Column(
            children: [
              Text(
                '↓ \$${state.totalExpense.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.expense,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('transactions_expense'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),

          // Income
          Column(
            children: [
              Text(
                '↑ \$${state.totalIncome.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.income,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('transactions_income'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),

          // Net
          Column(
            children: [
              Text(
                '= \$${state.netAmount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('transactions_net'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(
    BuildContext context,
    TransactionsLoaded state,
    User user,
  ) {
    final transactions = state.transactions;

    if (transactions.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.receipt_long,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('transactions_no_transactions'),
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _showAddTransactionSheet(context, user),
                child: Text(context.tr('transactions_add_new')),
              ),
            ],
          ),
        ),
      );
    }

    // Group transactions by date
    final Map<String, List<Transaction>> groupedTransactions = {};

    for (var transaction in transactions) {
      final dateString = DateFormat('EEEE, MMMM d').format(transaction.date);
      if (!groupedTransactions.containsKey(dateString)) {
        groupedTransactions[dateString] = [];
      }
      groupedTransactions[dateString]!.add(transaction);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...groupedTransactions.entries.map((entry) {
            final totalForDay = entry.value.fold<double>(
              0,
              (sum, transaction) => sum + transaction.amount,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${totalForDay.toStringAsFixed(0)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...entry.value.map((transaction) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TransactionCard(
                      transaction: transaction,
                      onEdit:
                          () => _showEditTransactionSheet(
                            context,
                            user,
                            transaction,
                          ),
                      onDelete:
                          () => _confirmDeleteTransaction(
                            context,
                            transaction.id,
                          ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }
}
