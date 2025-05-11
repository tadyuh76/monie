import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/themes/app_colors.dart';
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
            // Logout button
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                // Show confirmation dialog
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
              },
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
