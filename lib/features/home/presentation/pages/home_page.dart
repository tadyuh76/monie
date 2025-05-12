import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/category_data.dart';
import 'package:monie/core/utils/mock_data.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_event.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/authentication/presentation/pages/login_page.dart';
import 'package:monie/features/home/presentation/widgets/accounts_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/account_summary_widget.dart';
import 'package:monie/features/home/presentation/widgets/budget_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/greeting_widget.dart';
import 'package:monie/features/home/presentation/widgets/heat_map_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/net_worth_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/pie_chart_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/recent_transactions_section_widget.dart';
import 'package:monie/features/home/presentation/widgets/summary_section_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const GreetingWidget(name: 'Đạt Huy'),
                const SizedBox(height: 24),
                AccountsSectionWidget(accounts: MockData.accounts),
                const SizedBox(height: 24),
                AccountSummaryWidget(
                  accounts: MockData.accounts,
                  transactions: MockData.transactions,
                ),
                const SizedBox(height: 24),
                BudgetSectionWidget(budget: MockData.budgets.first),
                const SizedBox(height: 24),
                SummarySectionWidget(transactions: MockData.transactions),
                const SizedBox(height: 24),
                NetWorthSectionWidget(netWorth: 178.0, transactionsCount: 3),
                const SizedBox(height: 24),
                const PieChartSectionWidget(),
                const SizedBox(height: 24),
                const HeatMapSectionWidget(),
                const SizedBox(height: 24),
                RecentTransactionsSectionWidget(
                  transactions: MockData.transactions,
                  onViewAllPressed: () {
                    // Navigate to transactions page
                    Navigator.pushNamed(context, '/transactions');
                  },
                ),
                const SizedBox(height: 100), // Extra space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}
