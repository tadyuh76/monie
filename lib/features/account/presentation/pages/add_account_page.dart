import 'package:flutter/material.dart';

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
  Color _color = Colors.green;
  // Add more fields for type-specific attributes as needed

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
                items: [
                  'bank', 'cash', 'credit', 'debit', 'savings', 'investment'
                ].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Initial Balance'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _initialBalance = double.tryParse(v) ?? 0.0,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Currency'),
                onChanged: (v) => _currency = v,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Account Color:'),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      // TODO: Show color picker
                    },
                    child: CircleAvatar(backgroundColor: _color),
                  ),
                ],
              ),
              // TODO: Add type-specific fields here
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TODO: Save account via Bloc/Cubit
                    Navigator.of(context).pop();
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