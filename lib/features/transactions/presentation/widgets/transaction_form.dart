import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
  String? _selectedAccountId;
  String? _selectedBudgetId;

  @override
  void initState() {
    super.initState();

    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.amount.abs().toString();
      _descriptionController.text = widget.transaction!.description;
      _titleController.text = widget.transaction!.title;
      _selectedDate = widget.transaction!.date;
      _isIncome = widget.transaction!.amount >= 0;

      // Find the category from CategoryUtils using categoryName
      if (widget.transaction!.categoryName != null) {
        _selectedCategory = CategoryUtils.categories.firstWhere(
          (category) => category['name'] == widget.transaction!.categoryName,
          orElse:
              () => {
                'name': widget.transaction!.categoryName!,
                'icon': Icons.more_horiz,
                'color': Colors.grey,
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
          const SnackBar(
            content: Text('Please select a category'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final categoryName = _selectedCategory!['name'] as String;
      final categoryColor = CategoryUtils.colorToHex(
        _selectedCategory!['color'] as Color,
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
          id: widget.transaction!.id,
          amount: signedAmount,
          description: description,
          title: title,
          date: _selectedDate,
          userId: widget.userId,
          categoryName: categoryName,
          categoryColor: categoryColor,
          accountId: _selectedAccountId,
          budgetId: _selectedBudgetId,
          isRecurring: widget.transaction!.isRecurring,
          receiptUrl: widget.transaction!.receiptUrl,
          createdAt: widget.transaction!.createdAt,
          updatedAt: DateTime.now(),
        );

        context.read<TransactionsBloc>().add(
          UpdateExistingTransaction(updatedTransaction),
        );
      }

      Navigator.pop(context);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      ? 'Add Transaction'
                      : 'Edit Transaction',
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
            const SizedBox(height: 16),

            // Income/Expense Toggle
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isIncome = false;
                        _selectedCategory =
                            null; // Reset category when switching type
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          !_isIncome ? AppColors.expense : AppColors.surface,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Expense',
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
                        _selectedCategory =
                            null; // Reset category when switching type
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isIncome ? AppColors.income : AppColors.surface,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Income',
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
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.title, color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.attach_money, color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category Selection
            Text(
              'Category',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemCount:
                    _isIncome
                        ? CategoryUtils.getIncomeCategories().length
                        : CategoryUtils.getExpenseCategories().length,
                itemBuilder: (context, index) {
                  final categories =
                      _isIncome
                          ? CategoryUtils.getIncomeCategories()
                          : CategoryUtils.getExpenseCategories();
                  final category = categories[index];
                  final isSelected = _selectedCategory == category;
                  final categoryColor = category['color'] as Color;
                  final categoryIcon = category['icon'] as IconData;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(
                          isSelected ? 0.3 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected ? categoryColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(categoryIcon, color: categoryColor, size: 28),
                          SizedBox(height: 4),
                          Text(
                            category['name'] as String,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Date Picker
            Text('Date', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMd().format(_selectedDate),
                      style: TextStyle(color: Colors.white),
                    ),
                    Icon(Icons.calendar_today, color: Colors.white70),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.white70),
                alignLabelWithHint: true,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.transaction == null
                      ? 'Add Transaction'
                      : 'Update Transaction',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
