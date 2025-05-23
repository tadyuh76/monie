import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';

class BudgetFormBottomSheet extends StatefulWidget {
  final Budget? budget;

  const BudgetFormBottomSheet({super.key, this.budget});

  @override
  State<BudgetFormBottomSheet> createState() => _BudgetFormBottomSheetState();
}

class _BudgetFormBottomSheetState extends State<BudgetFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedColor = 'blue';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isRecurring = false;
  String _frequency = 'monthly';

  bool get _isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.budget!.name;
      _amountController.text = widget.budget!.amount.toString();
      _selectedColor = widget.budget!.color ?? 'blue';
      _startDate = widget.budget!.startDate;
      _endDate = widget.budget!.endDate;
      _isRecurring = widget.budget!.isRecurring;
      _frequency = widget.budget!.frequency ?? 'monthly';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
                    _isEditing
                        ? context.tr('budget_edit')
                        : context.tr('budget_new'),
                    style: textTheme.titleLarge?.copyWith(
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

              // Budget name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: context.tr('budget_name'),
                  hintText: context.tr('budget_name_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.assignment),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('budget_name_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Budget amount field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('budget_amount'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('budget_amount_required');
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return context.tr('budget_amount_valid');
                  }
                  if (amount <= 0) {
                    return context.tr('budget_amount_positive');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date range selection
              // Text(
              //   context.tr('budget_date_range'),
              //   style: textTheme.titleMedium?.copyWith(
              //     color: isDarkMode ? Colors.white : Colors.black87,
              //   ),
              // ),
              // const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: context.tr('budgets_start_date'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Text(DateFormat.yMd().format(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: context.tr('budgets_end_date'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          _endDate != null
                              ? DateFormat.yMd().format(_endDate!)
                              : '-',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Options section
              Text(
                context.tr('budget_options'),
                style: textTheme.titleMedium?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Recurring switch
              SwitchListTile(
                title: Text(context.tr('budget_recurring')),
                subtitle: Text(context.tr('budget_recurring_description')),
                value: _isRecurring,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                  });
                },
              ),

              // Frequency dropdown (only if recurring)
              if (_isRecurring)
                DropdownButtonFormField<String>(
                  value: _frequency,
                  decoration: InputDecoration(
                    labelText: context.tr('budget_frequency'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'daily',
                      child: Text(context.tr('budget_daily')),
                    ),
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text(context.tr('budget_weekly')),
                    ),
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text(context.tr('budget_monthly')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _frequency = value;
                      });
                    }
                  },
                ),
              const SizedBox(height: 16),

              // Color selection
              Text(
                context.tr('budget_color'),
                style: textTheme.titleMedium?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildColorOption('blue', Colors.blue),
                    _buildColorOption('green', Colors.green),
                    _buildColorOption('purple', Colors.purple),
                    _buildColorOption('orange', Colors.orange),
                    _buildColorOption('red', Colors.red),
                    _buildColorOption('teal', Colors.teal),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isEditing
                        ? context.tr('common_save')
                        : context.tr('budget_create'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(String colorName, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = colorName;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border:
              _selectedColor == colorName
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child:
            _selectedColor == colorName
                ? const Icon(Icons.check, color: Colors.white)
                : null,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: isStartDate ? DateTime.now() : _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Ensure end date is after start date
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('budget_auth_required')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final name = _nameController.text;
      final amount = double.parse(_amountController.text);
      final userId = authState.user.id;

      if (_isEditing) {
        // Update existing budget
        final updatedBudget = Budget(
          budgetId: widget.budget!.budgetId,
          userId: userId,
          name: name,
          amount: amount,
          startDate: _startDate,
          endDate: _endDate,
          color: _selectedColor,
          isRecurring: _isRecurring,
          frequency: _frequency,
        );
        context.read<BudgetsBloc>().add(UpdateBudget(updatedBudget));
      } else {
        // Create new budget
        final newBudget = Budget(
          budgetId: '',
          userId: userId,
          name: name,
          amount: amount,
          startDate: _startDate,
          endDate: _endDate,
          color: _selectedColor,
          isRecurring: _isRecurring,
          frequency: _frequency,
        );
        context.read<BudgetsBloc>().add(AddBudget(newBudget));
      }

      Navigator.pop(context);
    }
  }
}
