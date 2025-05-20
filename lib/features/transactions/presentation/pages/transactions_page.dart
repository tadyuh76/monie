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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surface : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: isDarkMode ? null : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.surface : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: isDarkMode ? null : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.background : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.background : Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          context.tr('transactions_title'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: isDarkMode ? Colors.white : Colors.black87,
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
            icon: Icon(
              Icons.filter_list,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All'),
              ),
              const PopupMenuItem(
                value: 'expense',
                child: Text('Expenses'),
              ),
              const PopupMenuItem(
                value: 'income',
                child: Text('Income'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(context),
          Expanded(
            child: BlocBuilder<TransactionsBloc, TransactionsState>(
              builder: (context, state) {
                if (state is TransactionsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is TransactionsLoaded) {
                  if (state.transactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: isDarkMode ? Colors.white30 : Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('transactions_empty'),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: state.transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = state.transactions[index];
                      
                      return TransactionCard(
                        transaction: transaction,
                        onEdit: () => _showEditTransactionSheet(
                          context,
                          user,
                          transaction,
                        ),
                        onDelete: () => _confirmDeleteTransaction(
                          context,
                          transaction.id,
                        ),
                      );
                    },
                  );
                } else if (state is TransactionsError) {
                  return Center(
                    child: Text(
                      'Error: ${state.message}',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  );
                }
                
                return const Center(child: Text('No transactions found'));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionSheet(context, user),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final currentMonth = DateFormat('MMMM yyyy').format(_selectedMonth);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surface : Colors.white,
        boxShadow: isDarkMode 
          ? null 
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left, 
              color: isDarkMode ? Colors.white : Colors.black87
            ),
            onPressed: () {
              final previousMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month - 1,
                1,
              );
              _filterByMonth(previousMonth);
            },
          ),
          Text(
            currentMonth,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right, 
              color: isDarkMode ? Colors.white : Colors.black87
            ),
            onPressed: () {
              final nextMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month + 1,
                1,
              );
              _filterByMonth(nextMonth);
            },
          ),
        ],
      ),
    );
  }
}
