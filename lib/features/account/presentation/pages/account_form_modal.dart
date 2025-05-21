import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/themes/category_colors.dart';
import 'package:monie/core/utils/category_utils.dart';
import 'package:monie/di/injection.dart';
import 'package:monie/features/account/domain/entities/account.dart';
import 'package:monie/features/account/presentation/bloc/account_bloc.dart';
import 'package:monie/features/account/presentation/bloc/account_event.dart';
import 'package:monie/features/account/presentation/bloc/account_state.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
// import 'package:monie/features/home/domain/entities/account.dart';
import 'package:monie/features/home/presentation/bloc/home_bloc.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:monie/features/transactions/presentation/bloc/transactions_bloc.dart';

class AccountFormModal extends StatefulWidget {
  final Account? account;
  final bool isEdit;

  const AccountFormModal({super.key, this.account, this.isEdit = false});

  @override
  State<AccountFormModal> createState() => _AccountFormModalState();

  static Future<void> show(
    BuildContext context, {
    Account? account,
    bool isEdit = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AccountFormModal(account: account, isEdit: isEdit),
    );
  }
}

class _AccountFormModalState extends State<AccountFormModal> {
  final _formKey = GlobalKey<FormState>();
  String _accountType = 'cash';
  final Map<String, TextEditingController> _controllers = {
    'name': TextEditingController(),
    'balance': TextEditingController(),
    'currency': TextEditingController(text: 'USD'),
    'accountNumber': TextEditingController(),
    'institution': TextEditingController(),
    'interestRate': TextEditingController(),
    'creditLimit': TextEditingController(),
  };
  String _selectedColorName = 'blue';
  bool _isSubmitting = false;

  Account? get account => widget.account;

