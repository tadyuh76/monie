import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/core/utils/mock_data.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_event.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/authentication/presentation/pages/login_page.dart';
import 'package:monie/features/home/domain/entities/account.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

// Custom painter for the line chart
class LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.chartLine
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

    // Grid lines
    final gridPaint =
        Paint()
          ..color = AppColors.chartGrid
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // Draw grid lines
    for (int i = 0; i < 4; i++) {
      final y = size.height - (i * (size.height / 3));

      // Dashed line
      final dashPath = Path();
      dashPath.moveTo(0, y);
      for (double x = 0; x < size.width; x += 12) {
        dashPath.moveTo(x, y);
        dashPath.lineTo(x + 6, y);
      }

      canvas.drawPath(dashPath, gridPaint);
    }

    // Line path
    final path = Path();

    // Define the points on the curve (values normalized to fit the chart)
    final points = [
      Offset(0, size.height), // 0
      Offset(size.width * 0.25, size.height * 0.5), // 90
      Offset(size.width * 0.5, size.height * 0.01), // 179
      Offset(size.width * 0.75, size.height * 0.02), // 178
      Offset(size.width, size.height * 0.02), // 178
    ];

    // Move to the first point
    path.moveTo(points[0].dx, points[0].dy);

    // Create a smooth curve through the points
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      // Simple curve - in real app use bezier curves for smoothness
      path.quadraticBezierTo((p1.dx + p2.dx) / 2, p1.dy, p2.dx, p2.dy);
    }

    // Draw the line
    canvas.drawPath(path, paint);

    // Fill area under the curve
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint =
        Paint()
          ..color = AppColors.chartLine.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Triangle painter for the indicator
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    // Draw a downward-pointing triangle
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Index for pie chart pages (0 = expenses, 1 = incomes)
  int _pieChartPageIndex = 0;

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
                _buildGreeting(context),
                const SizedBox(height: 24),
                _buildAccountsSection(context),
                const SizedBox(height: 24),
                _buildAccountSummary(context),
                const SizedBox(height: 24),
                _buildBudgetSection(context),
                const SizedBox(height: 24),
                _buildSummarySection(context),
                const SizedBox(height: 24),
                _buildNetWorthSection(context),
                const SizedBox(height: 24),
                _buildPieChartSection(context),
                const SizedBox(height: 24),
                _buildHeatMapSection(context),
                const SizedBox(height: 24),
                _buildRecentTransactionsSection(context),
                const SizedBox(height: 100), // Extra space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi there',
          style: textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          'Đạt Huy',
          style: textTheme.headlineLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsSection(BuildContext context) {
    // In a real app, this would come from the HomeBloc
    final accounts = MockData.accounts;

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final account = accounts[index];
          return SizedBox(
            width: 200,
            child: _buildAccountCard(context, account),
          );
        },
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, Account account) {
    final textTheme = Theme.of(context).textTheme;

    // Determine card color based on account type
    Color accountColor = AppColors.bank;
    if (account.type == 'cash') {
      accountColor = AppColors.cash;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                account.name,
                style: textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: accountColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$${account.balance.abs().toStringAsFixed(0)}',
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${account.transactionCount} ${account.transactionCount == 1 ? 'transaction' : 'transactions'}',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSummary(BuildContext context) {
    final accounts = MockData.accounts;

    // Calculate total balance
    final double totalBalance = accounts.fold(
      0,
      (previousValue, account) => previousValue + account.balance,
    );

    // Calculate income and expense
    final transactions = MockData.transactions;
    final double totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0, (sum, t) => sum + t.amount);
    final double totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold(0, (sum, t) => sum + t.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Balance column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Balance',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(totalBalance),
                  style: TextStyle(
                    color: totalBalance >= 0 ? Colors.white : AppColors.expense,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Income column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Income',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(totalIncome),
                  style: const TextStyle(
                    color: AppColors.income,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Expense column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expense',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(totalExpense),
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final budget = MockData.budgets.first;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.budgetBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            budget.name,
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${Formatters.formatCurrency(budget.remainingAmount)} left of ${Formatters.formatCurrency(budget.totalAmount)}',
            style: textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),

          // Progress indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: budget.progressPercentage / 100,
              backgroundColor: Colors.black26,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.budgetProgress,
              ),
              minHeight: 12,
            ),
          ),

          // Date range
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.formatShortDate(budget.startDate),
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Today',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.background,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  Formatters.formatShortDate(budget.endDate),
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),

          // Saving target
          Text(
            'You should save ${Formatters.formatCurrency(budget.dailySavingTarget)}/day for ${budget.daysRemaining} more days',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final transactions = MockData.transactions;

    double totalExpense = 0;
    double totalIncome = 0;

    for (var transaction in transactions) {
      if (transaction.type == 'expense') {
        totalExpense += transaction.amount;
      } else if (transaction.type == 'income') {
        totalIncome += transaction.amount;
      }
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expense',
                  style: textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.formatCurrency(totalExpense),
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.expense,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${transactions.where((t) => t.type == 'expense').length} transactions',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Income',
                  style: textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.formatCurrency(totalIncome),
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.income,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${transactions.where((t) => t.type == 'income').length} transaction',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetWorthSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final netWorth = 178.0; // In a real app, this would be calculated

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Worth',
            style: textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatCurrency(netWorth),
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '3 transactions',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          // Line chart
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: _buildLineChart(),
            ),
          ),

          // Chart labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final labels = ['Apr 10', 'Apr 18', 'Apr 25', 'May 3', 'May 10'];
              return Text(
                labels[index],
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    // Creating a simple line chart
    return CustomPaint(
      size: const Size(double.infinity, 180),
      painter: LineChartPainter(),
    );
  }

  Widget _buildPieChartSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Analysis',
          style: textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.only(
            top: 0,
            left: 24,
            right: 24,
            bottom: 24, // Increased from 24 to 40 to add more bottom spacing
          ),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          height:
              400, // Increased from 350 to 370 to accommodate the extra bottom padding
          child: PageView(
            onPageChanged: (index) {
              setState(() {
                _pieChartPageIndex = index;
              });
            },
            children: [_buildExpensePieChart(), _buildIncomePieChart()],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _pieChartPageIndex == 0
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _pieChartPageIndex == 1
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpensePieChart() {
    // Define expense categories with cleaner, modern colors and icons
    final List<Map<String, dynamic>> expenseCategories = [
      {
        'name': 'Groceries',
        'value': 35.0,
        'color': const Color(0xFF66BB6A),
        'icon': Icons.shopping_basket,
      },
      {
        'name': 'Dining',
        'value': 25.0,
        'color': const Color(0xFFFFA726),
        'icon': Icons.restaurant,
      },
      {
        'name': 'Transport',
        'value': 20.0,
        'color': const Color(0xFF42A5F5),
        'icon': Icons.directions_car,
      },
      {
        'name': 'Shopping',
        'value': 15.0,
        'color': const Color(0xFFEC407A),
        'icon': Icons.shopping_bag,
      },
      {
        'name': 'Entertainment',
        'value': 5.0,
        'color': const Color(0xFFAB47BC),
        'icon': Icons.movie,
      },
    ];

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 280,
          height: 280,
          child: PieChart(
            PieChartData(
              startDegreeOffset: 270, // Start from the top
              sectionsSpace: 3, // Slightly more space between sections
              centerSpaceRadius: 60,
              sections:
                  expenseCategories.map((category) {
                    return PieChartSectionData(
                      color: category['color'],
                      value: category['value'],
                      title: '',
                      radius: 90,
                      showTitle: false,
                    );
                  }).toList(),
              pieTouchData: PieTouchData(enabled: false),
            ),
          ),
        ),

        // Title and category legend in the center
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Expenses',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              Formatters.formatCurrency(100.0),
              style: TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),

        // Category icons positioned around the pie chart
        ...List.generate(expenseCategories.length, (index) {
          // Calculate the middle angle of each pie section in radians
          double totalValue = expenseCategories.fold(
            0.0,
            (sum, item) => sum + item['value'],
          );

          // Calculate the starting and ending angles for each category
          double startAngle = 270.0; // Start from the top
          for (int i = 0; i < index; i++) {
            startAngle += (expenseCategories[i]['value'] / totalValue) * 360.0;
          }

          // Calculate the middle angle of this section
          double middleAngle =
              startAngle +
              (expenseCategories[index]['value'] / totalValue) * 180.0;

          // Convert to radians
          double middleAngleRadians = middleAngle * (3.14159 / 180);

          // Position at the edge of the chart with some padding
          final radius = 110;
          final x = radius * cos(middleAngleRadians);
          final y = radius * sin(middleAngleRadians);

          return Positioned(
            left: 170 + x - 16, // Center (180) + offset - half icon size (16)
            top: 170 + y - 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: expenseCategories[index]['color'],
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardDark, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                expenseCategories[index]['icon'],
                color: Colors.white,
                size: 16,
              ),
            ),
          );
        }),

        // Legend at the bottom
        Positioned(
          bottom: -10,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: expenseCategories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: expenseCategories[index]['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${expenseCategories[index]['name']} (${expenseCategories[index]['value'].toInt()}%)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Triangle indicator at the top right
        Positioned(
          top: 24,
          right: 12,
          child: CustomPaint(
            painter: TrianglePainter(
              const Color(0xFFEF5350), // Updated red for expense
            ),
            size: const Size(16, 10),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomePieChart() {
    // Define income categories with cleaner, modern colors and icons
    final List<Map<String, dynamic>> incomeCategories = [
      {
        'name': 'Salary',
        'value': 70.0,
        'color': const Color(0xFF42A5F5),
        'icon': Icons.work,
      },
      {
        'name': 'Investments',
        'value': 20.0,
        'color': const Color(0xFFFFD54F),
        'icon': Icons.trending_up,
      },
      {
        'name': 'Freelance',
        'value': 10.0,
        'color': const Color(0xFF7E57C2),
        'icon': Icons.computer,
      },
    ];

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 280,
          height: 280,
          child: PieChart(
            PieChartData(
              startDegreeOffset: 270, // Start from the top
              sectionsSpace: 3, // Slightly more space between sections
              centerSpaceRadius: 60,
              sections:
                  incomeCategories.map((category) {
                    return PieChartSectionData(
                      color: category['color'],
                      value: category['value'],
                      title: '',
                      radius: 90,
                      showTitle: false,
                    );
                  }).toList(),
              pieTouchData: PieTouchData(enabled: false),
            ),
          ),
        ),

        // Title and category total in the center
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Income',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              Formatters.formatCurrency(288.0),
              style: TextStyle(
                color: AppColors.income,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),

        // Category icons positioned around the pie chart
        ...List.generate(incomeCategories.length, (index) {
          // Calculate the middle angle of each pie section in radians
          double totalValue = incomeCategories.fold(
            0.0,
            (sum, item) => sum + item['value'],
          );

          // Calculate the starting and ending angles for each category
          double startAngle = 270.0; // Start from the top
          for (int i = 0; i < index; i++) {
            startAngle += (incomeCategories[i]['value'] / totalValue) * 360.0;
          }

          // Calculate the middle angle of this section
          double middleAngle =
              startAngle +
              (incomeCategories[index]['value'] / totalValue) * 180.0;

          // Convert to radians
          double middleAngleRadians = middleAngle * (3.14159 / 180);

          // Position at the edge of the chart with some padding
          final radius = 110;
          final x = radius * cos(middleAngleRadians);
          final y = radius * sin(middleAngleRadians);

          return Positioned(
            left: 170 + x - 16, // Center (140) + offset - half icon size (16)
            top: 170 + y - 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: incomeCategories[index]['color'],
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardDark, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                incomeCategories[index]['icon'],
                color:
                    index == 1
                        ? Colors.black87
                        : Colors.white, // Special case for yellow
                size: 16,
              ),
            ),
          );
        }),

        // Legend at the bottom
        Positioned(
          bottom: -10,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: incomeCategories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: incomeCategories[index]['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${incomeCategories[index]['name']} (${incomeCategories[index]['value'].toInt()}%)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Triangle indicator at the top right
        Positioned(
          top: 24,
          right: 12,
          child: CustomPaint(
            painter: TrianglePainter(
              const Color(0xFF66BB6A), // Updated green for income
            ),
            size: const Size(16, 10),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatMapSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Create a list of the last 180 days (ending today)
    final DateTime today = DateTime.now();
    final List<DateTime> days = List.generate(180, (index) {
      return today.subtract(Duration(days: 179 - index));
    });

    // Generate mock transaction data for the days
    final Map<DateTime, double> dailyCashFlow = {};
    final Random random = Random(42); // Seed for consistent random numbers

    // Create patterns for the mock data
    for (final day in days) {
      // Skip some days (no transactions)
      if (random.nextDouble() > 0.7) {
        continue;
      }

      // Generate cash flow (-100 to +100)
      final double cashFlow = (random.nextDouble() * 200) - 100;
      dailyCashFlow[day] = cashFlow;
    }

    // Add some specific patterns
    // Weekend pattern - more expenses
    for (final day in days) {
      if (day.weekday >= 6 &&
          !dailyCashFlow.containsKey(day) &&
          random.nextDouble() > 0.3) {
        dailyCashFlow[day] = -(random.nextDouble() * 60 + 20); // -20 to -80
      }
    }

    // Beginning of month - income
    for (final day in days) {
      if (day.day <= 3 &&
          !dailyCashFlow.containsKey(day) &&
          random.nextDouble() > 0.4) {
        dailyCashFlow[day] = random.nextDouble() * 80 + 40; // +40 to +120
      }
    }

    // Create specific data points
    dailyCashFlow[today.subtract(const Duration(days: 1))] = -65;
    dailyCashFlow[today] = 50;
    dailyCashFlow[today.subtract(const Duration(days: 7))] = 120;
    dailyCashFlow[today.subtract(const Duration(days: 15))] = -85;

    // Group by weekday to organize into columns (0 = Monday, 6 = Sunday)
    final List<List<MapEntry<DateTime, double?>>> columns = [];

    // Calculate how many weeks to display (180 days ÷ 7 ≈ 25.7 weeks)
    final int weeksCount = (days.length / 7).ceil();

    // Create columns grouped by weekday
    for (int week = 0; week < weeksCount; week++) {
      final List<MapEntry<DateTime, double?>> column = List.generate(7, (
        weekday,
      ) {
        final int dayIndex = week * 7 + weekday;
        if (dayIndex >= days.length) {
          return MapEntry(today, null); // Padding
        }

        final DateTime date = days[dayIndex];
        final double? cashFlow = dailyCashFlow[date];
        return MapEntry(date, cashFlow);
      });

      columns.add(column);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash Flow Activity',
          style: textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date range
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last 180 Days',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('MMM d').format(days.first),
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const Text(
                          ' - ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          DateFormat('MMM d').format(days.last),
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Heatmap - horizontally scrollable
              SizedBox(
                height: 120,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  reverse: true, // Latest dates (today) on the right
                  child: Row(
                    children:
                        columns.map((column) {
                          // Add visual indicator for today's column
                          // bool containsToday = column.any(
                          //   (entry) =>
                          //       entry.key.year == today.year &&
                          //       entry.key.month == today.month &&
                          //       entry.key.day == today.day,
                          // );

                          return Container(
                            width: 16, // Column width
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              children:
                                  column.map((entry) {
                                    final date = entry.key;
                                    final cashFlow = entry.value;

                                    // Cell color based on cash flow
                                    Color cellColor;
                                    if (cashFlow == null) {
                                      // No transaction
                                      cellColor = AppColors.textSecondary
                                          .withValues(alpha: 0.1);
                                    } else if (cashFlow > 0) {
                                      // Positive cash flow (green)
                                      final intensity = min(
                                        0.9,
                                        (cashFlow / 100),
                                      );
                                      cellColor = const Color(
                                        0xFF66BB6A,
                                      ).withValues(
                                        alpha: 0.3 + (intensity * 0.6),
                                      );
                                    } else {
                                      // Negative cash flow (red)
                                      final intensity = min(
                                        0.9,
                                        (-cashFlow / 100),
                                      );
                                      cellColor = const Color(
                                        0xFFEF5350,
                                      ).withValues(
                                        alpha: 0.3 + (intensity * 0.6),
                                      );
                                    }

                                    // Tooltip content
                                    String tooltip = Formatters.formatShortDate(
                                      date,
                                    );
                                    if (cashFlow != null) {
                                      final isPositive = cashFlow > 0;
                                      final formattedAmount =
                                          Formatters.formatCurrency(
                                            cashFlow.abs(),
                                          );
                                      tooltip +=
                                          '\n${isPositive ? "Income" : "Expense"}: ';
                                      tooltip +=
                                          isPositive
                                              ? '+$formattedAmount'
                                              : '-$formattedAmount';
                                    } else {
                                      tooltip += '\nNo transactions';
                                    }

                                    // Special background for today's cell
                                    Color backgroundColor = cellColor;
                                    if (date.year == today.year &&
                                        date.month == today.month &&
                                        date.day == today.day) {
                                      backgroundColor = Colors.white.withValues(
                                        alpha: 0.15,
                                      );
                                    }

                                    return Expanded(
                                      child: Tooltip(
                                        message: tooltip,
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: backgroundColor,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                          child:
                                              cashFlow != null &&
                                                      cashFlow.abs() > 50
                                                  ? Center(
                                                    child: Icon(
                                                      cashFlow > 0
                                                          ? Icons.arrow_upward
                                                          : Icons
                                                              .arrow_downward,
                                                      color: Colors.white,
                                                      size: 8,
                                                    ),
                                                  )
                                                  : null,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Legend
              Row(
                children: [
                  // Left column with red and blue legends
                  Expanded(
                    child: Column(
                      children: [
                        _buildLegendItem(
                          Color(0xFF66BB6A).withValues(alpha: 0.7),
                          'Income > Expense',
                          textTheme,
                        ),
                        const SizedBox(height: 8),
                        _buildLegendItem(
                          Color(0xFFEF5350).withValues(alpha: 0.7),
                          'Expense > Income',
                          textTheme,
                        ),
                      ],
                    ),
                  ),
                  // Right column with no activity legend
                  Expanded(
                    child: _buildLegendItem(
                      AppColors.textSecondary.withValues(alpha: 0.1),
                      'No Activity',
                      textTheme,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build legend items
  Widget _buildLegendItem(Color color, String text, TextTheme textTheme) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: textTheme.bodySmall?.copyWith(
            color: Colors.white70,
            fontSize: 10, // Smaller font size
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final transactions = MockData.transactions;

    // Sort by date (newest first) and limit to 3 transactions
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentTransactions = sortedTransactions.take(3).toList();

    // Group transactions by date
    final Map<String, List<Transaction>> groupedTransactions = {};

    for (var transaction in recentTransactions) {
      final dateString = Formatters.formatFullDate(transaction.date);
      if (!groupedTransactions.containsKey(dateString)) {
        groupedTransactions[dateString] = [];
      }
      groupedTransactions[dateString]!.add(transaction);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Recent Transactions',
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Transaction items grouped by date
        ...groupedTransactions.entries.map((entry) {
          final totalForDay = entry.value.fold<double>(
            0,
            (sum, transaction) =>
                sum +
                (transaction.type == 'expense'
                    ? -transaction.amount
                    : transaction.amount),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(totalForDay),
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...entry.value.map((transaction) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: _buildTransactionItem(context, transaction),
                );
              }),
              if (entry != groupedTransactions.entries.last)
                const SizedBox(height: 16),
            ],
          );
        }),

        const SizedBox(height: 20),

        // View all button
        Center(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextButton(
              onPressed: () {
                // Navigate to transactions page
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
                    'View All Transactions',
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

  Widget _buildTransactionItem(BuildContext context, Transaction transaction) {
    final textTheme = Theme.of(context).textTheme;
    final isExpense = transaction.type == 'expense';
    final colorForType = isExpense ? AppColors.expense : AppColors.income;

    // Get the appropriate icon
    IconData icon;
    if (transaction.title == 'Groceries') {
      icon = Icons.shopping_basket;
    } else if (transaction.title == 'thhy') {
      icon = Icons.work;
    } else {
      icon = isExpense ? Icons.arrow_downward : Icons.arrow_upward;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Transaction icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorForType.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorForType, size: 22),
          ),
          const SizedBox(width: 16),

          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.category,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            isExpense
                ? '-${Formatters.formatCurrency(transaction.amount)}'
                : Formatters.formatCurrency(transaction.amount),
            style: textTheme.titleMedium?.copyWith(
              color: colorForType,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
