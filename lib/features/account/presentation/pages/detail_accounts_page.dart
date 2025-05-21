import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/account/presentation/pages/account_form_modal.dart';
import 'package:monie/features/home/domain/entities/account.dart';
import 'package:monie/features/transactions/domain/entities/account.dart'
    as transaction_account;
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/presentation/bloc/account_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/account_event.dart';
import 'package:monie/features/transactions/presentation/bloc/account_state.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_state.dart';

class DetailAccountsPage extends StatefulWidget {
  final Account account;
  final List<Transaction> transactions;

  const DetailAccountsPage({
    super.key,
    required this.account,
    required this.transactions,
  });

  @override
  State<DetailAccountsPage> createState() => _DetailAccountsPageState();
}

class _DetailAccountsPageState extends State<DetailAccountsPage> {
  Account get account => _updatedAccount ?? widget.account;
  List<Transaction> get allTransactions => widget.transactions;

  List<Transaction> _filteredTransactions = [];

  // Time filter options
  final List<String> _timeFilters = ['All Time', 'This Month', 'This Week'];
  String _selectedTimeFilter = 'All Time';

  // Transaction type filter (for pie chart)
  bool _showingExpenses = true;

  Account? _updatedAccount;

  @override
  void initState() {
    super.initState();
    _applyFilters();

    // If account ID is available, load the latest transactions for this account
    if (account.accountId != null) {
      try {
        // Get the latest transactions for this account
        final transactionBloc = context.read<TransactionBloc>();
        transactionBloc.add(LoadTransactionsByAccountEvent(account.accountId!));
      } catch (e) {
        // Bloc might be closed, ignore the error
      }

      try {
        // Also recalculate the account balance to ensure it's correct
        final accountBloc = context.read<AccountBloc>();
        accountBloc.add(RecalculateAccountBalanceEvent(account.accountId!));
      } catch (e) {
        // Bloc might be closed, ignore the error
      }
    }
  }

  void _applyFilters() {
    final now = DateTime.now();

    // Filter transactions by time period
    if (_selectedTimeFilter == 'This Week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );

      _filteredTransactions =
          allTransactions
              .where(
                (tx) =>
                    tx.date.isAfter(startDate) ||
                    tx.date.isAtSameMomentAs(startDate),
              )
              .toList();
    } else if (_selectedTimeFilter == 'This Month') {
      final startDate = DateTime(now.year, now.month, 1);

      _filteredTransactions =
          allTransactions
              .where(
                (tx) =>
                    tx.date.isAfter(startDate) ||
                    tx.date.isAtSameMomentAs(startDate),
              )
              .toList();
    } else {
      // All Time
      _filteredTransactions = List.from(allTransactions);
    }

    setState(() {});
  }

  double get totalExpense {
    return _filteredTransactions
        .where((tx) => tx.amount < 0)
        .fold(0, (sum, tx) => sum + tx.amount.abs());
  }

