import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/constants/category_icons.dart';
import 'package:monie/core/constants/transaction_categories.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/category_utils.dart';
import 'package:monie/features/account/presentation/bloc/account_bloc.dart';
import 'package:monie/features/account/presentation/bloc/account_event.dart';
import 'package:monie/features/account/presentation/bloc/account_state.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';

// Extension to add capitalize method to String
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class AddTransactionForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSubmit;
  final dynamic
  transaction; // Accept a transaction for editing (can be Transaction or Map)

  const AddTransactionForm({super.key, this.onSubmit, this.transaction});

  @override
  AddTransactionFormState createState() => AddTransactionFormState();
}

class AddTransactionFormState extends State<AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();

  // Form state
  String _transactionType = 'expense';
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _calculatorExpression = '';
  Map<String, dynamic>? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  String? _selectedAccountId;
  String? _selectedBudgetId;

  // Step control - 0: title entry, 1: category selection, 2: amount calculator, 3: additional info
  int _currentStep = 0;

  // Track whether form submission is in progress to prevent double submission
  bool _isSubmitting = false;

  // Helper getters for validation
  bool get _isTitleValid => _titleController.text.isNotEmpty;
  bool get _isCategorySelected => _selectedCategory != null;
  bool get _isAmountValid =>
      _amountController.text.isNotEmpty &&
      double.tryParse(_amountController.text) != null &&
      double.parse(_amountController.text) > 0;
  bool get _isAdditionalInfoValid => _selectedAccountId != null;

  // Icon mapping utility
  IconData getIconData(String? iconString) {
    // Simply return a default icon regardless of the string
    // The complex parsing was causing issues
    return Icons.category;
  }

  // Helper method to safely parse color from hex string
  Color _parseColor(String? colorHex, Color defaultColor) {
    if (colorHex == null || colorHex.isEmpty) {
      return defaultColor;
    }

    try {
      // Remove # prefix if present
      final cleanHex =
          colorHex.startsWith('#') ? colorHex.substring(1) : colorHex;
      return Color(int.parse('0xFF$cleanHex'));
    } catch (e) {
      return defaultColor;
    }
  }

  @override
  void initState() {
    super.initState();
    _amountController.text = '0';
    _selectedAccountId = null; // Initialize as null instead of '1'

    // If editing, prefill fields
    if (widget.transaction != null) {
      final t = widget.transaction;
      _titleController.text = t.title ?? '';
      _amountController.text =
          t.amount != null ? t.amount.abs().toString() : '0';
      _descriptionController.text = t.description ?? '';
      _selectedDate = t.date ?? DateTime.now();
      _selectedCategory =
          t.categoryName != null ? {'name': t.categoryName} : null;
      _transactionType =
          (t.amount != null && t.amount < 0) ? 'expense' : 'income';
      _selectedAccountId = t.accountId;
      _selectedBudgetId = t.budgetId;
      _isRecurring = t.isRecurring ?? false;
    }

    // Load user accounts when the form is initialized
    _loadUserAccounts();

    // Load budgets when the form is initialized
    _loadBudgets();
  }

  void _loadUserAccounts() {
    final accountBloc = context.read<AccountBloc>();
    // Check if accounts are already loaded
    final state = accountBloc.state;
    if (state is! AccountsLoaded) {
      // Get the authenticated user ID from AuthBloc
      try {
        final authBloc = context.read<AuthBloc>();
        final authState = authBloc.state;
        if (authState is Authenticated) {
          accountBloc.add(LoadAccountsEvent(authState.user.id));
        }
      } catch (e) {
        // If AuthBloc is not available, we can't load accounts
      }
    }
  }

  void _loadBudgets() {
    final budgetsBloc = context.read<BudgetsBloc>();
    // Load active budgets
    budgetsBloc.add(const LoadActiveBudgets());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
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
        case 3:
          if (_isAdditionalInfoValid) _saveTransaction();
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

  void _updateCalculatorExpression(String value) {
    setState(() {
      if (value == 'C') {
        // Clear the expression
        _calculatorExpression = '';
        _amountController.text = '0';
      } else if (value == '=') {
        // Evaluate the expression
        try {
          _amountController.text = _evaluateExpression(_calculatorExpression);
          _calculatorExpression = '';
        } catch (e) {
          _amountController.text = 'Error';
          _calculatorExpression = '';
        }
      } else if (value == '⌫') {
        // Backspace
        if (_calculatorExpression.isNotEmpty) {
          _calculatorExpression = _calculatorExpression.substring(
            0,
            _calculatorExpression.length - 1,
          );

          if (_calculatorExpression.isEmpty) {
            _amountController.text = '0';
          } else {
            try {
              _amountController.text = _evaluateExpression(
                _calculatorExpression,
              );
            } catch (e) {
              _amountController.text = _calculatorExpression;
            }
          }
        }
      } else {
        // Add to expression
        _calculatorExpression += value;
        try {
          _amountController.text = _evaluateExpression(_calculatorExpression);
        } catch (e) {
          _amountController.text = _calculatorExpression;
        }
      }
    });
  }

  String _evaluateExpression(String expression) {
    if (expression.isEmpty) return '0';

    // Replace × with * and ÷ with /
    expression = expression.replaceAll('×', '*').replaceAll('÷', '/');

    try {
      final result = _parseExpression(expression);

      // Format the result
      if (result == result.floorToDouble()) {
        return result.toInt().toString();
      } else {
        return result.toStringAsFixed(2);
      }
    } catch (e) {
      return expression;
    }
  }

  double _parseExpression(String expression) {
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

  void _saveTransaction() async {
    // Prevent duplicate submissions
    if (_isSubmitting) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Make sure we have a category
    if (_selectedCategory == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category first'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Set submission state to prevent duplicates
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Adjust amount based on transaction type
      double amount = double.parse(_amountController.text);
      if (_transactionType == 'expense') {
        amount = -amount; // Make it negative for expenses
      }

      // Get the category name
      String categoryName = _selectedCategory!['name'] as String;

      // Get the category color hex code using CategoryUtils
      String categoryColorHex = CategoryUtils.getCategoryColorHex(categoryName);

      // Build transaction data with category name and color
      final transactionData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'amount': amount,
        'date': _selectedDate.toIso8601String(),
        'category_name': categoryName,
        'category_color': categoryColorHex,
        'is_recurring': _isRecurring,
        'account_id': _selectedAccountId,
        'budget_id': _selectedBudgetId,
      };

      // Call onSubmit if available
      if (widget.onSubmit != null) {
        widget.onSubmit!(transactionData);
      }

      // Close form immediately - snackbar will be shown by the bloc listener
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Reset submission state if there's an error
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      // Use 80% of screen height
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.background : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow:
            isDarkMode
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
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
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Transaction type selector (only on category selection step)
              if (_currentStep == 1) _buildTransactionTypeSelector(),
              if (_currentStep == 1) const SizedBox(height: 16),

              // Step content
              Flexible(
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
        return 'Enter Transaction Details';
      case 1:
        return 'Select Category';
      case 2:
        return 'Enter Amount';
      case 3:
        return 'Additional Information';
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
        return _buildAdditionalInfoStep();
      default:
        return Container();
    }
  }

  Widget _buildTransactionTypeSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_transactionType != 'expense') {
                setState(() {
                  _transactionType = 'expense';
                  _selectedCategory =
                      null; // Reset category when switching types
                });
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color:
                    _transactionType == 'expense'
                        ? AppColors.expense.withValues(alpha: 0.2)
                        : isDarkMode
                        ? AppColors.cardDark
                        : Colors.grey.shade100,
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
                          : isDarkMode
                          ? Colors.white
                          : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_transactionType != 'income') {
                setState(() {
                  _transactionType = 'income';
                  _selectedCategory =
                      null; // Reset category when switching types
                });
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color:
                    _transactionType == 'income'
                        ? AppColors.income.withValues(alpha: 0.2)
                        : isDarkMode
                        ? AppColors.cardDark
                        : Colors.grey.shade100,
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
                          : isDarkMode
                          ? Colors.white
                          : Colors.black87,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Title',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _titleController,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            hintText: 'e.g., Grocery shopping, Monthly rent',
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.white54 : Colors.black38,
            ),
            filled: true,
            fillColor: isDarkMode ? AppColors.cardDark : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            if (_isTitleValid) _nextStep();
          },
          autofocus: true,
        ),
        SizedBox(height: 20),

        Text(
          'Description (Optional)',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Add notes about this transaction',
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.white54 : Colors.black38,
            ),
            filled: true,
            fillColor: isDarkMode ? AppColors.cardDark : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildCategoryStep() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final categories =
        _transactionType == 'expense'
            ? TransactionCategories.expenseCategories
            : TransactionCategories.incomeCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a category',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryItem(category);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final isSelected =
        _selectedCategory != null &&
        _selectedCategory!['name'] == category['name'];

    String svgName = category['svgName'].toString();
    String iconPath = CategoryIcons.getIconPath(svgName);
    Color borderColor = isSelected ? Colors.white : Colors.transparent;

    // Get category color using CategoryUtils
    category['name'].toString().toLowerCase();
    Color categoryColor = CategoryUtils.getCategoryColor(svgName);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
        // Auto-proceed to next step after a short delay
        Future.delayed(Duration(milliseconds: 300), _nextStep);
      },
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : categoryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(iconPath),
            ),
            SizedBox(height: 8),
            Text(
              category['name'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorStep() {
    String categoryName =
        _selectedCategory?['name']?.toString().toLowerCase() ?? '';
    String iconPath = CategoryIcons.getIconPath(categoryName);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isDarkMode ? AppColors.cardDark : Colors.grey.shade100;
    final operatorColor = AppColors.primary;

    // Calculator layout

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Show selected category and title as reference
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(iconPath),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleController.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _selectedCategory?['name'] as String? ?? 'Uncategorized',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Amount display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardDark : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_calculatorExpression.isNotEmpty)
                Text(
                  _calculatorExpression,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white60 : Colors.black54,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _transactionType == 'expense' ? '-' : '+',
                    style: TextStyle(
                      fontSize: 32,
                      color:
                          _transactionType == 'expense'
                              ? AppColors.expense
                              : AppColors.income,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${_amountController.text}',
                    style: TextStyle(
                      fontSize: 32,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calculator buttons
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          childAspectRatio: 1.3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildCalcButton('7', buttonColor, isDarkMode),
            _buildCalcButton('8', buttonColor, isDarkMode),
            _buildCalcButton('9', buttonColor, isDarkMode),
            _buildCalcButton('÷', operatorColor, isDarkMode, isOperator: true),
            _buildCalcButton('4', buttonColor, isDarkMode),
            _buildCalcButton('5', buttonColor, isDarkMode),
            _buildCalcButton('6', buttonColor, isDarkMode),
            _buildCalcButton('×', operatorColor, isDarkMode, isOperator: true),
            _buildCalcButton('1', buttonColor, isDarkMode),
            _buildCalcButton('2', buttonColor, isDarkMode),
            _buildCalcButton('3', buttonColor, isDarkMode),
            _buildCalcButton('-', operatorColor, isDarkMode, isOperator: true),
            _buildCalcButton('0', buttonColor, isDarkMode),
            _buildCalcButton('.', buttonColor, isDarkMode),
            _buildCalcButton(
              'C',
              AppColors.expense,
              isDarkMode,
              isOperator: true,
            ),
            _buildCalcButton('+', operatorColor, isDarkMode, isOperator: true),
          ],
        ),
      ],
    );
  }

  Widget _buildCalcButton(
    String text,
    Color bgColor,
    bool isDarkMode, {
    bool isOperator = false,
  }) {
    final textColor =
        isOperator
            ? Colors.white
            : isDarkMode
            ? Colors.white
            : Colors.black87;

    return InkWell(
      onTap: () => _updateCalculatorExpression(text),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoStep() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date selector
        Text(
          'Date',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            if (!mounted) return;
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (BuildContext context, Widget? child) {
                if (!mounted) return child!;
                return Theme(
                  data:
                      isDarkMode
                          ? ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                              surface: AppColors.surface,
                              onSurface: Colors.white,
                            ),
                            dialogTheme: DialogThemeData(
                              backgroundColor: AppColors.surface,
                            ),
                          )
                          : ThemeData.light().copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black87,
                            ),
                          ),
                  child: child!,
                );
              },
            );
            if (!mounted) return;
            if (pickedDate != null) {
              setState(() {
                _selectedDate = pickedDate;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.cardDark : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Recurring transaction toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recurring Transaction',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            Switch(
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                });
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Account selector (dropdown)
        Text(
          'Account',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardDark : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: BlocBuilder<AccountBloc, AccountState>(
            builder: (context, state) {
              if (state is AccountLoading) {
                return const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              } else if (state is AccountsLoaded) {
                final accounts = state.accounts;

                // If no account is selected and we have accounts, select the first one
                if (_selectedAccountId == null && accounts.isNotEmpty) {
                  // Select the first account by default
                  _selectedAccountId = accounts.first.accountId;
                }

                return DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAccountId,
                    hint: Text(
                      'Select Account',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    isExpanded: true,
                    dropdownColor:
                        isDarkMode ? AppColors.surface : Colors.white,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    items:
                        accounts.map((account) {
                          // Use a color based on account type
                          Color accountColor;
                          switch (account.type.toLowerCase()) {
                            case 'cash':
                              accountColor = AppColors.cash;
                              break;
                            case 'bank':
                              accountColor = AppColors.bank;
                              break;
                            case 'credit card':
                            case 'credit':
                              accountColor = AppColors.credit;
                              break;
                            case 'investment':
                              accountColor = AppColors.investment;
                              break;
                            case 'savings':
                              accountColor = AppColors.savings;
                              break;
                            default:
                              accountColor = AppColors.primary;
                          }

                          return DropdownMenuItem(
                            value: account.accountId,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: accountColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(account.name),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAccountId = value;
                      });
                    },
                  ),
                );
              } else {
                // If there's an error or no accounts loaded, show a message
                if (state is AccountError) {}
                return Text(
                  'No accounts available',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                );
              }
            },
          ),
        ),

        const SizedBox(height: 24),

        // Budget selector (dropdown)
        Text(
          'Budget (Optional)',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardDark : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: BlocBuilder<BudgetsBloc, BudgetsState>(
            builder: (context, state) {
              if (state is BudgetsLoading) {
                return const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              } else if (state is BudgetsLoaded) {
                final allBudgets = state.budgets;

                // Filter budgets based on transaction type
                final filteredBudgets =
                    allBudgets.where((budget) {
                      final isExpenseBudget = !budget.isSaving;
                      final isIncomeBudget = budget.isSaving;

                      if (_transactionType == 'expense') {
                        return isExpenseBudget;
                      } else {
                        return isIncomeBudget;
                      }
                    }).toList();

                // Check if selected budget is still valid after filtering
                if (_selectedBudgetId != null) {
                  final stillValid = filteredBudgets.any(
                    (budget) => budget.budgetId == _selectedBudgetId,
                  );
                  if (!stillValid) {
                    _selectedBudgetId = null;
                  }
                }

                if (filteredBudgets.isEmpty) {
                  return Text(
                    'No $_transactionType budgets available',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  );
                }

                return DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBudgetId,
                    hint: Text(
                      'Select ${_transactionType.capitalize()} Budget',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    isExpanded: true,
                    dropdownColor:
                        isDarkMode ? AppColors.surface : Colors.white,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    items: [
                      // Add a "None" option
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'None',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                      // Add filtered budgets
                      ...filteredBudgets.map((budget) {
                        // Parse color from hex string or use default
                        Color budgetColor;
                        try {
                          if (budget.color != null) {
                            budgetColor = _parseColor(
                              budget.color,
                              AppColors.primary,
                            );
                          } else {
                            budgetColor = AppColors.primary;
                          }
                        } catch (e) {
                          budgetColor = AppColors.primary;
                        }

                        return DropdownMenuItem(
                          value: budget.budgetId,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: budgetColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  budget.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '\$${budget.remaining.toStringAsFixed(0)} left',
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? Colors.white60
                                          : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedBudgetId = value;
                      });
                    },
                  ),
                );
              } else {
                // If there's an error or no budgets loaded, show a message
                return Text(
                  'No budgets available',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button for all steps except the first
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDarkMode ? Colors.white30 : Colors.grey.shade400,
                ),
                foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Back'),
            )
          else
            const SizedBox(width: 0), // Empty space if no back button
          // Next or Save button
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(_currentStep == 3 ? 'Save Transaction' : 'Next'),
          ),
        ],
      ),
    );
  }
}
