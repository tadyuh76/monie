import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/features/account/domain/entities/account.dart';
import 'package:monie/features/account/presentation/bloc/account_bloc.dart';
import 'package:monie/features/account/presentation/bloc/account_event.dart';
import 'package:monie/features/account/presentation/bloc/account_state.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_event.dart';

class TransactionFormWidget extends StatefulWidget {
  final String userId;
  final Transaction? transaction;
  final Function? onSuccess;

  const TransactionFormWidget({
    super.key,
    required this.userId,
    this.transaction,
    this.onSuccess,
  });

  @override
  State<TransactionFormWidget> createState() => _TransactionFormWidgetState();
}

class _TransactionFormWidgetState extends State<TransactionFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedAccountId;
  String? _selectedBudgetId;
  String? _selectedCategoryName;
  String? _selectedColor;
  bool _isExpense = true;

  @override
  void initState() {
    super.initState();

    // Load accounts and budgets
    context.read<AccountBloc>().add(LoadAccountsEvent(widget.userId));
    context.read<BudgetsBloc>().add(const LoadBudgets());

    // If editing an existing transaction, populate the form
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.abs().toString();
      _descriptionController.text = widget.transaction!.description ?? '';
      _selectedDate = widget.transaction!.date;
      _selectedAccountId = widget.transaction!.accountId;
      _selectedBudgetId = widget.transaction!.budgetId;
      _selectedCategoryName = widget.transaction!.categoryName;
      _selectedColor = widget.transaction!.color;
      _isExpense = widget.transaction!.amount < 0;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Get form values
      final title = _titleController.text;
      final description = _descriptionController.text;

      // Convert amount based on transaction type (income/expense)
      double amount = double.tryParse(_amountController.text) ?? 0;
      if (_isExpense) {
        amount = -amount; // Make amount negative for expenses
      }

      // Create or update transaction
      final transaction = Transaction(
        transactionId: widget.transaction?.transactionId,
        userId: widget.userId,
        title: title,
        description: description,
        amount: amount,
        date: _selectedDate,
        accountId: _selectedAccountId,
        budgetId: _selectedBudgetId,
        categoryName: _selectedCategoryName,
        color: _selectedColor,
      );

      // Dispatch event to create or update transaction
      if (widget.transaction == null) {
        context.read<TransactionBloc>().add(
          CreateTransactionEvent(transaction),
        );
      } else {
        context.read<TransactionBloc>().add(
          UpdateTransactionEvent(transaction),
        );
      }

      // Call the onSuccess callback if provided
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction Type Selector (Income/Expense)
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text(context.tr('transaction_expense')),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(context.tr('transaction_income')),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                  ],
                  selected: {_isExpense},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _isExpense = newSelection.first;
                      // Clear selected budget when transaction type changes
                      _selectedBudgetId = null;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title Field
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: context.tr('transaction_title'),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr('transaction_title_required');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Amount Field
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: context.tr('transaction_amount'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr('transaction_amount_required');
              }
              if (double.tryParse(value) == null) {
                return context.tr('transaction_amount_invalid');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Date Picker
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: context.tr('transaction_date'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
            ),
          ),
          const SizedBox(height: 16),

          // Account Dropdown
          BlocBuilder<AccountBloc, AccountState>(
            builder: (context, state) {
              List<Account> accounts = [];
              if (state is AccountsLoaded) {
                accounts = state.accounts;
              }

              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: context.tr('transaction_account'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                ),
                value: _selectedAccountId,
                items:
                    accounts.map((account) {
                      return DropdownMenuItem<String>(
                        value: account.accountId,
                        child: Text(account.name),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAccountId = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('transaction_account_required');
                  }
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Budget Dropdown - Filter based on transaction type
          BlocBuilder<BudgetsBloc, BudgetsState>(
            builder: (context, state) {
              List<Budget> allBudgets = [];
              if (state is BudgetsLoaded) {
                allBudgets = state.budgets;
              }

              // Filter budgets based on transaction type
              final matchingBudgets =
                  allBudgets.where((budget) {
                    if (_isExpense) {
                      return !budget
                          .isSaving; // Expense budgets (isSaving = false)
                    } else {
                      return budget
                          .isSaving; // Income budgets (isSaving = true)
                    }
                  }).toList();

              // Check if selected budget is still valid after filtering
              if (_selectedBudgetId != null) {
                final stillValid = matchingBudgets.any(
                  (budget) => budget.budgetId == _selectedBudgetId,
                );
                if (!stillValid) {
                  _selectedBudgetId = null;
                }
              }

              final String budgetLabel =
                  _isExpense
                      ? context.tr('transaction_expense_budget')
                      : context.tr('transaction_income_budget');

              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: budgetLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.pie_chart),
                  helperText:
                      matchingBudgets.isEmpty
                          ? 'No ${_isExpense ? "expense" : "income"} budgets available'
                          : null,
                ),
                value: _selectedBudgetId,
                items:
                    matchingBudgets.isEmpty
                        ? [
                          DropdownMenuItem<String>(
                            value: null,
                            enabled: false,
                            child: Text(
                              'No ${_isExpense ? "expense" : "income"} budgets available',
                            ),
                          ),
                        ]
                        : matchingBudgets.map((budget) {
                          return DropdownMenuItem<String>(
                            value: budget.budgetId,
                            child: Row(
                              children: [
                                Text(budget.name),
                                const Spacer(),
                                Text(
                                  '\$${budget.remaining.toStringAsFixed(2)} left',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                onChanged:
                    matchingBudgets.isEmpty
                        ? null
                        : (value) {
                          setState(() {
                            _selectedBudgetId = value;
                          });
                        },
                validator: (value) {
                  // Budget is optional, no validation needed
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Description Field
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: context.tr('transaction_description'),
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.transaction == null
                    ? context.tr('transaction_create')
                    : context.tr('transaction_update'),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