  double get totalIncome {
    return _filteredTransactions
        .where((tx) => tx.amount > 0)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  // Group transactions by category for the pie chart
  List<Map<String, dynamic>> get categoryData {
    final Map<String, double> categorySums = {};
    final Map<String, Color> categoryColors = {};

    // Get transactions based on the current view (expenses or income)
    final relevantTransactions =
        _filteredTransactions
            .where((tx) => _showingExpenses ? tx.amount < 0 : tx.amount > 0)
            .toList();

    // Sum up amounts by category
    for (final tx in relevantTransactions) {
      final category = tx.categoryName ?? 'Uncategorized';
      final amount = _showingExpenses ? tx.amount.abs() : tx.amount;

      if (categorySums.containsKey(category)) {
        categorySums[category] = categorySums[category]! + amount;
      } else {
        categorySums[category] = amount;

        // Assign colors to categories
        if (tx.color != null) {
          final colorHex = int.parse(tx.color!.replaceAll('#', '0xFF'));
          categoryColors[category] = Color(colorHex);
        } else {
          // Default fallback colors if no color is specified
          final defaultColors = [
            AppColors.expense,
            AppColors.income,
            Colors.purple,
            Colors.amber,
            Colors.teal,
            Colors.indigo,
            Colors.orange,
          ];

          categoryColors[category] =
              defaultColors[categorySums.keys.toList().indexOf(category) %
                  defaultColors.length];
        }
      }
    }

    // Convert to list of maps for easier use in the pie chart
    return categorySums.entries.map((entry) {
      return {
        'name': entry.key,
        'value': entry.value,
        'color': categoryColors[entry.key] ?? AppColors.primary,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.grey[100];
    final cardColor = isDarkMode ? AppColors.cardDark : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return MultiBlocListener(
      listeners: [
        BlocListener<AccountBloc, AccountState>(
          listener: (context, state) {
            if (state is AccountBalanceRecalculated) {
              // Convert the transaction account back to home account
              if (state.account.accountId == account.accountId) {
                // Create a new account with the updated balance
                final updatedAccount = account.copyWith(
                  balance: state.account.balance,
                );

                // Update the local state variable to reflect the new balance
                setState(() {
                  // Use a private field to hold the updated account
                  _updatedAccount = updatedAccount;

                  // Refresh the filtered transactions
                  _applyFilters();
                });
              }
            } else if (state is AccountUpdated) {
              // Handle account updates (name, type, etc.)
              if (state.account.accountId == account.accountId) {
                // Convert the transaction account to home account
                final homeAccount = Account(
                  accountId: state.account.accountId,
                  userId: state.account.userId,
                  name: state.account.name,
                  type: state.account.type,
                  balance: state.account.balance,
                  currency: state.account.currency,
                  color: state.account.color,
                  pinned: state.account.pinned,
                  archived: state.account.archived,
                );

                // Update the local state
                setState(() {
                  _updatedAccount = homeAccount;
                });

                // Refresh transactions to include any new adjustment transactions
                final transactionBloc = context.read<TransactionBloc>();
                transactionBloc.add(
                  LoadTransactionsByAccountEvent(state.account.accountId),
                );
              }
            }
          },
        ),
        BlocListener<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is TransactionsLoaded) {
              setState(() {
                // Update the transactions
                widget.transactions.clear();
                widget.transactions.addAll(state.transactions);
                _applyFilters();
              });
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text('Account Details', style: TextStyle(color: textColor)),
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit, color: textColor),
              onPressed: () {
                _showEditAccountModal(context);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: textColor),
              onPressed: () {
                _showDeleteAccountConfirmation(context);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Header
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                color: cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          account.name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, color: textColor),
                          tooltip: 'Recalculate Balance',
                          onPressed: _recalculateAccountBalance,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: account.getColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          account.type,
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Account Total Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
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
                  children: [
                    Text(
                      'Account Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      Formatters.formatCurrency(account.balance),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_filteredTransactions.length} transactions',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Time filter
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 48,
                decoration: BoxDecoration(
                  color: cardColor,
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
                child: Row(
                  children:
                      _timeFilters.map((filter) {
                        final isSelected = _selectedTimeFilter == filter;
                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTimeFilter = filter;
                                _applyFilters();
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : null,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : textColor,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Income and Expense
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
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
                child: Row(
                  children: [
                    // Expense
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Expense',
                            style: TextStyle(fontSize: 16, color: textColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Formatters.formatCurrency(totalExpense),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(
                      height: 40,
                      width: 1,
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    ),

                    // Income
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Income',
                            style: TextStyle(fontSize: 16, color: textColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Formatters.formatCurrency(totalIncome),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.income,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Chart section title and toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Category Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    // Toggle between expense and income view
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showingExpenses = !_showingExpenses;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _showingExpenses
                                  ? AppColors.expense
                                  : AppColors.income,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _showingExpenses ? 'Expense' : 'Income',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Pie Chart
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                height: 300,
                decoration: BoxDecoration(
                  color: cardColor,
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
                child:
                    categoryData.isEmpty
                        ? Center(
                          child: Text(
                            'No ${_showingExpenses ? 'expense' : 'income'} data for this period',
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                        )
                        : Row(
                          children: [
                            // Pie Chart
                            Expanded(
                              flex: 3,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 30,
                                  sections:
                                      categoryData.map((cat) {
                                        return PieChartSectionData(
                                          color: cat['color'],
                                          value: cat['value'],
                                          title: '',
                                          radius: 100,
                                          titlePositionPercentageOffset: 0.5,
                                        );
                                      }).toList(),
                                  pieTouchData: PieTouchData(enabled: false),
                                ),
                              ),
                            ),

                            // Legend
                            Expanded(
                              flex: 2,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: categoryData.length,
                                itemBuilder: (context, index) {
                                  final category = categoryData[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: category['color'],
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            category['name'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          Formatters.formatCurrency(
                                            category['value'],
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
              ),

              const SizedBox(height: 24),

              // Transactions title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Transactions list
              _filteredTransactions.isEmpty
                  ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'No transactions for this period',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  )
                  : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _filteredTransactions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow:
                                !isDarkMode
                                    ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    transaction.amount > 0
                                        ? AppColors.income.withValues(
                                          alpha: 0.2,
                                        )
                                        : AppColors.expense.withValues(
                                          alpha: 0.2,
                                        ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                transaction.amount > 0
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color:
                                    transaction.amount > 0
                                        ? AppColors.income
                                        : AppColors.expense,
                              ),
                            ),
                            title: Text(
                              transaction.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            subtitle: Text(
                              '${transaction.categoryName ?? 'Uncategorized'} • ${DateFormat.yMMMd().format(transaction.date)}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                            trailing: Text(
                              Formatters.formatCurrency(transaction.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    transaction.amount > 0
                                        ? AppColors.income
                                        : AppColors.expense,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditAccountModal(BuildContext context) {
    final homeAccount = account;

    // Use AccountFormModal instead of AccountFormBottomSheet
    AccountFormModal.show(context, account: homeAccount, isEdit: true).then((
      _,
    ) {
      // When the modal is closed, ensure we have the latest data
      if (account.accountId != null) {
        if (!context.mounted) return;

        try {
          // Reload the account data
          final accountBloc = context.read<AccountBloc>();
          accountBloc.add(LoadAccountByIdEvent(account.accountId!));
        } catch (e) {
          // Bloc might be closed, ignore the error
        }

        try {
          // Reload transactions for this account
          final transactionBloc = context.read<TransactionBloc>();
          transactionBloc.add(
            LoadTransactionsByAccountEvent(account.accountId!),
          );
        } catch (e) {
          // Bloc might be closed, ignore the error
        }
      }
    });
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final String accountName = account.name;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.cardDark : Colors.white,
          title: Text(context.tr('accounts_delete_title')),
          content: Text(
            context
                .tr('accounts_delete_confirmation')
                .replaceAll('{name}', accountName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('common_cancel')),
            ),
            TextButton(
              onPressed: () {
                try {
                  final accountBloc = context.read<AccountBloc>();
                  accountBloc.add(DeleteAccountEvent(account.accountId!));
                } catch (e) {
                  // Bloc might be closed, ignore the error
                }

                // Close the dialog
                Navigator.pop(context);

                // Return to the previous screen
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(context.tr('common_delete')),
            ),
          ],
        );
      },
    );
  }

  void _recalculateAccountBalance() {
    if (account.accountId != null) {
      final transactionAccount = _convertHomeAccountToTransactionAccount(
        account,
      );

      try {
        final accountBloc = context.read<AccountBloc>();
        accountBloc.add(
          RecalculateAccountBalanceEvent(transactionAccount.accountId),
        );

        // Show a snackbar to indicate the operation is in progress
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recalculating account balance...'),
            duration: Duration(seconds: 1),
          ),
        );
      } catch (e) {
        // Bloc might be closed, ignore the error

        // Show an error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to recalculate account balance.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  transaction_account.Account _convertHomeAccountToTransactionAccount(
    Account account,
  ) {
    return transaction_account.Account(
      accountId: account.accountId!,
      userId: account.userId,
      name: account.name,
      type: account.type,
      balance: account.balance,
      currency: account.currency,
      color: account.color,
      pinned: account.pinned,
      archived: account.archived,
    );
  }
}
