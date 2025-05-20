import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/home/domain/entities/account.dart'
    as home_account;
import 'package:monie/features/home/presentation/widgets/balance_chart_widget.dart';
import 'package:monie/features/home/presentation/widgets/greeting_widget.dart';
import 'package:monie/features/home/presentation/widgets/heat_map_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/pie_chart_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/recent_transactions_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/summary_section_widget.dart';
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
                  // Listen for transaction states that should trigger data reload
                  return current is TransactionCreated ||
                      current is TransactionUpdated ||
                      current is TransactionDeleted;
                },
                listener: (context, state) {
                  // Reload the home page data when transactions change
                  if (state is TransactionCreated ||
                      state is TransactionUpdated ||
                      state is TransactionDeleted) {
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

                // Summary section
                BlocBuilder<TransactionBloc, TransactionState>(
                  builder: (context, state) {
                    if (state is TransactionsLoaded) {
                      return SummarySectionWidget(
                        transactions: state.transactions,
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
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

                // Accounts section
                _buildAccountsSection(context, userId),

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
            if (accountState is AccountsLoaded &&
                transactionState is TransactionsLoaded) {
              // Convert Account entities to home_account.Account entities
              final homeAccounts =
                  accountState.accounts.map((acc) {
                    return home_account.Account(
                      accountId: acc.accountId,
                      userId: userId,
                      name: acc.name,
                      type: acc.type,
                      balance: acc.balance,
                      currency: acc.currency,
                      color: acc.color ?? 'blue',
                      pinned: true, // Set all accounts as pinned for now
                    );
                  }).toList();

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
                  if (homeAccounts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          context.tr('home_no_accounts'),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: homeAccounts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: 180,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    homeAccounts[index].getColor(),
                                    homeAccounts[index].getColor().withValues(
                                      alpha: 0.7,
                                    ),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    homeAccounts[index].name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    homeAccounts[index].type,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${homeAccounts[index].currency}${homeAccounts[index].balance}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        );
      },
    );
  }

  Widget _buildBudgetsSection(BuildContext context, String userId) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) {
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
              Text(
                context.tr('home_budgets'),
                style: textTheme.headlineMedium?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (activeBudgets.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      context.tr('home_no_budgets'),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
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

                    return Container(
                      padding: const EdgeInsets.all(16),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        return const Center(child: CircularProgressIndicator());
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
