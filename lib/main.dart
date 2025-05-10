import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/core/themes/app_theme.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/category_utils.dart';
import 'package:monie/di/injection.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_event.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/authentication/presentation/pages/login_page.dart';
import 'package:monie/features/home/presentation/bloc/home_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:monie/features/home/presentation/pages/home_page.dart';
import 'package:monie/features/transactions/presentation/pages/transactions_page.dart';
import 'package:monie/features/budgets/presentation/pages/budgets_page.dart';
import 'package:monie/features/groups/presentation/pages/groups_page.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Supabase client
  await SupabaseClientManager.initialize();

  // Setup dependency injection
  await configureDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(GetCurrentUserEvent()),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => getIt<HomeBloc>()..add(const LoadHomeData()),
        ),
        BlocProvider<TransactionsBloc>(
          create:
              (context) =>
                  getIt<TransactionsBloc>()..add(const LoadTransactions()),
        ),
        BlocProvider<BudgetsBloc>(
          create: (context) => getIt<BudgetsBloc>()..add(const LoadBudgets()),
        ),
      ],
      child: MaterialApp(
        title: 'Monie',
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        // Only trigger navigation when auth state changes between authenticated/unauthenticated
        return (previous is Authenticated && current is Unauthenticated) ||
            (previous is Unauthenticated && current is Authenticated) ||
            (previous is AuthInitial);
      },
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is Unauthenticated) {
          // Force navigation to login when unauthenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          });
        }
      },
      builder: (context, state) {
        if (state is AuthInitial) {
          // If we're in initial state, trigger auth check
          context.read<AuthBloc>().add(GetCurrentUserEvent());
          return const _LoadingScreen();
        } else if (state is AuthLoading) {
          return const _LoadingScreen();
        } else if (state is Authenticated) {
          return const MainScreen();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Loading...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const TransactionsPage(),
    const BudgetsPage(),
    const GroupsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // When user is signed out, the AuthWrapper will handle navigation
        // This ensures consistent behavior across the app
      },
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.black, width: 0.5)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_rounded),
                  label: 'Transactions',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.pie_chart_rounded),
                  label: 'Budgets',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz),
                  label: 'More',
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddTransactionModal(context);
          },
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          foregroundColor: AppColors.background,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  void _showAddTransactionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const AddTransactionForm();
      },
    );
  }
}

class AddTransactionForm extends StatefulWidget {
  const AddTransactionForm({super.key});

  @override
  _AddTransactionFormState createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();

  // Form state
  String _transactionType = 'expense';
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _calculatorExpression = '';
  String _selectedCategory = '';
  DateTime _selectedDate = DateTime.now();

  // Step control - 0: title entry, 1: category selection, 2: amount calculator, 3: preview
  int _currentStep = 0;

  // Categories organized by transaction type
  final Map<String, List<Map<String, dynamic>>> _categoriesByType = {
    'expense': [
      {'name': 'Food', 'icon': Icons.restaurant, 'color': Colors.orange},
      {'name': 'Transport', 'icon': Icons.directions_car, 'color': Colors.blue},
      {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Colors.purple},
      {'name': 'Bills', 'icon': Icons.receipt_long, 'color': Colors.red},
      {'name': 'Entertainment', 'icon': Icons.movie, 'color': Colors.pink},
      {'name': 'Health', 'icon': Icons.medical_services, 'color': Colors.green},
      {'name': 'Education', 'icon': Icons.school, 'color': Colors.amber},
      {'name': 'Groceries', 'icon': Icons.shopping_cart, 'color': Colors.teal},
      {'name': 'Rent', 'icon': Icons.home, 'color': Colors.brown},
      {'name': 'Other', 'icon': Icons.more_horiz, 'color': Colors.grey},
    ],
    'income': [
      {'name': 'Salary', 'icon': Icons.work, 'color': Colors.green},
      {'name': 'Freelance', 'icon': Icons.computer, 'color': Colors.blue},
      {'name': 'Gift', 'icon': Icons.card_giftcard, 'color': Colors.purple},
      {'name': 'Investment', 'icon': Icons.trending_up, 'color': Colors.amber},
      {'name': 'Refund', 'icon': Icons.assignment_return, 'color': Colors.teal},
      {'name': 'Other', 'icon': Icons.more_horiz, 'color': Colors.grey},
    ],
  };

  // Helpers for validation and navigation
  bool get _isTitleValid => _titleController.text.isNotEmpty;
  bool get _isCategorySelected => _selectedCategory.isNotEmpty;
  bool get _isAmountValid =>
      _amountController.text.isNotEmpty &&
      double.tryParse(_amountController.text) != null &&
      double.parse(_amountController.text) > 0;

