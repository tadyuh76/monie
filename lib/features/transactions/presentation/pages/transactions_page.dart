import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/core/widgets/transaction_card_widget.dart';
import 'package:monie/features/account/data/models/account_model.dart';
import 'package:monie/features/account/presentation/bloc/account_bloc.dart';
import 'package:monie/features/account/presentation/bloc/account_event.dart';
import 'package:monie/features/account/presentation/bloc/account_state.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/budgets/data/models/budget_model.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/presentation/bloc/categories_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/categories_event.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:monie/features/transactions/presentation/widgets/add_transaction_form.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _selectedType = 'all'; // 'all', 'expense', 'income'

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    context.read<CategoriesBloc>().add(const LoadCategories());
  }

  void _loadTransactions() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      // By default, load all transactions for the selected month
      _dispatchFilterEvent();
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });
    _dispatchFilterEvent();
  }

  void _changeType(String type) {
    setState(() {
      _selectedType = type;
    });
    _dispatchFilterEvent();
  }

  void _dispatchFilterEvent() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;
    final userId = authState.user.id;
    // Dispatch a filter event with userId, type, and month
    context.read<TransactionBloc>().add(
      FilterTransactionsEvent(
        userId: userId,
        type: _selectedType,
        month: _selectedMonth,
      ),
    );
  }

  void _showEditTransactionForm(Transaction transaction) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder:
            (context) => BlocProvider.value(
              value: BlocProvider.of<BudgetsBloc>(context),
              child: AddTransactionForm(
                transaction: transaction,
                onSubmit: (transactionData) {
                  // Keep track of old and new values
                  final transactionBloc = context.read<TransactionBloc>();
                  final accountBloc = context.read<AccountBloc>();

                  final oldAccountId = transaction.accountId ?? '';
                  final newAccountId = transactionData['account_id'] as String;
                  final budgetId = transactionData['budget_id'] as String?;

                  // First update the transaction
                  transactionBloc.add(
                    UpdateTransactionEvent(
                      transaction.copyWith(
                        amount: transactionData['amount'] as double,
                        title: transactionData['title'],
                        date: DateTime.parse(transactionData['date']),
                        description: transactionData['description'],
                        categoryName: transactionData['category_name'],
                        color: transactionData['category_color'],
                        accountId: newAccountId,
                        budgetId: budgetId,
                      ),
                    ),
                  );

                  // If account changed, recalculate both accounts
                  if (oldAccountId != newAccountId) {
                    // Recalculate old account
                    if (oldAccountId.isNotEmpty) {
                      accountBloc.add(
                        RecalculateAccountBalanceEvent(oldAccountId),
                      );
                    }

                    // Recalculate new account
                    accountBloc.add(
                      RecalculateAccountBalanceEvent(newAccountId),
                    );
                  } else {
                    // Just recalculate the same account
                    accountBloc.add(
                      RecalculateAccountBalanceEvent(newAccountId),
                    );
                  }

                  Navigator.pop(context);
                  _loadTransactions();
                },
              ),
            ),
      );
    }
  }

  void _confirmDeleteTransaction(String transactionId) {
    // First get the transaction to be deleted
    final transactionState = context.read<TransactionBloc>().state;
    Transaction? transactionToDelete;

    if (transactionState is TransactionsLoaded) {
      transactionToDelete = transactionState.transactions.firstWhere(
        (t) => t.transactionId == transactionId,
        orElse: () => throw Exception('Transaction not found'),
      );
    }

    // If we can't find the transaction, don't continue
    if (transactionToDelete == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.tr('transactions_error')}: Transaction not found',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.tr('transactions_delete')),
            content: Text(context.tr('transactions_delete_confirm')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('common_cancel')),
              ),
              TextButton(
                onPressed: () {
                  final transactionBloc = context.read<TransactionBloc>();
                  final accountBloc = context.read<AccountBloc>();
                  final accountId = transactionToDelete?.accountId;

                  // First delete the transaction
                  transactionBloc.add(DeleteTransactionEvent(transactionId));

                  // Recalculate the account balance
                  if (accountId != null) {
                    accountBloc.add(RecalculateAccountBalanceEvent(accountId));
                  }

                  Navigator.pop(context);
                  _loadTransactions();
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Center(child: CircularProgressIndicator());
        }
        return MultiBlocListener(
          listeners: [
            BlocListener<TransactionBloc, TransactionState>(
              listener: (context, state) {
                if (state is TransactionCreated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('transactions_created_success')),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadTransactions();
                } else if (state is TransactionUpdated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('transactions_updated_success')),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadTransactions();
                } else if (state is TransactionDeleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('transactions_deleted_success')),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadTransactions();
                } else if (state is TransactionError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${context.tr('transactions_error')}: ${state.message}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
          child: Scaffold(
            appBar: AppBar(
              title: Text(context.tr('transactions_title')),
              actions: [
                PopupMenuButton<String>(
                  onSelected: _changeType,
                  initialValue: _selectedType,
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'all',
                          child: Text(context.tr('transactions_all')),
                        ),
                        PopupMenuItem(
                          value: 'expense',
                          child: Text(context.tr('transactions_expense')),
                        ),
                        PopupMenuItem(
                          value: 'income',
                          child: Text(context.tr('transactions_income')),
                        ),
                      ],
                  icon: const Icon(Icons.filter_list),
                ),
              ],
            ),
            body: Column(
              children: [
                // Month selector
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<TransactionBloc, TransactionState>(
                    builder: (context, state) {
                      if (state is TransactionLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is TransactionsLoaded) {
                        // Filter by month and type in UI for now
                        final transactions =
                            state.transactions.where((t) {
                              final isSameMonth =
                                  t.date.year == _selectedMonth.year &&
                                  t.date.month == _selectedMonth.month;
                              final isType =
                                  _selectedType == 'all' ||
                                  (_selectedType == 'expense' &&
                                      t.amount < 0) ||
                                  (_selectedType == 'income' && t.amount >= 0);
                              return isSameMonth && isType;
                            }).toList();
                        if (transactions.isEmpty) {
                          return Center(
                            child: Text(
                              context.tr('transactions_no_transactions'),
                            ),
                          );
                        }
                        // Group transactions by date
                        final Map<String, List<Transaction>>
                        groupedTransactions = {};

                        for (var transaction in transactions) {
                          final dateString = Formatters.formatFullDate(
                            transaction.date,
                          );
                          if (!groupedTransactions.containsKey(dateString)) {
                            groupedTransactions[dateString] = [];
                          }
                          groupedTransactions[dateString]!.add(transaction);
                        }

                        // Sort the grouped dates with newest first
                        final sortedDates =
                            groupedTransactions.keys.toList()..sort((a, b) {
                              // Since transactions are already sorted by date,
                              // we can use the first transaction's date in each group for comparison
                              final dateA = groupedTransactions[a]!.first.date;
                              final dateB = groupedTransactions[b]!.first.date;
                              return dateB.compareTo(dateA); // Newest first
                            });

                        return ListView.builder(
                          itemCount: sortedDates.length,
                          itemBuilder: (context, dateIndex) {
                            final dateString = sortedDates[dateIndex];
                            final transactionsForDay =
                                groupedTransactions[dateString]!;
                            final totalForDay = transactionsForDay.fold<double>(
                              0,
                              (sum, transaction) =>
                                  sum +
                                  (transaction.amount < 0
                                      ? -transaction.amount
                                      : transaction.amount),
                            );

                            // Create a list to hold all widgets for this date section
                            List<Widget> sectionWidgets = [];

                            // Add the date header
                            sectionWidgets.add(
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  right: 16.0,
                                  top: 16.0,
                                  bottom: 8.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateString,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.copyWith(
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppColors.textSecondary
                                                : Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      Formatters.formatCurrency(totalForDay),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.copyWith(
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            // Add all transactions for this date
                            for (var transaction in transactionsForDay) {
                              // Get account name if available
                              String? accountName;
                              if (transaction.accountId != null) {
                                final accountState =
                                    context.watch<AccountBloc>().state;
                                if (accountState is AccountsLoaded) {
                                  final account = accountState.accounts
                                      .firstWhere(
                                        (a) =>
                                            a.accountId ==
                                            transaction.accountId,
                                        orElse:
                                            () => AccountModel(
                                              accountId: '',
                                              userId: '',
                                              name: 'Unknown Account',
                                              type: 'Other',
                                            ),
                                      );
                                  accountName = account.name;
                                }
                              }

                              // Get budget name if available
                              String? budgetName;
                              if (transaction.budgetId != null) {
                                final budgetState =
                                    context.watch<BudgetsBloc>().state;
                                if (budgetState is BudgetsLoaded) {
                                  final budget = budgetState.budgets.firstWhere(
                                    (b) => b.budgetId == transaction.budgetId,
                                    orElse:
                                        () => BudgetModel(
                                          budgetId: '',
                                          userId: '',
                                          name: 'Unknown Budget',
                                          amount: 0,
                                          startDate: DateTime.now(),
                                        ),
                                  );
                                  budgetName = budget.name;
                                }
                              }

                              sectionWidgets.add(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 4.0,
                                  ),
                                  child: TransactionCardWidget(
                                    transaction: transaction,
                                    accountName: accountName,
                                    budgetName: budgetName,
                                    onTap:
                                        () => _showEditTransactionForm(
                                          transaction,
                                        ),
                                    onDelete: _confirmDeleteTransaction,
                                    showDate:
                                        false, // Date is shown in the section header
                                  ),
                                ),
                              );
                            }

                            // Return a column with all widgets for this date
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: sectionWidgets,
                            );
                          },
                        );
                      } else if (state is TransactionCreated ||
                          state is TransactionUpdated ||
                          state is TransactionDeleted) {
                        // Show loading indicator while reloading transactions
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is TransactionError) {
                        return Center(child: Text(state.message));
                      }
                      return Center(
                        child: Text(context.tr('transactions_no_transactions')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// class TransactionListItem extends StatelessWidget {
//   final Transaction transaction;
//   final VoidCallback onEdit;
//   final VoidCallback onDelete;

//   const TransactionListItem({
//     super.key,
//     required this.transaction,
//     required this.onEdit,
//     required this.onDelete,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isExpense = transaction.amount < 0;
//     final formattedAmount = NumberFormat.currency(
//       symbol: '\$',
//       decimalDigits: 2,
//     ).format(transaction.amount.abs());

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: ListTile(
//         contentPadding: const EdgeInsets.all(16),
//         title: Text(
//           transaction.title,
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (transaction.description != null &&
//                 transaction.description!.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(top: 4),
//                 child: Text(transaction.description!),
//               ),
//             Padding(
//               padding: const EdgeInsets.only(top: 8),
//               child: Row(
//                 children: [
//                   const Icon(Icons.calendar_today, size: 16),
//                   const SizedBox(width: 4),
//                   Text(DateFormat('MMM d, yyyy').format(transaction.date)),
//                   if (transaction.accountId != null) ...[
//                     const SizedBox(width: 16),
//                     const Icon(Icons.account_balance_wallet, size: 16),
//                     const SizedBox(width: 4),
//                     Text(
//                       'Account ID: ${transaction.accountId!.substring(0, 8)}...',
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               formattedAmount,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: isExpense ? Colors.red : Colors.green,
//                 fontSize: 18,
//               ),
//             ),
//             PopupMenuButton<String>(
//               onSelected: (value) {
//                 if (value == 'edit') {
//                   onEdit();
//                 } else if (value == 'delete') {
//                   onDelete();
//                 }
//               },
//               itemBuilder:
//                   (context) => [
//                     PopupMenuItem(
//                       value: 'edit',
//                       child: Row(
//                         children: [
//                           const Icon(Icons.edit),
//                           const SizedBox(width: 8),
//                           Text(context.tr('edit')),
//                         ],
//                       ),
//                     ),
//                     PopupMenuItem(
//                       value: 'delete',
//                       child: Row(
//                         children: [
//                           const Icon(Icons.delete, color: Colors.red),
//                           const SizedBox(width: 8),
//                           Text(
//                             context.tr('delete'),
//                             style: const TextStyle(color: Colors.red),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
