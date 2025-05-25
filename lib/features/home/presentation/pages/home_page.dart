import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/widgets/main_screen.dart';
import 'package:monie/features/account/domain/entities/account.dart';
import 'package:monie/features/account/presentation/bloc/account_bloc.dart';
import 'package:monie/features/account/presentation/bloc/account_event.dart';
import 'package:monie/features/account/presentation/bloc/account_state.dart';
import 'package:monie/features/account/presentation/pages/account_form_modal.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:monie/features/budgets/presentation/widgets/budget_card.dart';
import 'package:monie/features/budgets/presentation/widgets/budget_form.dart';
import 'package:monie/features/home/presentation/widgets/accounts_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/balance_chart_widget.dart';
import 'package:monie/features/home/presentation/widgets/category_breakdown_widget.dart';
import 'package:monie/features/home/presentation/widgets/greeting_widget.dart';
import 'package:monie/features/home/presentation/widgets/heat_map_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/monthly_summary_widget.dart';
import 'package:monie/features/home/presentation/widgets/notification_bell_widget.dart';
import 'package:monie/features/home/presentation/widgets/recent_transactions_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/spending_forecast_widget.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_event.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:monie/features/transactions/presentation/widgets/add_transaction_form.dart';
import 'package:monie/features/transactions/presentation/widgets/budget_form_bottom_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Local cache for accounts to avoid UI flickering
  List<Account> _cachedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (!mounted) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final userId = authState.user.id;

      try {
        // Load transactions
        context.read<TransactionBloc>().add(LoadTransactionsEvent(userId));
      } catch (e) {
        // Bloc might be closed, ignore the error
      }

      try {
        // Load accounts
        context.read<AccountBloc>().add(LoadAccountsEvent(userId));
      } catch (e) {
        // Bloc might be closed, ignore the error
      }

      try {
        // Load budgets
        context.read<BudgetsBloc>().add(const LoadBudgets());
      } catch (e) {
        // Bloc might be closed, ignore the error
      }

      try {
        // Load notifications unread count
        context.read<NotificationBloc>().add(LoadUnreadCount(userId));
      } catch (e) {
        // Bloc might be closed, ignore the error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is Authenticated) {
          final userId = authState.user.id;
          final displayName =
              authState.user.displayName != null &&
                      authState.user.displayName!.isNotEmpty
                  ? authState.user.displayName!
                  : authState.user.email.split('@')[0];
          return MultiBlocListener(
            listeners: [
              BlocListener<TransactionBloc, TransactionState>(
                listenWhen: (previous, current) {
                  return current is TransactionCreated ||
                      current is TransactionUpdated ||
                      current is TransactionDeleted;
                },
                listener: (context, state) {
                  if (state is TransactionCreated ||
                      state is TransactionUpdated ||
                      state is TransactionDeleted) {
                    if (mounted) {
                      _loadData();
                    }
                  }
                },
              ),
              BlocListener<AccountBloc, AccountState>(
                listenWhen:
                    (previous, current) =>
                        current is AccountCreated ||
                        current is AccountDeleted ||
                        current is AccountBalanceUpdated ||
                        current is AccountUpdated,
                listener: (context, state) {
                  if (state is AccountCreated ||
                      state is AccountDeleted ||
                      state is AccountBalanceUpdated ||
                      state is AccountUpdated) {
                    if (mounted) {
                      // Reload accounts after any account operation
                      context.read<AccountBloc>().add(
                        LoadAccountsEvent(userId),
                      );
                      _loadData();
                    }
                  }
                  // No need to reload data for simple pin updates
                },
              ),
              BlocListener<BudgetsBloc, BudgetsState>(
                listenWhen:
                    (previous, current) =>
                        current is BudgetAdded ||
                        current is BudgetUpdated ||
                        current is BudgetDeleted,
                listener: (context, state) {
                  if (state is BudgetAdded ||
                      state is BudgetUpdated ||
                      state is BudgetDeleted) {
                    if (mounted) {
                      _loadData();
                    }
                  }
                },
              ),
            ],
            child: _buildDashboard(context, userId, displayName),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    String userId,
    String displayName,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.background : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (mounted) {
            _loadData();
          }
          return;
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Greeting section with notification bell
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: GreetingWidget(name: displayName)),
                    NotificationBellWidget(userId: userId),
                  ],
                ),

                const SizedBox(height: 24),

                // AI Analysis section
                // const AIAnalysisWidget(),

                // const SizedBox(height: 24),

                // Accounts section
                _buildAccountsSection(context, userId),

                const SizedBox(height: 24),

                // Monthly Summary section
                BlocBuilder<TransactionBloc, TransactionState>(
                  builder: (context, state) {
                    if (state is TransactionsLoaded) {
                      return MonthlySummaryWidget(
                        transactions: state.transactions,
                      );
                    }
                    return const SizedBox();
                  },
                ),

                const SizedBox(height: 24),

                // Balance Chart section
                BlocBuilder<TransactionBloc, TransactionState>(
                  builder: (context, state) {
                    if (state is TransactionsLoaded) {
                      return BalanceChartWidget(
                        transactions: state.transactions,
                      );
                    }
                    return const SizedBox();
                  },
                ),

                const SizedBox(height: 24),

                // Spending Forecast section
                const SpendingForecastWidget(),

                const SizedBox(height: 24),

                // // Smart Budget Recommendations
                // const SmartBudgetWidget(),

                // const SizedBox(height: 24),

                // Heat Map section
                const HeatMapSectionWidget(),

                const SizedBox(height: 24),

                // Category Breakdown section
                const CategoryBreakdownWidget(),

                const SizedBox(height: 24),

                // Recent transactions section
                _buildTransactions(),

                const SizedBox(height: 24),

                // Budgets section
                _buildBudgetsSection(context, userId),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
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
                  _loadData();
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

  BlocBuilder<TransactionBloc, TransactionState> _buildTransactions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is TransactionError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    context.tr('home_transaction_error'),
                    style: TextStyle(
                      color: isDarkMode ? Colors.red[300] : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadData,
                    child: Text(context.tr('home_refresh')),
                  ),
                ],
              ),
            ),
          );
        } else if (state is TransactionsLoaded) {
          return state.transactions.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    context.tr('home_no_transactions'),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
              : RecentTransactionsSectionWidget(
                transactions: state.transactions,
                onViewAllPressed: () {
                  // Switch to transactions tab (index 1)
                  navigateToTab(1);
                },
                onTransactionTap: (transaction) {
                  // Navigate to transaction edit form
                  _showEditTransactionForm(context, transaction);
                },
                onTransactionDelete: _confirmDeleteTransaction,
              );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildAccountsSection(BuildContext context, String userId) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, accountState) {
        return BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, transactionState) {
            List<Account> accountsToDisplay = [];

            // Handle loading states explicitly - use cached accounts if we have them
            if ((accountState is AccountLoading ||
                    transactionState is TransactionLoading) &&
                _cachedAccounts.isNotEmpty) {
              // Use cached accounts to avoid flickering during loading
              accountsToDisplay = List.from(_cachedAccounts);
            } else if (accountState is AccountLoading &&
                transactionState is! TransactionsLoaded) {
              // Only show loading if accounts are loading and we don't have transactions loaded yet
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 50.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            // Handle error states explicitly
            else if (accountState is AccountError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    '${context.tr('home_account_error')} ${accountState.message}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            } else if (transactionState is TransactionError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    '${context.tr('home_transaction_error')} ${transactionState.message}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            // Handle successfully loaded states - show accounts even if transactions are still loading
            else if (accountState is AccountsLoaded) {
              // Convert Account entities to Account entities
              accountsToDisplay =
                  accountState.accounts.map((acc) {
                    return Account(
                      accountId: acc.accountId,
                      userId: userId,
                      name: acc.name,
                      type: acc.type,
                      balance: acc.balance,
                      currency: acc.currency,
                      color: acc.color ?? 'blue',
                      pinned: acc.pinned,
                      archived: acc.archived,
                    );
                  }).toList();

              // Update our cached accounts
              _cachedAccounts = List.from(accountsToDisplay);
            }
            // Handle AccountCreated and AccountUpdated states - use cached accounts and trigger reload
            else if (accountState is AccountCreated ||
                accountState is AccountUpdated) {
              if (_cachedAccounts.isNotEmpty) {
                accountsToDisplay = List.from(_cachedAccounts);
              }
              // Trigger a reload to get the updated accounts list
              Future.microtask(() {
                if (context.mounted) {
                  context.read<AccountBloc>().add(LoadAccountsEvent(userId));
                }
              });
            }
            // Fallback for any other unhandled state combinations - use cached accounts if available
            else if (_cachedAccounts.isNotEmpty) {
              accountsToDisplay = List.from(_cachedAccounts);
            } else {
              return const SizedBox.shrink();
            }

            // Sort accounts
            accountsToDisplay.sort((a, b) {
              return a.name.compareTo(b.name);
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('home_accounts'),
                  style: textTheme.headlineMedium?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (accountsToDisplay.isEmpty)
                  _buildEmptyAccountsView(context)
                else
                  AccountsSectionWidget(
                    accounts: accountsToDisplay,
                    transactions:
                        transactionState is TransactionsLoaded
                            ? transactionState.transactions
                            : [],
                    onAccountPinToggle: _toggleAccountPin,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _toggleAccountPin(Account account) {
    // Debug print to verify method is called

    // Skip if already pinned (shouldn't happen with our UI flow)
    if (account.pinned) {
      return;
    }

    // Use a try-catch block to handle potential closed Bloc errors
    try {
      // Get the AccountBloc
      final accountBloc = context.read<AccountBloc>();

      // Find all pinned accounts
      List<Account> pinnedAccounts =
          _cachedAccounts.where((acc) => acc.pinned).toList();

      // First, update the database to ensure persistence
      // Unpin any currently pinned accounts
      for (final acc in pinnedAccounts) {
        final unpinnedAccount = Account(
          accountId: acc.accountId!,
          userId: acc.userId,
          name: acc.name,
          type: acc.type,
          balance: acc.balance,
          currency: acc.currency,
          color: acc.color,
          pinned: false,
          archived: acc.archived,
        );

        accountBloc.add(UpdateAccountEvent(unpinnedAccount));
      }

      // Then pin the selected account
      final accountToPin = Account(
        accountId: account.accountId!,
        userId: account.userId,
        name: account.name,
        type: account.type,
        balance: account.balance,
        currency: account.currency,
        color: account.color,
        pinned: true,
        archived: account.archived,
      );

      accountBloc.add(UpdateAccountEvent(accountToPin));

      // Now update the cached accounts after a short delay to ensure DB updates have been processed
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            for (int i = 0; i < _cachedAccounts.length; i++) {
              // For consistent behavior, we'll ensure only one account is pinned
              if (_cachedAccounts[i].accountId == account.accountId) {
                // Pin the clicked account
                _cachedAccounts[i] = Account(
                  accountId: _cachedAccounts[i].accountId,
                  userId: _cachedAccounts[i].userId,
                  name: _cachedAccounts[i].name,
                  type: _cachedAccounts[i].type,
                  balance: _cachedAccounts[i].balance,
                  currency: _cachedAccounts[i].currency,
                  color: _cachedAccounts[i].color,
                  pinned: true,
                  archived: _cachedAccounts[i].archived,
                );
              } else if (_cachedAccounts[i].pinned) {
                // Unpin any other accounts
                _cachedAccounts[i] = Account(
                  accountId: _cachedAccounts[i].accountId,
                  userId: _cachedAccounts[i].userId,
                  name: _cachedAccounts[i].name,
                  type: _cachedAccounts[i].type,
                  balance: _cachedAccounts[i].balance,
                  currency: _cachedAccounts[i].currency,
                  color: _cachedAccounts[i].color,
                  pinned: false,
                  archived: _cachedAccounts[i].archived,
                );
              }
            }
          });
        }
      });

      // Reload accounts after a longer delay to ensure all updates are complete
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          try {
            // Get a fresh reference to the bloc in case it was recreated
            final freshBloc = context.read<AccountBloc>();
            freshBloc.add(LoadAccountsEvent(account.userId));
          } catch (e) {
            // If there's an error, try to reload all data
            _loadData();
          }
        }
      });
    } catch (e) {
      // If the bloc is closed, we need to reload the page to get a fresh bloc
      if (mounted) {
        // Force refresh the UI to get fresh blocs
        _loadData();
      }
    }
  }

  Widget _buildEmptyAccountsView(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDarkMode
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 28,
                color: isDarkMode ? Colors.white30 : Colors.black26,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('home_no_accounts'),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('home_no_accounts_desc'),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white54 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showAddAccountModal(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(context.tr('accounts_add_new')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAccountModal(BuildContext context) {
    // Use the new AccountFormModal instead of the bottom sheet
    AccountFormModal.show(context);
  }

  Widget _buildBudgetsSection(BuildContext context, String userId) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<BudgetsBloc, BudgetsState>(
      builder: (context, state) {
        if (state is BudgetsLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 50.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (state is BudgetsError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                '${context.tr('home_budget_error')} ${state.message}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (state is BudgetsLoaded) {
          final activeBudgets =
              state.budgets
                  .where(
                    (b) =>
                        b.endDate == null || b.endDate!.isAfter(DateTime.now()),
                  )
                  .take(3)
                  .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('home_budgets'),
                    style: textTheme.headlineMedium?.copyWith(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      _showAddBudgetModal(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (activeBudgets.isEmpty)
                _buildEmptyBudgetsView(context)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeBudgets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final budget = activeBudgets[index];
                    return BudgetCard(
                      budget: budget,
                      onTap: () => _showEditBudgetOptions(context, budget),
                      onEdit: () => _showEditBudgetForm(context, budget),
                      onDelete: () => _confirmDeleteBudget(context, budget),
                    );
                  },
                ),
              const SizedBox(height: 16),
              if (state.budgets.isNotEmpty)
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppColors.surface : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextButton(
                      onPressed: () {
                        // Switch to budgets tab (index 2)
                        navigateToTab(2);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr('home_see_all'),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
        return _buildEmptyBudgetsView(context);
      },
    );
  }

  Widget _buildEmptyBudgetsView(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 150,
      padding: const EdgeInsets.all(20),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.tr('home_no_active_budgets'),
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _showAddBudgetModal(context);
            },
            icon: const Icon(Icons.add),
            label: Text(context.tr('budget_create')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBudgetModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const BudgetFormBottomSheet();
      },
    );
  }

  void _showEditBudgetOptions(BuildContext context, Budget budget) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardDark : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.primary),
                title: Text(context.tr('common_edit')),
                onTap: () {
                  Navigator.pop(context);
                  _showEditBudgetForm(context, budget);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(context.tr('common_delete')),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteBudget(context, budget);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditBudgetForm(BuildContext context, Budget budget) {
    // First navigate to the budget tab
    navigateToTab(2);

    // Then show the edit form as a modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BudgetForm(budget: budget),
    );
  }

  void _confirmDeleteBudget(BuildContext context, Budget budget) {
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

  void _showEditTransactionForm(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => BlocProvider.value(
            value: BlocProvider.of<BudgetsBloc>(context),
            child: AddTransactionForm(
              transaction: transaction,
              onSubmit: (transactionData) {
                final transactionBloc = context.read<TransactionBloc>();
                final accountBloc = context.read<AccountBloc>();

                final oldAccountId = transaction.accountId ?? '';
                final newAccountId = transactionData['account_id'] as String;
                final budgetId = transactionData['budget_id'] as String?;

                // Update the transaction
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
                  accountBloc.add(RecalculateAccountBalanceEvent(newAccountId));
                } else {
                  // Just recalculate the same account
                  accountBloc.add(RecalculateAccountBalanceEvent(newAccountId));
                }

                Navigator.pop(context);

                // Reload data when returning from edit
                _loadData();
              },
            ),
          ),
    );
  }
}
