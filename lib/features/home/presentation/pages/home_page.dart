import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/localization/app_localizations.dart';
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

  // Controller và vị trí hiện tại cho PageView của ngân sách
  final PageController _budgetPageController = PageController(viewportFraction: 0.93);
  int _currentBudgetPage = 0;

  @override
  void initState() {
    super.initState();
    // Reload home data when the page is initialized
    context.read<HomeBloc>().add(const LoadHomeData());
    // Make sure budgets are loaded too
    context.read<BudgetsBloc>().add(const LoadBudgets());

    // Lắng nghe sự kiện thay đổi trang
    _budgetPageController.addListener(_onBudgetPageChanged);
  }

  @override
  void dispose() {
    _budgetPageController.removeListener(_onBudgetPageChanged);
    _budgetPageController.dispose();
    super.dispose();
  }

  void _onBudgetPageChanged() {
    if (_budgetPageController.page!.round() != _currentBudgetPage) {
      setState(() {
        _currentBudgetPage = _budgetPageController.page!.round();
      });
    }
  }

  // Widget to build the budget section based on BudgetsBloc state
  Widget _buildBudgetSection() {
    return BlocBuilder<BudgetsBloc, BudgetsState>(
      builder: (context, state) {
        final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        if (state is BudgetsLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.surface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: !isDarkMode ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ] : null,
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
              color: isDarkMode ? AppColors.surface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: !isDarkMode ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ] : null,
            ),
            child: Column(
              children: [
                Text(
                  '${context.tr('common_error')}: ${state.message}',
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    context.read<BudgetsBloc>().add(const LoadBudgets());
                  },
                  child: Text(context.tr('common_retry')),
                ),
              ],
            ),
          );
        } else if (state is BudgetsLoaded) {
          if (state.budgets.isNotEmpty) {
            // Tạo PageView để hiển thị tất cả ngân sách
            return Column(
              children: [
                SizedBox(
                  height: 200, // Tăng chiều cao lên để có đủ không gian
                  child: PageView.builder(
                    itemCount: state.budgets.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: BudgetSectionWidget(budget: state.budgets[index]),
                      );
                    },
                    // Thêm hiệu ứng lướt mượt và hiển thị một phần ngân sách kế tiếp
                    controller: _budgetPageController,
                  ),
                ),
                const SizedBox(height: 8),
                // Hiển thị indicator để biết đang ở vị trí nào
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    state.budgets.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(index == _currentBudgetPage ? 1.0 : 0.3),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: !isDarkMode ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ] : null,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: isDarkMode ? Colors.white70 : Colors.black45,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('home_no_active_budgets'),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        fontSize: 16
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('home_create_budget_hint'),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white54 : Colors.black54,
                        fontSize: 14
                      ),
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
            color: isDarkMode ? AppColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: !isDarkMode ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ] : null,
          ),
          child: SizedBox(
            height: 100,
            child: Center(
              child: Text(
                context.tr('home_loading_budgets'),
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            context.tr('app_name'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            // Settings icon button
            IconButton(
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87
              ),
              onPressed: () {
                // Navigate to settings page
                Navigator.of(context).pushNamed('/settings');
              },
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('common_loading'),
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87
                        ),
                      ),
                    ],
                  ),
                );
              } else if (state is HomeError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${context.tr('common_error')}: ${state.message}',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<HomeBloc>().add(const LoadHomeData());
                        },
                        child: Text(context.tr('common_retry')),
                      ),
                    ],
                  ),
                );
              } else if (state is HomeLoaded) {
                // Get user data from AuthBloc
                final authState = context.watch<AuthBloc>().state;
                final userName =
                    authState is Authenticated
                        ? authState.user.displayName ?? context.tr('common_user')
                        : context.tr('common_user');

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      GreetingWidget(name: userName),
                      const SizedBox(height: 24),
                      AccountsSectionWidget(accounts: state.accounts),
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
                              SnackBar(
                                content: Text(context.tr('home_tab_switching_unavailable')),
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
