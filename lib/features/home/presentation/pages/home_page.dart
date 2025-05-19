import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/category_data.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_event.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/authentication/presentation/pages/login_page.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:monie/features/home/presentation/bloc/home_bloc.dart';
import 'package:monie/features/home/presentation/widgets/accounts_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/account_summary_widget.dart';
import 'package:monie/features/home/presentation/widgets/budget_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/greeting_widget.dart';
import 'package:monie/features/home/presentation/widgets/heat_map_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/net_worth_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/pie_chart_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/recent_transactions_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/summary_section_widget.dart';

// Define a callback type for tab switching
typedef TabSwitchCallback = void Function(int index);

// Define a key for accessing MainScreen state from children
final GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey<NavigatorState>();

class HomePage extends StatefulWidget {
  final TabSwitchCallback? onSwitchTab;

  const HomePage({super.key, this.onSwitchTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // A method to reset categories in the database
  Future<void> _resetCategories(BuildContext context) async {
    // Capture the ScaffoldMessenger before async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Seed categories into database
      final success = await CategoryData.seedCategoriesIntoDatabase();

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success/failure message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Categories reset successfully!'
                : 'Failed to reset categories.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message using captured ScaffoldMessenger
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Reload home data when the page is initialized
    context.read<HomeBloc>().add(const LoadHomeData());
    // Make sure budgets are loaded too
    context.read<BudgetsBloc>().add(const LoadBudgets());
  }

  // Widget to build the budget section based on BudgetsBloc state
  Widget _buildBudgetSection() {
    return BlocBuilder<BudgetsBloc, BudgetsState>(
      builder: (context, state) {
        if (state is BudgetsLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        } else if (state is BudgetsError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Error loading budgets: ${state.message}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    context.read<BudgetsBloc>().add(const LoadBudgets());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is BudgetsLoaded) {
          if (state.budgets.isNotEmpty) {
            return BudgetSectionWidget(budget: state.budgets.first);
          } else {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white70,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No active budgets',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create a budget to start tracking your spending',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
        }

        // Initial state
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'Loading budgets...',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // When user is signed out, navigate to login page
        if (state is Unauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Monie',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            // More options menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'reset_categories') {
                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Text(
                            'Reset Categories',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'This will ensure all default categories are available in the database. Continue?',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _resetCategories(context);
                              },
                              child: const Text('Reset Categories'),
                            ),
                          ],
                        ),
                  );
                } else if (value == 'logout') {
                  // Show logout confirmation dialog
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'Are you sure you want to logout?',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.read<AuthBloc>().add(SignOutEvent());

                                // Also manually navigate to login page for redundancy
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: Text(
                                'Logout',
                                style: TextStyle(color: AppColors.expense),
                              ),
                            ),
                          ],
                        ),
                  );
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem<String>(
                      value: 'reset_categories',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Reset Categories',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Logout', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is HomeError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading data: ${state.message}',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<HomeBloc>().add(const LoadHomeData());
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (state is HomeLoaded) {
                // Get user data from AuthBloc
                final authState = context.watch<AuthBloc>().state;
                final userName =
                    authState is Authenticated
                        ? authState.user.displayName ?? 'User'
                        : 'User';

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      GreetingWidget(name: userName),
                      const SizedBox(height: 24),
                      AccountsSectionWidget(accounts: state.accounts, transactions: state.recentTransactions,),
                      const SizedBox(height: 24),
                      AccountSummaryWidget(
                        accounts: state.accounts,
                        transactions: state.recentTransactions,
                      ),
                      const SizedBox(height: 24),
                      _buildBudgetSection(),
                      const SizedBox(height: 24),
                      SummarySectionWidget(
                        transactions: state.recentTransactions,
                      ),
                      const SizedBox(height: 24),
                      NetWorthSectionWidget(
                        netWorth: state.totalBalance,
                        transactionsCount: state.transactionCount,
                      ),
                      const SizedBox(height: 24),
                      const PieChartSectionWidget(),
                      const SizedBox(height: 24),
                      const HeatMapSectionWidget(),
                      const SizedBox(height: 24),
                      RecentTransactionsSectionWidget(
                        transactions: state.recentTransactions,
                        onViewAllPressed: () {
                          // Switch to transactions tab instead of navigating
                          if (widget.onSwitchTab != null) {
                            widget.onSwitchTab!(
                              1,
                            ); // Index 1 is transactions tab
                          } else {
                            // Fallback to traditional navigation if not provided
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tab switching not available'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 100), // Extra space at the bottom
                    ],
                  ),
                );
              }

              // Default initial state
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }
}
