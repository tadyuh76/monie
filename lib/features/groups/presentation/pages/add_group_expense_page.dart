import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/constants/category_icons.dart';
import 'package:monie/core/constants/transaction_categories.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/category_utils.dart';
import 'package:monie/features/groups/data/models/group_member_model.dart';
import 'package:monie/features/groups/presentation/bloc/group_bloc.dart';
import 'package:monie/features/groups/presentation/bloc/group_event.dart';
import 'package:monie/features/groups/presentation/bloc/group_state.dart';

class AddGroupExpensePage extends StatefulWidget {
  final String groupId;

  const AddGroupExpensePage({super.key, required this.groupId});

  @override
  State<AddGroupExpensePage> createState() => _AddGroupExpensePageState();
}

class _AddGroupExpensePageState extends State<AddGroupExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _paidBy = ''; // User ID of the payer
  DateTime _date = DateTime.now();
  Map<String, dynamic>? _selectedCategory; // Added for category selection
  bool _isExpense = true; // New: Track if this is an expense or income

  // Map of user IDs to display names for the UI
  Map<String, String> _memberDisplayNames = {};
  List<GroupMemberModel> _groupMembers = [];

  // State for category selection
  bool _showCategorySelector = false;

  @override
  void initState() {
    super.initState();

    // Set default category to 'Group'
    _updateDefaultCategory();

    // Load group details and member list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupBloc>().add(GetGroupByIdEvent(groupId: widget.groupId));
      context.read<GroupBloc>().add(
        GetGroupMembersEvent(groupId: widget.groupId),
      );
    });
  }

  void _updateDefaultCategory() {
    final categories =
        _isExpense
            ? TransactionCategories.expenseCategories
            : TransactionCategories.incomeCategories;

    _selectedCategory = categories.firstWhere(
      (category) => category['name'] == 'Group',
      orElse: () => categories.first,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode
              ? AppColors.background
              : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            isDarkMode
                ? AppColors.background
                : Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        title: Text(
          _isExpense
              ? context.tr('groups_add_expense')
              : context.tr('groups_add_income'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocListener<GroupBloc, GroupState>(
        listener: (context, state) {
          if (state is GroupError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is GroupOperationSuccess) {
            // Only show snackbars for expense-related operations
            if (state.message.contains('Expense added')) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
              Navigator.pop(context); // Return to group details page
            }
          } else if (state is GroupMembersLoaded) {
            // When members are loaded, update the member data
            setState(() {
              _groupMembers = state.members;

              // Create a map of user IDs to display names
              _memberDisplayNames = {
                for (var member in state.members)
                  member.userId: member.displayName ?? member.userId,
              };

              // Set the default payer if not already set
              if (_paidBy.isEmpty && _groupMembers.isNotEmpty) {
                _paidBy = _groupMembers.first.userId;
              }
            });
          }
        },
        child: BlocBuilder<GroupBloc, GroupState>(
          builder: (context, state) {
            // Show loading indicator if we're still loading and don't have members
            if (_memberDisplayNames.isEmpty &&
                (state is GroupLoading || state is GroupInitial)) {
              return const Center(child: CircularProgressIndicator());
            }

            // If we have members data, build the form
            if (_memberDisplayNames.isNotEmpty) {
              // Show category selector if activated, otherwise show the main form
              return _showCategorySelector
                  ? _buildCategorySelector()
                  : _buildForm(context);
            }

            // Request member data if we need it
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_memberDisplayNames.isEmpty && state is! GroupLoading) {
                context.read<GroupBloc>().add(
                  GetGroupMembersEvent(groupId: widget.groupId),
                );
              }
            });

            return const Center(child: Text('Loading group members...'));
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Transaction Type Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.cardDark : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!_isExpense) {
                        setState(() {
                          _isExpense = true;
                          _updateDefaultCategory();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            _isExpense ? AppColors.expense : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.tr('transaction_expense'),
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color:
                              _isExpense
                                  ? Colors.white
                                  : (isDarkMode
                                      ? Colors.white70
                                      : Colors.black54),
                          fontWeight:
                              _isExpense ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_isExpense) {
                        setState(() {
                          _isExpense = false;
                          _updateDefaultCategory();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            !_isExpense ? AppColors.income : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.tr('transaction_income'),
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color:
                              !_isExpense
                                  ? Colors.white
                                  : (isDarkMode
                                      ? Colors.white70
                                      : Colors.black54),
                          fontWeight:
                              !_isExpense ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Transaction title
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText:
                  _isExpense
                      ? context.tr('groups_expense_title')
                      : context.tr('groups_income_title'),
              hintText:
                  _isExpense
                      ? context.tr('groups_expense_title_hint')
                      : context.tr('groups_income_title_hint'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return _isExpense
                    ? context.tr('groups_expense_title_required')
                    : context.tr('groups_income_title_required');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Amount
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText:
                  _isExpense
                      ? context.tr('groups_expense_amount')
                      : context.tr('groups_income_amount'),
              hintText: '0.00',
              prefixText: '\$ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return _isExpense
                    ? context.tr('groups_expense_amount_required')
                    : context.tr('groups_income_amount_required');
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return context.tr('groups_amount_invalid');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Category selector
          InkWell(
            onTap: () {
              setState(() {
                _showCategorySelector = true;
              });
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: context.tr('category'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  if (_selectedCategory != null) ...[
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CategoryUtils.getCategoryColor(
                          _selectedCategory!['svgName'],
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: SvgPicture.asset(
                        CategoryIcons.getIconPath(
                          _selectedCategory!['svgName'],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedCategory!['name'],
                      style: textTheme.bodyLarge?.copyWith(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Date picker
          InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null && picked != _date) {
                setState(() {
                  _date = picked;
                });
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: context.tr('groups_expense_date'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('MMM d, yyyy').format(_date)),
                  Icon(
                    Icons.calendar_today,
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText:
                  _isExpense
                      ? context.tr('groups_expense_description')
                      : context.tr('groups_income_description'),
              hintText:
                  _isExpense
                      ? context.tr('groups_expense_description_hint')
                      : context.tr('groups_income_description_hint'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Paid by / Received by section
          Text(
            _isExpense
                ? context.tr('groups_expense_paid_by')
                : context.tr('groups_income_received_by'),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow:
                  !isDarkMode
                      ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Column(
              children:
                  _memberDisplayNames.entries.map((entry) {
                    return RadioListTile<String>(
                      title: Text(entry.value), // Display name
                      value: entry.key, // User ID
                      groupValue: _paidBy,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _paidBy = value;
                          });
                        }
                      },
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isExpense ? AppColors.expense : AppColors.income,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isExpense
                    ? context.tr('groups_add_expense')
                    : context.tr('groups_add_income'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Category selector widget
  Widget _buildCategorySelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final categories =
        _isExpense
            ? TransactionCategories.expenseCategories
            : TransactionCategories.incomeCategories;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.background : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.background : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _showCategorySelector = false;
            });
          },
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        title: Text(
          context.tr('select_category'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryItem(category);
        },
      ),
    );
  }

  // Individual category item
  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected =
        _selectedCategory != null &&
        _selectedCategory!['name'] == category['name'];

    String svgName = category['svgName'];
    String iconPath = CategoryIcons.getIconPath(svgName);
    Color categoryColor = CategoryUtils.getCategoryColor(svgName);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _showCategorySelector = false; // Return to the form after selection
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected
                  ? categoryColor.withValues(alpha: 0.3)
                  : isDarkMode
                  ? AppColors.cardDark
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? categoryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(iconPath, width: 24, height: 24),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category['name'],
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitTransaction() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_paidBy.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isExpense
                  ? context.tr('groups_expense_select_payer')
                  : context.tr('groups_income_received_by'),
            ),
          ),
        );
        return;
      }

      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('please_select_category'))),
        );
        return;
      }

      // Create transaction data
      String title = _titleController.text.trim();
      double amount = double.parse(_amountController.text.trim());
      final description = _descriptionController.text.trim();

      // Get the category information
      final categoryName = _selectedCategory!['name'];
      final categoryColor = CategoryUtils.getCategoryColorHex(
        _selectedCategory!['svgName'],
      );

      // For group transactions:
      // - Expenses: store as negative amounts
      // - Income: store as positive amounts
      if (!_isExpense) {
        // Income: ensure amount is positive
        amount = amount.abs();
      } else {
        // Expense: ensure amount is negative
        amount = -amount.abs();
      }

      // No prefix for income anymore
      // title = _isExpense ? title : 'Income: $title';

      context.read<GroupBloc>().add(
        AddGroupExpenseEvent(
          groupId: widget.groupId,
          title: title,
          amount: amount,
          description: description,
          date: _date,
          paidBy: _paidBy,
          categoryName: categoryName,
          color: categoryColor,
        ),
      );
    }
  }
}
