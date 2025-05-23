import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/constants/category_icons.dart';
import 'package:monie/core/constants/transaction_categories.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/category_utils.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/presentation/bloc/transactions_bloc.dart';

class TransactionForm extends StatefulWidget {
  final Transaction? transaction;
  final String userId;

  const TransactionForm({super.key, this.transaction, required this.userId});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isIncome = false;
  Map<String, dynamic>? _selectedCategory;
  String? _selectedCategoryName;
  String? _selectedAccountId;
  String? _selectedBudgetId;

  @override
  void initState() {
    super.initState();

    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.amount.abs().toString();
      _descriptionController.text = widget.transaction!.description ?? '';
      _titleController.text = widget.transaction!.title;
      _selectedDate = widget.transaction!.date;
      _isIncome = widget.transaction!.amount >= 0;

      // Find the category from proper category list based on transaction type
      if (widget.transaction!.categoryName != null) {
        _selectedCategoryName = widget.transaction!.categoryName;
        final allCategories =
            _isIncome
                ? TransactionCategories.incomeCategories
                : TransactionCategories.expenseCategories;

        _selectedCategory = allCategories.firstWhere(
          (category) => category['name'] == widget.transaction!.categoryName,
          orElse:
              () => {
                'name': widget.transaction!.categoryName!,
                'svgName': _isIncome ? 'salary' : 'shopping',
                'color': widget.transaction!.color ?? '#9E9E9E',
              },
        );
      }

      _selectedAccountId = widget.transaction!.accountId;
      _selectedBudgetId = widget.transaction!.budgetId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;
      final title = _titleController.text;

      // Apply sign based on income/expense
      final signedAmount = _isIncome ? amount : -amount;

      // Ensure a category is selected
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('transactions_category_required')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final categoryName = _selectedCategory!['name'] as String;
      final categoryColor = CategoryColorHelper.getHexColorForCategory(
        _selectedCategory!['svgName'] as String,
      );

      if (widget.transaction == null) {
        // Add new transaction
        context.read<TransactionsBloc>().add(
          AddNewTransaction(
            amount: signedAmount,
            description: description,
            title: title,
            date: _selectedDate,
            userId: widget.userId,
            categoryName: categoryName,
            categoryColor: categoryColor,
            accountId: _selectedAccountId,
            budgetId: _selectedBudgetId,
            isIncome: _isIncome,
          ),
        );
      } else {
        // Update existing transaction
        final updatedTransaction = Transaction(
          transactionId: widget.transaction!.transactionId,
          amount: signedAmount,
          description: description,
          title: title,
          date: _selectedDate,
          userId: widget.userId,
          categoryName: categoryName,
          color: categoryColor,
          accountId: _selectedAccountId,
          budgetId: _selectedBudgetId,
          isRecurring: widget.transaction!.isRecurring,
          receiptUrl: widget.transaction!.receiptUrl,
        );

        context.read<TransactionsBloc>().add(
          UpdateExistingTransaction(updatedTransaction),
        );
      }

      Navigator.pop(context);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!mounted) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        if (!mounted) return child!;
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

    if (!mounted) return;
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Make sure we have a default category selected
    if (_selectedCategory == null) {
      final categories =
          _isIncome
              ? TransactionCategories.incomeCategories
              : TransactionCategories.expenseCategories;

      if (categories.isNotEmpty) {
        _selectedCategory = categories.first;
        _selectedCategoryName = _selectedCategory!['name'] as String;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.transaction == null
                      ? context.tr('transactions_add_new')
                      : context.tr('common_edit'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Income/Expense Toggle
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isIncome = false;
                        // Reset category selection when switching type
                        _selectedCategory = null;
                        _selectedCategoryName = null;

                        // Set a default category for expense
                        if (TransactionCategories
                            .expenseCategories
                            .isNotEmpty) {
                          _selectedCategory =
                              TransactionCategories.expenseCategories.first;
                          _selectedCategoryName =
                              _selectedCategory!['name'] as String;
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          !_isIncome ? AppColors.expense : AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      context.tr('home_expense'),
                      style: TextStyle(
                        color: !_isIncome ? Colors.white : Colors.white70,
                        fontWeight:
                            !_isIncome ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isIncome = true;
                        // Reset category selection when switching type
                        _selectedCategory = null;
                        _selectedCategoryName = null;

                        // Set a default category for income
                        if (TransactionCategories.incomeCategories.isNotEmpty) {
                          _selectedCategory =
                              TransactionCategories.incomeCategories.first;
                          _selectedCategoryName =
                              _selectedCategory!['name'] as String;
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isIncome ? AppColors.income : AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      context.tr('home_income'),
                      style: TextStyle(
                        color: _isIncome ? Colors.white : Colors.white70,
                        fontWeight:
                            _isIncome ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Title Field
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: context.tr('transactions_title'),
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.title, color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.tr('field_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: context.tr('transactions_amount'),
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(
                  Icons.attach_money,
                  color: Colors.white70,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.tr('transactions_amount');
                }
                if (double.tryParse(value) == null) {
                  return context.tr('budget_amount_valid');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category Selection
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            const SizedBox(height: 16),

            // Date Picker
            Text(
              context.tr('transactions_date'),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMd().format(_selectedDate),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Icon(Icons.calendar_today, color: Colors.white70),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.tr('transactions_description'),
                labelStyle: const TextStyle(color: Colors.white70),
                alignLabelWithHint: true,
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.transaction == null
                      ? context.tr('transactions_add_new')
                      : context.tr('common_save'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categories =
        _isIncome
            ? TransactionCategories.incomeCategories
            : TransactionCategories.expenseCategories;

    return DropdownButtonFormField<String>(
      value: _selectedCategoryName,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
      decoration: InputDecoration(
        labelText: context.tr('transactions_category'),
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.category, color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: Colors.white),
      itemHeight: 60,
      items:
          categories.map((category) {
            final String categoryName = category['name'] as String;
            final String iconPath = CategoryIcons.getIconPath(categoryName);

            // Get category color from helper class
            Color backgroundColor = Colors.white.withValues(alpha: 0.1);
            final String colorHex =
                TransactionCategories.getCategoryColorByName(categoryName);
            Color categoryColor = CategoryUtils.hexToColor(colorHex);
            backgroundColor = categoryColor.withValues(alpha: 0.2);

            return DropdownMenuItem<String>(
              value: categoryName,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(iconPath),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    categoryName,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            );
          }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategoryName = value;
            // Find the category from correct category list
            final allCategories =
                _isIncome
                    ? TransactionCategories.incomeCategories
                    : TransactionCategories.expenseCategories;

            _selectedCategory = allCategories.firstWhere(
              (category) => category['name'] == value,
              orElse:
                  () => {
                    'name': value,
                    'svgName': _isIncome ? 'salary' : 'shopping',
                  },
            );
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return context.tr('field_required');
        }
        return null;
      },
    );
  }
}
