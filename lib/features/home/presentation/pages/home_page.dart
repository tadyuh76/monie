import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/home/domain/entities/account.dart'
    as home_account;
import 'package:monie/features/home/presentation/widgets/account_card_widget.dart';
import 'package:monie/features/home/presentation/widgets/balance_chart_widget.dart';
import 'package:monie/features/home/presentation/widgets/greeting_widget.dart';
import 'package:monie/features/home/presentation/widgets/heat_map_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/pie_chart_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/recent_transactions_section_widget.dart';
import 'package:monie/features/transactions/domain/entities/account.dart'
    as transaction_account;
import 'package:monie/features/transactions/domain/entities/budget.dart';
import 'package:monie/features/transactions/presentation/bloc/account_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/account_event.dart';
import 'package:monie/features/transactions/presentation/bloc/account_state.dart';
import 'package:monie/features/transactions/presentation/bloc/budget_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/budget_event.dart';
import 'package:monie/features/transactions/presentation/bloc/budget_state.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:monie/features/transactions/presentation/pages/transactions_page.dart';
import 'package:monie/features/transactions/presentation/widgets/account_form_bottom_sheet.dart';
import 'package:monie/features/transactions/presentation/widgets/budget_form_bottom_sheet.dart';
import 'package:monie/features/home/presentation/widgets/accounts_section_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Local cache for accounts to avoid UI flickering
  List<home_account.Account> _cachedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final userId = authState.user.id;

      // Load transactions
      context.read<TransactionBloc>().add(LoadTransactionsEvent(userId));

      // Load accounts
      context.read<AccountBloc>().add(LoadAccountsEvent(userId));

      // Load budgets
      context.read<BudgetBloc>().add(LoadBudgetsEvent(userId));
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
                    _loadData();
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
                      state is AccountBalanceUpdated) {
                    _loadData();
                  }
                  // No need to reload data for simple pin updates
                },
              ),
              BlocListener<BudgetBloc, BudgetState>(
                listenWhen:
                    (previous, current) =>
                        current is BudgetCreated ||
                        current is BudgetUpdated ||
                        current is BudgetDeleted,
                listener: (context, state) {
                  if (state is BudgetCreated ||
                      state is BudgetUpdated ||
                      state is BudgetDeleted) {
                    _loadData();
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
        onRefresh: () async => _loadData(),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Greeting section
                GreetingWidget(name: displayName),

                const SizedBox(height: 24),

                // Accounts section
                _buildAccountsSection(context, userId),

                // Summary section
                // BlocBuilder<TransactionBloc, TransactionState>(
                //   builder: (context, state) {
                //     if (state is TransactionsLoaded) {
                //       return SummarySectionWidget(
                //         transactions: state.transactions,
                //       );
                //     }
                //     return const Center(child: CircularProgressIndicator());
                //   },
                // ),
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

                // Pie Chart section - Category analysis
                const PieChartSectionWidget(),

                const SizedBox(height: 24),

                // Heat Map section
                const HeatMapSectionWidget(),

                const SizedBox(height: 24),

                // Recent transactions section
                BlocBuilder<TransactionBloc, TransactionState>(
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
                                  color:
                                      isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => _loadData(),
                                child: Text(context.tr('retry')),
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
                                  color:
                                      isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                          : RecentTransactionsSectionWidget(
                            transactions: state.transactions,
                            onViewAllPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransactionsPage(),
                                ),
                              ).then((_) {
                                // Reload data when returning from transactions page
                                _loadData();
                              });
                            },
                          );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),

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

  Widget _buildAccountsSection(BuildContext context, String userId) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, accountState) {
        return BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, transactionState) {
            List<home_account.Account> accountsToDisplay = [];

            // Handle loading states explicitly - use cached accounts if we have them
            if ((accountState is AccountLoading ||
                    transactionState is TransactionLoading) &&
                _cachedAccounts.isNotEmpty) {
              // Use cached accounts to avoid flickering during loading
              accountsToDisplay = List.from(_cachedAccounts);
            } else if (accountState is AccountLoading ||
                transactionState is TransactionLoading) {
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
            // Handle successfully loaded states
            else if (accountState is AccountsLoaded &&
                transactionState is TransactionsLoaded) {
              // Convert Account entities to home_account.Account entities
              accountsToDisplay =
                  accountState.accounts.map((acc) {
                    return home_account.Account(
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

  Widget _buildAccountCard(BuildContext context, home_account.Account account) {
    return SizedBox(
      width: 160,
      child: AccountCardWidget(
        account: account,
        transactions: [],
        onPinToggle: () => _toggleAccountPin(account),
        onEdit: () => _showEditAccountOptions(context, account),
      ),
    );
  }

  Widget _buildAddAccountCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBackgroundColor =
        isDarkMode ? AppColors.cardDark : Colors.grey[200];

    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: () {
          _showAddAccountModal(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode ? Colors.white30 : Colors.black26,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 32,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('accounts_add_new'),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleAccountPin(home_account.Account account) {
    // Debug print to verify method is called
    print(
      "Toggling pin for account: ${account.name}, currently pinned: ${account.pinned}",
    );

    // Skip if already pinned (shouldn't happen with our UI flow)
    if (account.pinned) return;

    // Get the AccountBloc
    final accountBloc = context.read<AccountBloc>();

    // Find all pinned accounts
    List<home_account.Account> pinnedAccounts =
        _cachedAccounts.where((acc) => acc.pinned).toList();
    print("Found ${pinnedAccounts.length} pinned accounts before update");

    // Update cached accounts immediately (to avoid UI flicker)
    setState(() {
      for (int i = 0; i < _cachedAccounts.length; i++) {
        // For consistent behavior, we'll ensure only one account is pinned
        if (_cachedAccounts[i].accountId == account.accountId) {
          // Pin the clicked account
          _cachedAccounts[i] = home_account.Account(
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
          _cachedAccounts[i] = home_account.Account(
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

    // Update the database
    // Unpin any currently pinned accounts
    for (final acc in pinnedAccounts) {
      final unpinnedAccount = transaction_account.Account(
        accountId: acc.accountId!,
        userId: acc.userId,
        name: acc.name,
        type: acc.type,
        balance: acc.balance,
        currency: acc.currency,
        color: acc.color,
        pinned: false,
      );

      print("Unpinning account in DB: ${acc.name}");
      accountBloc.add(UpdateAccountEvent(unpinnedAccount));
    }

    // Then pin the selected account
    final accountToPin = transaction_account.Account(
      accountId: account.accountId!,
      userId: account.userId,
      name: account.name,
      type: account.type,
      balance: account.balance,
      currency: account.currency,
      color: account.color,
      pinned: true,
    );

    print("Pinning account in DB: ${account.name}");
    accountBloc.add(UpdateAccountEvent(accountToPin));

    // Reload accounts after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      accountBloc.add(LoadAccountsEvent(account.userId));
    });
  }

  Widget _buildEmptyAccountsView(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 150,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              _showAddAccountModal(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(context.tr('accounts_add_new')),
          ),
        ],
      ),
    );
  }

  void _showAddAccountModal(BuildContext context) {
    // Implement account creation modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const AccountFormBottomSheet();
      },
    );
  }

  void _showEditAccountOptions(
    BuildContext context,
    home_account.Account account,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Provide haptic feedback to indicate the long-press was recognized
    HapticFeedback.mediumImpact();

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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  account.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.primary),
                title: Text(context.tr('common_edit')),
                onTap: () {
                  Navigator.pop(context);
                  _showEditAccountModal(context, account);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(context.tr('common_delete')),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteAccountConfirmation(context, account);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  transaction_account.Account _convertHomeAccountToTransactionAccount(
    home_account.Account account,
  ) {
    return transaction_account.Account(
      accountId: account.accountId!,
      userId: account.userId,
      name: account.name,
      type: account.type,
      balance: account.balance,
      currency: account.currency,
      // The color parameter is nullable in the Transaction Account class
    );
  }

  void _showEditAccountModal(
    BuildContext context,
    home_account.Account account,
  ) {
    final transactionAccount = _convertHomeAccountToTransactionAccount(account);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AccountFormBottomSheet(account: transactionAccount);
      },
    );
  }

  void _showDeleteAccountConfirmation(
    BuildContext context,
    home_account.Account account,
  ) {
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
                final accountBloc = context.read<AccountBloc>();
                accountBloc.add(DeleteAccountEvent(account.accountId!));
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

  Widget _buildBudgetsSection(BuildContext context, String userId) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) {
        if (state is BudgetLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 50.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (state is BudgetError) {
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
                    // Calculate progress (simplified for this example)
                    final progress =
                        0.7; // This should be calculated based on spent/total
                    // We don't have spent amount available, so using a placeholder
                    final spentAmount = budget.amount * progress;

                    return Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isDarkMode ? AppColors.cardDark : Colors.white,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    budget.name,
                                    style: textTheme.titleMedium?.copyWith(
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${spentAmount.toStringAsFixed(2)}/${budget.amount.toStringAsFixed(2)}',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: _getBudgetColor(budget.color),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor:
                                      isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[300],
                                  minHeight: 10,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getBudgetColor(budget.color),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'All Categories', // Using placeholder since categoryName isn't available
                                style: textTheme.bodyMedium?.copyWith(
                                  color:
                                      isDarkMode
                                          ? AppColors.textSecondary
                                          : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () {
                              _showEditBudgetOptions(context, budget);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color:
                                    (isDarkMode
                                        ? Colors.white10
                                        : Colors.black.withValues(alpha: 0.05)),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.more_vert,
                                color:
                                    isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                      onPressed: () => Navigator.pushNamed(context, '/budgets'),
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
                            '${context.tr('home_see_all')} ${context.tr('home_budgets')}',
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
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
        // Fallback for initial or other states
        return const SizedBox.shrink();
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
                  _showEditBudgetModal(context, budget);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(context.tr('common_delete')),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteBudgetConfirmation(context, budget);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditBudgetModal(BuildContext context, Budget budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BudgetFormBottomSheet(budget: budget);
      },
    );
  }

  void _showDeleteBudgetConfirmation(BuildContext context, Budget budget) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.cardDark : Colors.white,
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
                final budgetBloc = context.read<BudgetBloc>();
                budgetBloc.add(DeleteBudgetEvent(budget.budgetId));
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

  Color _getBudgetColor(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'teal':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }
}