  @override
  void initState() {
    super.initState();
    if (account != null) {
      _controllers['name']!.text = account?.name ?? '';
      _controllers['balance']!.text = account?.balance.toString() ?? '';
      _controllers['currency']!.text = account?.currency ?? 'USD';
      _accountType = account?.type ?? 'cash';
      _selectedColorName = account?.color ?? 'blue';
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<Widget> _buildDynamicFields() {
    switch (_accountType) {
      case 'investment':
        return [
          _textField('Account Number', 'accountNumber'),
          _textField('Institution', 'institution'),
        ];
      case 'savings':
        return [
          _textField('Account Number', 'accountNumber'),
          _textField('Institution', 'institution'),
          _textField('Interest Rate', 'interestRate'),
        ];
      case 'credit':
        return [
          _textField('Account Number', 'accountNumber'),
          _textField('Institution', 'institution'),
          _textField('Credit Limit', 'creditLimit'),
        ];
      case 'debit':
        return [
          _textField('Account Number', 'accountNumber'),
          _textField('Institution', 'institution'),
          _textField('Credit Limit', 'creditLimit'),
        ];
      default:
        return [];
    }
  }

  Widget _textField(
    String label,
    String key, {
    bool isNumber = false,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: isNumber ? TextInputType.number : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return '$label is required';
          }
          if (isNumber &&
              value != null &&
              value.isNotEmpty &&
              double.tryParse(value) == null) {
            return '$label must be a number';
          }
          return null;
        },
      ),
    );
  }

  Color get _selectedColor {
    switch (_selectedColorName.toLowerCase()) {
      case 'blue':
        return CategoryColors.blue;
      case 'green':
        return CategoryColors.green;
      case 'coolGrey':
        return CategoryColors.coolGrey;
      case 'warmGrey':
        return CategoryColors.warmGrey;
      case 'teal':
        return CategoryColors.teal;
      case 'darkBlue':
        return CategoryColors.darkBlue;
      case 'red':
        return CategoryColors.red;
      case 'gold':
        return CategoryColors.gold;
      case 'orange':
        return CategoryColors.orange;
      case 'plum':
        return CategoryColors.plum;
      case 'purple':
        return CategoryColors.purple;
      case 'indigo':
        return CategoryColors.indigo;
      default:
        return CategoryColors.blue;
    }
  }

  Widget _colorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Account Color:'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _colorOption('blue', CategoryColors.blue),
            _colorOption('green', CategoryColors.green),
            _colorOption('coolGrey', CategoryColors.coolGrey),
            _colorOption('warmGrey', CategoryColors.warmGrey),
            _colorOption('teal', CategoryColors.teal),
            _colorOption('darkBlue', CategoryColors.darkBlue),
            _colorOption('red', CategoryColors.red),
            _colorOption('gold', CategoryColors.gold),
            _colorOption('orange', CategoryColors.orange),
            _colorOption('plum', CategoryColors.plum),
            _colorOption('purple', CategoryColors.purple),
            _colorOption('indigo', CategoryColors.indigo),
          ],
        ),
      ],
    );
  }

  Widget _colorOption(String name, Color color) {
    return GestureDetector(
      onTap: () => setState(() => _selectedColorName = name),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                _selectedColorName == name ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                    widget.isEdit ? 'Edit Account' : 'Add Account',
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

              Expanded(
                child: ListView(
                  children: [
                    _textField('Account Name', 'name', required: true),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: DropdownButtonFormField<String>(
                        value: _accountType,
                        decoration: const InputDecoration(
                          labelText: 'Account Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'bank', child: Text('Bank')),
                          DropdownMenuItem(
                            value: 'investment',
                            child: Text('Investment'),
                          ),
                          DropdownMenuItem(
                            value: 'savings',
                            child: Text('Savings'),
                          ),
                          DropdownMenuItem(
                            value: 'credit',
                            child: Text('Credit'),
                          ),
                          DropdownMenuItem(
                            value: 'debit',
                            child: Text('Debit'),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _accountType = val ?? 'cash';
                          });
                        },
                      ),
                    ),
                    _currencyDropdown(),
                    _textField(
                      'Initial Balance',
                      'balance',
                      isNumber: true,
                      required: true,
                    ),
                    ..._buildDynamicFields(),
                    _colorPicker(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              MultiBlocProvider(
                providers: [
                  BlocProvider<AccountBloc>(
                    create: (context) => sl<AccountBloc>(),
                  ),
                  BlocProvider<TransactionBloc>(
                    create: (context) => sl<TransactionBloc>(),
                  ),
                  // Try to get the transactions AccountBloc from context, or create a new one if not available
                  BlocProvider<AccountBloc>(
                    create: (context) {
                      try {
                        return context.read<AccountBloc>();
                      } catch (e) {
                        // If not available, create a new instance
                        return sl<AccountBloc>();
                      }
                    },
                  ),
                ],
                child: MultiBlocListener(
                  listeners: [
                    BlocListener<AccountBloc, AccountState>(
                      listener: (context, state) {
                        if (state is AccountCreated) {
                          final authState = context.read<AuthBloc>().state;
                          if (authState is Authenticated) {
                            // Always trigger HomeBloc to reload data with the new account
                            try {
                              final homeBloc = context.read<HomeBloc>();
                              homeBloc.add(LoadHomeData(authState.user.id));
                            } catch (e) {
                              // If the bloc is closed, ignore the error
                            }

                            // Also trigger the transactions AccountBloc to update its state
                            try {
                              final transactionsAccountBloc =
                                  context.read<AccountBloc>();
                              transactionsAccountBloc.add(
                                LoadAccountsEvent(authState.user.id),
                              );
                            } catch (e) {
                              // If the bloc is not available in this context, that's okay
                            }

                            // Create initial balance transaction if balance > 0
                            final balance =
                                double.tryParse(
                                  _controllers['balance']!.text,
                                ) ??
                                0;

                            // Make sure we have a valid account ID before creating a transaction
                            if (balance > 0 &&
                                state.account.accountId != null) {
                              try {
                                final transactionBloc =
                                    context.read<TransactionBloc>();

                                // Create an initial balance transaction
                                final initialTransaction = Transaction(
                                  userId: authState.user.id,
                                  amount: balance,
                                  title: 'Initial balance',
                                  description: 'Initial account balance',
                                  date: DateTime.now(),
                                  accountId: state.account.accountId!,
                                  categoryName: 'Account Adjustment',
                                  color: CategoryUtils.getCategoryColorHex(
                                    'Account Adjustment',
                                    isIncome: true,
                                  ),
                                );

                                // Add the transaction
                                transactionBloc.add(
                                  CreateTransactionEvent(initialTransaction),
                                );
                              } catch (e) {
                                // If the bloc is closed, ignore the error and close the modal
                                Navigator.of(context).pop();
                              }
                            } else {
                              // If no initial balance transaction needed or no accountId,
                              // close the modal since we've already triggered the home data reload
                              Navigator.of(context).pop();
                            }
                          }
                        } else if (state is AccountUpdated) {
                          final authState = context.read<AuthBloc>().state;
                          if (authState is Authenticated) {
                            // Reload home data after account update
                            try {
                              final homeBloc = context.read<HomeBloc>();
                              homeBloc.add(LoadHomeData(authState.user.id));
                            } catch (e) {
                              // If the bloc is closed, ignore the error
                            }

                            // Also trigger the transactions AccountBloc to update its state
                            try {
                              final transactionsAccountBloc =
                                  context.read<AccountBloc>();
                              transactionsAccountBloc.add(
                                LoadAccountsEvent(authState.user.id),
                              );
                            } catch (e) {
                              // If the bloc is not available in this context, that's okay
                            }
                          }
                          Navigator.of(context).pop();
                        } else if (state is Error) {
                          setState(() {
                            _isSubmitting = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${state.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                    BlocListener<TransactionBloc, TransactionState>(
                      listener: (context, state) {
                        final authState = context.read<AuthBloc>().state;
                        if (state is TransactionCreated) {
                          // Transaction created successfully, reload home data
                          if (authState is Authenticated) {
                            // Make sure HomeBloc is triggered to reload data with the new transaction
                            try {
                              final homeBloc = context.read<HomeBloc>();
                              homeBloc.add(LoadHomeData(authState.user.id));
                            } catch (e) {
                              // If the bloc is closed, ignore the error
                            }

                            // Also trigger the transactions AccountBloc to update its state
                            try {
                              final transactionsAccountBloc =
                                  context.read<AccountBloc>();
                              transactionsAccountBloc.add(
                                LoadAccountsEvent(authState.user.id),
                              );
                            } catch (e) {
                              // If the bloc is not available in this context, that's okay
                            }

                            // Also reload transactions list if needed
                            try {
                              final transactionsBloc =
                                  context.read<TransactionsBloc>();
                              transactionsBloc.add(
                                LoadTransactions(userId: authState.user.id),
                              );
                            } catch (e) {
                              // TransactionsBloc might not be available in this context
                              // This is fine as HomeBloc will still be updated
                            }
                          }
                          // Close the modal after successful transaction creation
                          Navigator.of(context).pop();
                        } else if (state is TransactionError) {
                          setState(() {
                            _isSubmitting = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error creating initial transaction: ${state.message}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      if (authState is Authenticated) {
                        return BlocBuilder<AccountBloc, AccountState>(
                          builder: (context, state) {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed:
                                    _isSubmitting
                                        ? null
                                        : () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            setState(() {
                                              _isSubmitting = true;
                                            });

                                            Account accountRequest = Account(
                                              accountId:
                                                  widget.isEdit
                                                      ? account?.accountId
                                                      : null,
                                              userId: authState.user.id,
                                              name: _controllers['name']!.text,
                                              type: _accountType,
                                              balance:
                                                  double.tryParse(
                                                    _controllers['balance']!
                                                        .text,
                                                  ) ??
                                                  0,
                                              currency:
                                                  _controllers['currency']!
                                                      .text,
                                              color: _selectedColorName,
                                              archived:
                                                  account?.archived ?? false,
                                              pinned: account?.pinned ?? false,
                                            );

                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Account saved successfully!',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );

                                              // Add the account creation event
                                              context.read<AccountBloc>().add(
                                                widget.isEdit == false
                                                    ? CreateAccountEvent(
                                                      accountRequest,
                                                    )
                                                    : UpdateAccountEvent(
                                                      accountRequest,
                                                    ),
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please fill all required fields',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                child:
                                    _isSubmitting
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Text(
                                          widget.isEdit
                                              ? 'Save Changes'
                                              : 'Add Account',
                                        ),
                              ),
                            );
                          },
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _currencyDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _controllers['currency']!.text,
        decoration: const InputDecoration(
          labelText: 'Currency',
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: 'VND', child: Text('VND')),
          DropdownMenuItem(value: 'USD', child: Text('USD')),
          DropdownMenuItem(value: 'EUR', child: Text('EUR')),
        ],
        onChanged: (val) {
          setState(() {
            _controllers['currency']!.text = val ?? 'USD';
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Currency is required';
          }
          return null;
        },
      ),
    );
  }
}
