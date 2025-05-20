import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/themes/category_colors.dart';
import 'package:monie/features/account/presentation/bloc/account_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/home/domain/entities/account.dart';
import 'package:monie/features/home/presentation/bloc/home_bloc.dart';

class AddAccountPage extends StatefulWidget {
  final Account? account;
  final bool isEdit;

  const AddAccountPage({super.key, this.account, this.isEdit = false});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Account' : 'Add Account'),
        backgroundColor: _selectedColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
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
                    DropdownMenuItem(value: 'savings', child: Text('Savings')),
                    DropdownMenuItem(value: 'credit', child: Text('Credit')),
                    DropdownMenuItem(value: 'debit', child: Text('Debit')),
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
              BlocListener<AccountBloc, AccountState>(
                listener: (context, state) {
                  if (state is AddAccountState || state is UpdateAccountState) {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is Authenticated) {
                      context.read<HomeBloc>().add(
                        LoadHomeData(authState.user.id),
                      );
                      context.read<AccountBloc>().add(
                        GetAccountsEvent(userId: authState.user.id),
                      );
                    }
                    Navigator.of(context).pop();
                  }
                },
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    if (authState is Authenticated) {
                      return BlocBuilder<AccountBloc, AccountState>(
                        builder: (context, state) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedColor,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                Account accountRequest = Account(
                                  accountId: account?.accountId,
                                  userId: authState.user.id,
                                  name: _controllers['name']!.text,
                                  type: _accountType,
                                  balance:
                                      double.tryParse(
                                        _controllers['balance']!.text,
                                      ) ??
                                      0,
                                  currency: _controllers['currency']!.text,
                                  color: _selectedColorName,
                                  archived: account?.archived ?? false,
                                  pinned: account?.pinned ?? false,
                                );

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Account saved successfully!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  context.read<AccountBloc>().add(
                                    widget.isEdit == false
                                        ? AddAccountEvent(
                                          account: accountRequest,
                                        )
                                        : UpdateAccountEvent(
                                          account: accountRequest,
                                        ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please fill all required fields',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              widget.isEdit ? 'Save Changes' : 'Add Account',
                            ),
                          );
                        },
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
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
