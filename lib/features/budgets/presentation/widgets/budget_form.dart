import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/budgets/data/models/budget_model.dart';
import 'package:monie/features/budgets/domain/entities/budget.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';

class BudgetForm extends StatefulWidget {
  final Budget? budget; // Null for new budget, non-null for editing

  const BudgetForm({super.key, this.budget});

  @override
  State<BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isRecurring = false;
  bool _isSaving = false;
  String? _categoryId;
  String? _frequency;
  String _color = 'FF4CAF50'; // Default green color

  @override
  void initState() {
    super.initState();

    // If editing an existing budget, populate the form
    if (widget.budget != null) {
      _nameController.text = widget.budget!.name;
      _amountController.text = widget.budget!.totalAmount.toString();
      _startDate = widget.budget!.startDate;
      _endDate = widget.budget!.endDate;
      _isRecurring = widget.budget!.isRecurring;
      _isSaving = widget.budget!.isSaving;
      _categoryId = widget.budget!.categoryId;
      _frequency = widget.budget!.frequency;
      if (widget.budget!.color != null && widget.budget!.color!.isNotEmpty) {
        _color = widget.budget!.color!;
      }
    } else {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Helper method to format display text without underscores
  String _formatDisplayText(String text) {
    if (text.contains('_')) {
      List<String> words = text.split('_');
      return words
          .map(
            (word) =>
                word.isNotEmpty
                    ? '${word[0].toUpperCase()}${word.substring(1)}'
                    : '',
          )
          .join(' ');
    }
    return text;
  }

  // Helper method to translate text and remove underscores for display
  String _trDisplay(String key) {
    String translated = context.tr(key);
    // If translation failed (key is returned), format the key for display
    if (translated == key) {
      return _formatDisplayText(key);
    }
    return translated;
  }

  // Date picker methods
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;

        // Ensure end date is after start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _endDate.isAfter(_startDate)
              ? _endDate
              : _startDate.add(const Duration(days: 1)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final double amount = double.parse(_amountController.text);

      // Debug logs

      // Create or update budget
      final budget =
          widget.budget == null
              ? BudgetModel.create(
                name: _nameController.text,
                amount: amount,
                startDate: _startDate,
                endDate: _endDate,
                categoryId: _categoryId,
                isRecurring: _isRecurring,
                isSaving: _isSaving,
                frequency: _frequency,
                color: _color,
              )
              : BudgetModel(
                id: widget.budget!.id,
                name: _nameController.text,
                totalAmount: amount,
                spentAmount: widget.budget!.spentAmount,
                remainingAmount: amount - widget.budget!.spentAmount,
                currency: widget.budget!.currency,
                startDate: _startDate,
                endDate: _endDate,
                category: widget.budget!.category,
                categoryId: _categoryId,
                progressPercentage: widget.budget!.progressPercentage,
                dailySavingTarget: widget.budget!.dailySavingTarget,
                daysRemaining: _endDate.difference(DateTime.now()).inDays,
                userId: widget.budget!.userId,
                isRecurring: _isRecurring,
                isSaving: _isSaving,
                frequency: _frequency,
                color: _color,
              );

      // Debug log

      // Dispatch event to bloc
      if (widget.budget == null) {
        context.read<BudgetsBloc>().add(AddBudget(budget));
      } else {
        context.read<BudgetsBloc>().add(UpdateBudget(budget));
      }

      // Close the form
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.background : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.background : Colors.white,
        elevation: 0,
        title: Text(
          widget.budget == null
              ? _trDisplay('budget_new')
              : _trDisplay('budget_edit'),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: Text(
              context.tr('common_save'),
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Budget name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "${_trDisplay('budget_name')} *",
                  hintText: _trDisplay('budget_name_hint'),
                  border: const OutlineInputBorder(),
                  helperText: context.tr('field_required'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('budget_name_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Budget amount
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: "${_trDisplay('budget_amount')} *",
                  border: const OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('budget_amount_required');
                  }
                  try {
                    final amount = double.parse(value);
                    if (amount <= 0) {
                      return context.tr('budget_amount_positive');
                    }
                  } catch (e) {
                    return context.tr('budget_amount_valid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Date range
              Text(
                _trDisplay('budget_date_range'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectStartDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: _trDisplay('budget_start_date'),
                        ),
                        child: Text(
                          DateFormat('MMM d, yyyy').format(_startDate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectEndDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: _trDisplay('budget_end_date'),
                        ),
                        child: Text(DateFormat('MMM d, yyyy').format(_endDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Budget type options
              Text(
                _trDisplay('budget_options'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Saving budget
              SwitchListTile(
                title: Text(
                  _trDisplay('budget_saving'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  _trDisplay('budget_saving_description'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                value: _isSaving,
                onChanged: (value) {
                  setState(() {
                    _isSaving = value;
                  });
                },
                activeColor: AppColors.primary,
              ),

              // Recurring budget
              SwitchListTile(
                title: Text(
                  _trDisplay('budget_recurring'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  _trDisplay('budget_recurring_description'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                  });
                },
                activeColor: AppColors.primary,
              ),

              // Frequency selector (only show if recurring)
              if (_isRecurring) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: _trDisplay('budget_frequency'),
                    border: const OutlineInputBorder(),
                  ),
                  value: _frequency,
                  items: [
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text(context.tr('budget_monthly')),
                    ),
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text(context.tr('budget_weekly')),
                    ),
                    DropdownMenuItem(
                      value: 'daily',
                      child: Text(context.tr('budget_daily')),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _frequency = value;
                    });
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Color picker
              Text(
                _trDisplay('budget_color'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              // Các tùy chọn màu
              Wrap(
                spacing: 16, // Tăng khoảng cách giữa các màu
                runSpacing: 12, // Khoảng cách giữa các hàng
                children: [
                  _colorOption('FF4CAF50'), // Green
                  _colorOption('FF2196F3'), // Blue
                  _colorOption('FFF44336'), // Red
                  _colorOption('FFFF9800'), // Orange
                  _colorOption('FF9C27B0'), // Purple
                  _colorOption('FF607D8B'), // Blue Grey
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorOption(String colorHex) {
    final color = Color(int.parse('0x$colorHex'));
    final isSelected = _color == colorHex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _color = colorHex;
        });
      },
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.7),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                  : null,
        ),
        child:
            isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 28)
                : null,
      ),
    );
  }
}
