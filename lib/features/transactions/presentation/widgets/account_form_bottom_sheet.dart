import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/transactions/domain/entities/account.dart';
import 'package:monie/features/transactions/presentation/bloc/account_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/account_event.dart';

class AccountFormBottomSheet extends StatefulWidget {
  final Account? account;

  const AccountFormBottomSheet({super.key, this.account});

  @override
  State<AccountFormBottomSheet> createState() => _AccountFormBottomSheetState();
}

class _AccountFormBottomSheetState extends State<AccountFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = 'Checking';
  String _selectedCurrency = '\$';
  String _selectedColor = 'blue';

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toString();
      _selectedType = widget.account!.type;
      _selectedCurrency = widget.account!.currency;
      _selectedColor = widget.account!.color ?? 'blue';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
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
                        ? context.tr('accounts_edit')
                        : context.tr('accounts_add_new'),
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

              // Account name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: context.tr('accounts_name'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('accounts_name_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Account type dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: context.tr('accounts_type'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items:
                    ['Checking', 'Savings', 'Credit Card', 'Cash', 'Investment']
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Balance field
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Currency dropdown
                  Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: context.tr('accounts_currency'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items:
                          ['\$', '€', '£', '¥']
                              .map(
                                (currency) => DropdownMenuItem(
                                  value: currency,
                                  child: Text(currency),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCurrency = value;
                          });
                        }
                      },
                    ),
                  ),
                  // Balance amount
                  Expanded(
                    child: TextFormField(
                      controller: _balanceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.tr('accounts_balance'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('accounts_balance_required');
                        }
                        if (double.tryParse(value) == null) {
                          return context.tr('accounts_balance_invalid');
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Color selection
              Text(
                context.tr('accounts_color'),
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
                        : context.tr('accounts_create'),
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('accounts_auth_required')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final name = _nameController.text;
      final balance = double.parse(_balanceController.text);
      final userId = authState.user.id;

      if (_isEditing) {
        // Update existing account
        final updatedAccount = Account(
          accountId: widget.account!.accountId,
          userId: userId,
          name: name,
          type: _selectedType,
          balance: balance,
          currency: _selectedCurrency,
          color: _selectedColor,
        );
        context.read<AccountBloc>().add(UpdateAccountEvent(updatedAccount));
      } else {
        // Create new account
        final newAccount = Account(
          userId: userId,
          name: name,
          type: _selectedType,
          balance: balance,
          currency: _selectedCurrency,
          color: _selectedColor,
        );
        context.read<AccountBloc>().add(CreateAccountEvent(newAccount));
      }

      Navigator.pop(context);
    }
  }
}
