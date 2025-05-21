import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monie/features/account/presentation/bloc/account_bloc.dart';
import 'package:monie/features/account/presentation/bloc/account_event.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
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

  void _showAddTransactionForm() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder:
            (context) => BlocProvider.value(
              value: BlocProvider.of<BudgetsBloc>(context),
              child: AddTransactionForm(
                onSubmit: (transactionData) {
                  // Create the transaction
                  final transactionBloc = context.read<TransactionBloc>();
                  final accountBloc = context.read<AccountBloc>();
                  final amount = transactionData['amount'] as double;
                  final accountId = transactionData['account_id'] as String?;
                  final budgetId = transactionData['budget_id'] as String?;

                  // First create the transaction
                  transactionBloc.add(
                    CreateTransactionEvent(
                      Transaction(
                        userId: authState.user.id,
                        amount: amount,
                        title: transactionData['title'],
                        date: DateTime.parse(transactionData['date']),
                        description: transactionData['description'],
                        categoryName: transactionData['category_name'],
                        color: transactionData['category_color'],
                        accountId: accountId,
                        budgetId: budgetId,
                      ),
                    ),
                  );

                  // Recalculate the account balance if an account is selected
                  if (accountId != null) {
                    accountBloc.add(RecalculateAccountBalanceEvent(accountId));
                  }

                  Navigator.pop(context);
                  _loadTransactions();
                },
              ),
            ),
      );
    }
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
        const SnackBar(content: Text('Error: Transaction not found')),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text(
              'Are you sure you want to delete this transaction?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
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
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
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
        return Scaffold(
          appBar: AppBar(
            title: const Text('Transactions'),
            actions: [
              PopupMenuButton<String>(
                onSelected: _changeType,
                initialValue: _selectedType,
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(value: 'all', child: Text('All')),
                      const PopupMenuItem(
                        value: 'expense',
                        child: Text('Expenses'),
                      ),
                      const PopupMenuItem(
                        value: 'income',
                        child: Text('Income'),
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
                                (_selectedType == 'expense' && t.amount < 0) ||
                                (_selectedType == 'income' && t.amount >= 0);
                            return isSameMonth && isType;
                          }).toList();
                      if (transactions.isEmpty) {
                        return const Center(
                          child: Text('No transactions found.'),
                        );
                      }
                      return ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return ListTile(
                            title: Text(transaction.title),
                            subtitle: Text(transaction.description ?? ''),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditTransactionForm(transaction);
                                } else if (value == 'delete') {
                                  _confirmDeleteTransaction(
                                    transaction.transactionId,
                                  );
                                }
                              },
                              itemBuilder:
                                  (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
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
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddTransactionForm,
            heroTag: 'transactionAddFab',
            child: const Icon(Icons.add),
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