  @override
  void initState() {
    super.initState();
    _amountController.text = '0';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      switch (_currentStep) {
        case 0:
          if (_isTitleValid) _currentStep = 1;
          break;
        case 1:
          if (_isCategorySelected) _currentStep = 2;
          break;
        case 2:
          if (_isAmountValid) _currentStep = 3;
          break;
      }
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  // Calculator methods
  void _updateCalculatorExpression(String value) {
    setState(() {
      if (value == 'C') {
        // Clear the expression
        _calculatorExpression = '';
        _amountController.text = '0';
      } else if (value == '=') {
        // Evaluate the expression
        try {
          // Simple expression evaluation
          _amountController.text = _evaluateExpression(_calculatorExpression);
          _calculatorExpression = '';
        } catch (e) {
          // Invalid expression
          _amountController.text = 'Error';
          _calculatorExpression = '';
        }
      } else if (value == '⌫') {
        // Backspace: remove the last character
        if (_calculatorExpression.isNotEmpty) {
          _calculatorExpression = _calculatorExpression.substring(
            0,
            _calculatorExpression.length - 1,
          );

          if (_calculatorExpression.isEmpty) {
            _amountController.text = '0';
          } else {
            // Try to evaluate current expression
            try {
              _amountController.text = _evaluateExpression(
                _calculatorExpression,
              );
            } catch (e) {
              // Just show the current expression if it can't be evaluated yet
              _amountController.text = _calculatorExpression;
            }
          }
        }
      } else {
        // Add to the expression
        _calculatorExpression += value;

        // Try to evaluate current expression
        try {
          _amountController.text = _evaluateExpression(_calculatorExpression);
        } catch (e) {
          // Just show the current expression if it can't be evaluated yet
          _amountController.text = _calculatorExpression;
        }
      }
    });
  }

  String _evaluateExpression(String expression) {
    // Simple expression evaluation - for more complex cases, consider using a library
    if (expression.isEmpty) return '0';

    // Replace × with * and ÷ with /
    expression = expression.replaceAll('×', '*').replaceAll('÷', '/');

    try {
      // Parse and evaluate the expression
      // This is a simple approach - use a proper math expression parser for production
      final result = _parseExpression(expression);

      // Format the result: show integer if it's a whole number, otherwise show with 2 decimal places
      if (result == result.floorToDouble()) {
        return result.toInt().toString();
      } else {
        return result.toStringAsFixed(2);
      }
    } catch (e) {
      // If the expression can't be evaluated, just return the expression
      return expression;
    }
  }

  double _parseExpression(String expression) {
    // Very basic expression parsing - would need a proper parser for production
    final addSplit = expression.split('+');
    double result = 0;

    for (final addTerm in addSplit) {
      final subSplit = addTerm.split('-');
      double subResult = _parseMultiplicativeTerm(subSplit[0]);

      for (int i = 1; i < subSplit.length; i++) {
        subResult -= _parseMultiplicativeTerm(subSplit[i]);
      }

      result += subResult;
    }

    return result;
  }

  double _parseMultiplicativeTerm(String term) {
    final multSplit = term.split('*');
    double result = 1;

    for (final multTerm in multSplit) {
      final divSplit = multTerm.split('/');
      double divResult = double.tryParse(divSplit[0]) ?? 0;

      for (int i = 1; i < divSplit.length; i++) {
        final divisor = double.tryParse(divSplit[i]) ?? 1;
        if (divisor != 0) {
          divResult /= divisor;
        } else {
          throw Exception('Division by zero');
        }
      }

      result *= divResult;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getStepTitle(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Show transaction type selector only on the category selection step
              if (_currentStep == 1) _buildTransactionTypeSelector(),
              if (_currentStep == 1) SizedBox(height: 16),

              // Content changes based on current step
              Expanded(
                child: SingleChildScrollView(child: _buildCurrentStepContent()),
              ),

              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Enter Transaction Title';
      case 1:
        return 'Select Category';
      case 2:
        return 'Enter Amount';
      case 3:
        return 'Transaction Preview';
      default:
        return 'Add Transaction';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildTitleStep();
      case 1:
        return _buildCategoryStep();
      case 2:
        return _buildCalculatorStep();
      case 3:
        return _buildPreviewStep();
      default:
        return Container();
    }
  }

  Widget _buildTransactionTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap:
                () => setState(() {
                  _transactionType = 'expense';
                  // Clear selected category if switching types
                  if (!_categoriesByType['expense']!.any(
                    (c) => c['name'] == _selectedCategory,
                  )) {
                    _selectedCategory = '';
                  }
                }),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color:
                    _transactionType == 'expense'
                        ? AppColors.expense.withValues(alpha: 0.2)
                        : AppColors.cardDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _transactionType == 'expense'
                          ? AppColors.expense
                          : Colors.transparent,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Expense',
                style: TextStyle(
                  color:
                      _transactionType == 'expense'
                          ? AppColors.expense
                          : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap:
                () => setState(() {
                  _transactionType = 'income';
                  // Clear selected category if switching types
                  if (!_categoriesByType['income']!.any(
                    (c) => c['name'] == _selectedCategory,
                  )) {
                    _selectedCategory = '';
                  }
                }),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color:
                    _transactionType == 'income'
                        ? AppColors.income.withValues(alpha: 0.2)
                        : AppColors.cardDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _transactionType == 'income'
                          ? AppColors.income
                          : Colors.transparent,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Income',
                style: TextStyle(
                  color:
                      _transactionType == 'income'
                          ? AppColors.income
                          : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is this transaction for?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        SizedBox(height: 24),
        TextFormField(
          controller: _titleController,
          style: TextStyle(color: Colors.white, fontSize: 20),
          decoration: InputDecoration(
            hintText: 'e.g., Grocery shopping, Monthly rent',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(8),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (_) => setState(() {}), // Rebuild to update next button
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            if (_isTitleValid) _nextStep();
          },
          autofocus: true,
        ),
      ],
    );
  }

  Widget _buildCategoryStep() {
    final categories = _categoriesByType[_transactionType] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),

        // Categories grid
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = _selectedCategory == category['name'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category['name'];
                });
                // Automatically proceed to next step after selecting a category
                Future.delayed(Duration(milliseconds: 200), _nextStep);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: category['color'].withValues(
                    alpha: isSelected ? 0.3 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? category['color'] : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(category['icon'], color: category['color'], size: 28),
                    SizedBox(height: 8),
                    Text(
                      category['name'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCalculatorStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Show selected category and title as reference
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(_selectedCategory),
                color: _getCategoryColor(_selectedCategory),
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleController.text,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _selectedCategory,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        // Amount display
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Expression indicator (smaller text)
              if (_calculatorExpression.isNotEmpty)
                Text(
                  _calculatorExpression,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.right,
                ),

              // Main amount display
              Text(
                '\$${_amountController.text}',
                style: TextStyle(
                  color:
                      _transactionType == 'expense'
                          ? AppColors.expense
                          : AppColors.income,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        // Calculator layout
        _buildCalculator(),
      ],
    );
  }

  Widget _buildCalculator() {
    return Column(
      children: [
        _buildCalculatorRow(['7', '8', '9', '÷']),
        _buildCalculatorRow(['4', '5', '6', '×']),
        _buildCalculatorRow(['1', '2', '3', '-']),
        _buildCalculatorRow(['0', '.', '⌫', '+']),
        _buildCalculatorRow(['C', '=', '=', '=']),
      ],
    );
  }

  Widget _buildCalculatorRow(List<String> buttons) {
    return Row(
      children:
          buttons.map((button) {
            // Special styling for different button types
            final isOperation = ['+', '-', '×', '÷'].contains(button);
            final isAction = ['C', '=', '⌫'].contains(button);
            final isWideButton = button == '=';

            return Expanded(
              flex: isWideButton ? 3 : 1,
              child: AspectRatio(
                aspectRatio: isWideButton ? 3 : 1,
                child: Container(
                  margin: EdgeInsets.all(4),
                  child: ElevatedButton(
                    onPressed: () => _updateCalculatorExpression(button),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isOperation
                              ? AppColors.primary
                              : isAction
                              ? AppColors.cardDark
                              : Colors.grey.withValues(alpha: 0.2),
                      foregroundColor:
                          isOperation || isAction ? Colors.white : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      button,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildPreviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Transaction',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        SizedBox(height: 16),

        // Transaction summary card
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        _selectedCategory,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(_selectedCategory),
                      color: _getCategoryColor(_selectedCategory),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleController.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              _selectedCategory,
                              style: TextStyle(color: Colors.white70),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d').format(_selectedDate),
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${_amountController.text}',
                    style: TextStyle(
                      color:
                          _transactionType == 'expense'
                              ? AppColors.expense
                              : AppColors.income,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        // Date picker if needed
        GestureDetector(
          onTap: () async {
            // Store context reference before async gap
            final BuildContext currentContext = context;

            final DateTime? picked = await showDatePicker(
              context: currentContext,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      surface: AppColors.cardDark,
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            // Check if still mounted before updating state
            if (!mounted) return;

            if (picked != null) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${DateFormat('EEEE, MMMM d, y').format(_selectedDate)}',
                  style: TextStyle(color: Colors.white),
                ),
                Icon(Icons.calendar_today, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (hidden on first step)
          _currentStep > 0
              ? TextButton.icon(
                onPressed: _previousStep,
                icon: Icon(Icons.arrow_back, color: Colors.white70),
                label: Text('Back', style: TextStyle(color: Colors.white70)),
              )
              : SizedBox(width: 100), // Empty space for alignment
          // Next or Submit button
          if (_currentStep < 3)
            ElevatedButton(
              onPressed: _getNextButtonEnabled() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.3,
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Add Transaction',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _getNextButtonEnabled() {
    switch (_currentStep) {
      case 0:
        return _isTitleValid;
      case 1:
        return _isCategorySelected;
      case 2:
        return _isAmountValid;
      default:
        return true;
    }
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      // Process data and add transaction
      // In a full implementation, this would dispatch an event to the TransactionsBloc
      final transaction = {
        'id': const Uuid().v4(),
        'title': _titleController.text,
        'amount': double.parse(_amountController.text),
        'currency': 'USD',
        'date': _selectedDate.toIso8601String(),
        'category': _selectedCategory,
        'type': _transactionType,
      };

      // Close the form
      Navigator.pop(context);

      // Show confirmation to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction added successfully'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    return CategoryUtils.getCategoryIcon(categoryName);
  }

  Color _getCategoryColor(String categoryName) {
    return CategoryUtils.getCategoryColor(categoryName);
  }
}
