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
  String? _frequency;
  String _color = 'FF4CAF50'; // Default green color
  String _timeBoundType = 'monthly'; // Default to monthly

  @override
  void initState() {
    super.initState();

    // If editing an existing budget, populate the form
    if (widget.budget != null) {
      _nameController.text = widget.budget!.name;
      _amountController.text = widget.budget!.amount.toString();
      _startDate = widget.budget!.startDate;
      _endDate =
          widget.budget!.endDate ?? _startDate.add(const Duration(days: 30));
      _isRecurring = widget.budget!.isRecurring;
      _isSaving = widget.budget!.isSaving;
      _frequency = widget.budget!.frequency;
      if (widget.budget!.color != null && widget.budget!.color!.isNotEmpty) {
        _color = widget.budget!.color!;
      }

      // Determine time bound type based on date range
      _determineTimeBoundType();
    } else {
      // For new budget, set default end date based on monthly time bound
      _setEndDateFromTimeFrame();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Helper method to format display text without underscores

  // Determine time bound type based on date difference
  void _determineTimeBoundType() {
    final difference = _endDate.difference(_startDate).inDays;

    if (difference <= 7) {
      _timeBoundType = 'weekly';
    } else if (difference <= 31) {
      _timeBoundType = 'monthly';
    } else if (difference <= 366) {
      _timeBoundType = 'yearly';
    } else {
      _timeBoundType = 'custom';
    }
  }

  // Set end date based on time bound type
  void _setEndDateFromTimeFrame() {
    switch (_timeBoundType) {
      case 'weekly':
        // Add 7 days
        _endDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day + 7,
        );
        break;
      case 'monthly':
        // Use DateTime arithmetic to correctly move to next month
        int year = _startDate.year;
        int month = _startDate.month;
        int day = _startDate.day;

        // Move to next month
        month += 1;
        if (month > 12) {
          month = 1;
          year += 1;
        }

        // Handle day overflow (e.g., Jan 31 -> Feb 28)
        final lastDayOfMonth = DateTime(year, month + 1, 0).day;
        if (day > lastDayOfMonth) {
          day = lastDayOfMonth;
        }

        _endDate = DateTime(year, month, day);
        break;
      case 'yearly':
        // Add 1 year
        _endDate = DateTime(
          _startDate.year + 1,
          _startDate.month,
          _startDate.day,
        );

        // Handle February 29 for leap years
        if (_startDate.month == 2 &&
            _startDate.day == 29 &&
            !_isLeapYear(_endDate.year)) {
          _endDate = DateTime(_endDate.year, 2, 28);
        }
        break;
      case 'custom':
        // Keep existing end date for custom or ensure it's at least one day after start
        if (_endDate.isBefore(_startDate) ||
            _endDate.isAtSameMomentAs(_startDate)) {
          _endDate = _startDate.add(
            const Duration(days: 30),
          ); // Default to 30 days
        }
        break;
    }
  }

  // Helper to check if a year is a leap year
  bool _isLeapYear(int year) {
    return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
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

        // Update end date based on time frame if not custom
        if (_timeBoundType != 'custom') {
          _setEndDateFromTimeFrame();
        } else if (_endDate.isBefore(_startDate)) {
          // For custom time frame, ensure end date is after start date
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    // Only allow end date selection for custom time frame
    if (_timeBoundType != 'custom') {
      return;
    }

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

      // Create or update budget
      final budget =
          widget.budget == null
              ? BudgetModel.create(
                name: _nameController.text,
                amount: amount,
                startDate: _startDate,
                endDate: _endDate,
                userId:
                    "user_id_placeholder", // This would need to be replaced with the actual user ID
                isRecurring: _isRecurring,
                isSaving: _isSaving,
                frequency: _frequency,
                color: _color,
              )
              : BudgetModel(
                budgetId: widget.budget!.budgetId,
                userId: widget.budget!.userId,
                name: _nameController.text,
                amount: amount,
                startDate: _startDate,
                endDate: _endDate,
                isRecurring: _isRecurring,
                isSaving: _isSaving,
                frequency: _frequency,
                color: _color,
              );

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
              ? context.tr('budget_new')
              : context.tr('budget_edit'),
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
                  labelText: "${context.tr('budget_name')} *",
                  hintText: context.tr('budget_name_hint'),
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
              const SizedBox(height: 8),

              SwitchListTile(
                title: Text(
                  context.tr('budget_saving'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  context.tr('budget_saving_description'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                secondary: Icon(
                  _isSaving ? Icons.arrow_upward : Icons.arrow_downward,
                  color: _isSaving ? AppColors.income : AppColors.expense,
                ),
                value: _isSaving,
                onChanged: (value) {
                  setState(() {
                    _isSaving = value;
                  });
                },
                activeColor: AppColors.income,
                contentPadding: EdgeInsets.zero,
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_isSaving ? AppColors.income : AppColors.expense)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (_isSaving ? AppColors.income : AppColors.expense)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: _isSaving ? AppColors.income : AppColors.expense,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr(
                          _isSaving
                              ? 'budget_income_description'
                              : 'budget_expense_description',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Budget amount
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: "${context.tr('budget_amount')} *",
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

              // Time frame selector
              Text(
                context.tr('budget_time_frame'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Time bound type options
              Wrap(
                spacing: 8,
                children: [
                  _buildTimeFrameChip(
                    'weekly',
                    context.tr('budget_frequency_weekly'),
                  ),
                  _buildTimeFrameChip(
                    'monthly',
                    context.tr('budget_frequency_monthly'),
                  ),
                  _buildTimeFrameChip(
                    'yearly',
                    context.tr('budget_frequency_yearly'),
                  ),
                  _buildTimeFrameChip(
                    'custom',
                    context.tr('budget_custom_period'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Date selectors
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectStartDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: context.tr('budget_start_date'),
                        ),
                        child: Text(
                          DateFormat('MMM d, yyyy').format(_startDate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AbsorbPointer(
                      absorbing: _timeBoundType != 'custom',
                      child: InkWell(
                        onTap: _selectEndDate, // Only works when not absorbed
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: context.tr('budget_end_date'),
                            enabled: _timeBoundType == 'custom',
                            helperText:
                                _timeBoundType != 'custom'
                                    ? context.tr('budget_auto_end_date_info')
                                    : null,
                            helperStyle: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 11,
                              color:
                                  isDarkMode ? Colors.white60 : Colors.black45,
                            ),
                          ),
                          child: Text(
                            DateFormat('MMM d, yyyy').format(_endDate),
                            style: TextStyle(
                              color:
                                  _timeBoundType != 'custom'
                                      ? (isDarkMode
                                          ? Colors.white70
                                          : Colors.black54)
                                      : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Color picker
              Text(
                context.tr('budget_color'),
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

  Widget _buildTimeFrameChip(String type, String label) {
    final isSelected = _timeBoundType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _timeBoundType = type;
            _setEndDateFromTimeFrame();
          });
        }
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _colorOption(String colorHex) {
    // Safe color parsing
    Color color;
    try {
      color = Color(int.parse('0x$colorHex'));
    } catch (e) {
      // Fallback to a default color if parsing fails
      color = AppColors.primary;
    }

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
