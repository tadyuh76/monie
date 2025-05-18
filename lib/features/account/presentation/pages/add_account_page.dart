import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/features/home/presentation/bloc/home_bloc.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({Key? key}) : super(key: key);

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _type = 'bank';
  double _initialBalance = 0.0;
  String _currency = 'USD';
  Color _color = AppColors.bank;
  String _accountNumber = '';
  String _institution = '';
  String _interestRate = '';
  String _creditLimit = '';

  final List<String> _accountTypes = [
    'bank', 'cash', 'credit', 'debit', 'savings', 'investment'
  ];
  final List<String> _currencies = [
    'USD', 'VND', 'EUR', 'JPY', 'GBP', 'AUD', 'CAD', 'SGD', 'CNY', 'KRW'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Add Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Account Name'),
                onChanged: (v) => _name = v,
                validator: (v) => v == null || v.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Account Type'),
                items: _accountTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Initial Balance'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _initialBalance = double.tryParse(v) ?? 0.0,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: _currencies
                    .map((cur) => DropdownMenuItem(value: cur, child: Text(cur)))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v!),
              ),
              const SizedBox(height: 16),
              // Type-specific fields
              if (_type != 'cash') ...[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Account Number (Optional)'),
                  onChanged: (v) => _accountNumber = v,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Institution (Optional)'),
                  onChanged: (v) => _institution = v,
                ),
                const SizedBox(height: 16),
              ],
              if (_type == 'savings') ...[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Interest Rate (Optional)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _interestRate = v,
                ),
                const SizedBox(height: 16),
              ],
              if (_type == 'credit' || _type == 'debit') ...[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Credit Limit (Optional)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _creditLimit = v,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  const Text('Account Color:'),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      Color? picked = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: _color,
                              onColorChanged: (color) {
                                setState(() => _color = color);
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Select'),
                              onPressed: () => Navigator.of(context).pop(_color),
                            ),
                          ],
                        ),
                      );
                      if (picked != null) setState(() => _color = picked);
                    },
                    child: CircleAvatar(backgroundColor: _color),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Save account via Bloc
                    context.read<HomeBloc>().add(
                      AddAccount(
                        name: _name,
                        type: _type,
                        balance: _initialBalance,
                        currency: _currency,
                        color: _color,
                        accountNumber: _accountNumber,
                        institution: _institution,
                        interestRate: _interestRate,
                        creditLimit: _creditLimit,
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account added successfully!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Add Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 