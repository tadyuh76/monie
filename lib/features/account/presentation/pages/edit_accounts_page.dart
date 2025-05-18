import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:monie/features/account/presentation/pages/add_account_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/features/home/presentation/bloc/home_bloc.dart';

class EditAccountsPage extends StatefulWidget {
  const EditAccountsPage({Key? key}) : super(key: key);

  @override
  State<EditAccountsPage> createState() => _EditAccountsPageState();
}

class _EditAccountsPageState extends State<EditAccountsPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddAccountPage()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search accounts...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
          Expanded(
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is HomeLoaded) {
                  final filteredAccounts = state.accounts.where((a) => a.name.toLowerCase().contains(_search.toLowerCase())).toList();
                  return ListView.builder(
                    itemCount: filteredAccounts.length,
                    itemBuilder: (context, index) {
                      final account = filteredAccounts[index];
                      return Dismissible(
                        key: ValueKey(account.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Account'),
                              content: Text('Are you sure you want to delete ${account.name}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          context.read<HomeBloc>().add(DeleteAccount(account.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${account.name} deleted successfully!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditAccountPage(accountId: account.id)));
                            },
                            child: ListTile(
                              title: Text(account.name),
                              subtitle: Text('${account.balance} ${account.currency}\n${account.transactionCount} transactions'),
                              trailing: null, // Add primary chip logic if needed
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is HomeError) {
                  return Center(child: Text('Error: ${state.message}'));
                } else {
                  return const SizedBox();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EditAccountPage extends StatefulWidget {
  final String accountId;
  const EditAccountPage({Key? key, required this.accountId}) : super(key: key);

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  String _name = '';
  String _type = 'bank';
  Color _color = Colors.green;
  String _accountNumber = '';
  String _institution = '';
  String _interestRate = '';
  String _creditLimit = '';
  final List<Color> _fixedColors = [
    Colors.green,
    Colors.blue,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.brown,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
  ];

  final List<String> _accountTypes = [
    'bank', 'cash', 'credit', 'debit', 'savings', 'investment'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<HomeBloc>().state;
    if (state is HomeLoaded) {
      final account = state.accounts.firstWhere((a) => a.id == widget.accountId, orElse: () => state.accounts.first);
      _name = account.name;
      _type = account.type;
      _color = Colors.green; // You can update this to use account.color if available
      // Load type-specific fields from account if available
      // (future: implement loading and initializing form fields)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Account Name'),
              onChanged: (v) => _name = v,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Account Type'),
              items: _accountTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type[0].toUpperCase() + type.substring(1)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            // Type-specific fields
            if (_type != 'cash') ...[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Account Number (Optional)'),
                initialValue: _accountNumber,
                onChanged: (v) => _accountNumber = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Institution (Optional)'),
                initialValue: _institution,
                onChanged: (v) => _institution = v,
              ),
              const SizedBox(height: 16),
            ],
            if (_type == 'savings') ...[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Interest Rate (Optional)'),
                keyboardType: TextInputType.number,
                initialValue: _interestRate,
                onChanged: (v) => _interestRate = v,
              ),
              const SizedBox(height: 16),
            ],
            if (_type == 'credit' || _type == 'debit') ...[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Credit Limit (Optional)'),
                keyboardType: TextInputType.number,
                initialValue: _creditLimit,
                onChanged: (v) => _creditLimit = v,
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                const Text('Account Color:'),
                const SizedBox(width: 8),
                ..._fixedColors.map((color) => GestureDetector(
                  onTap: () => setState(() => _color = color),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == color ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: 14,
                      child: _color == color ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                    ),
                  ),
                )),
                GestureDetector(
                  onTap: () async {
                    Color picked = _color;
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: _color,
                            onColorChanged: (color) {
                              picked = color;
                            },
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Select'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    );
                    setState(() => _color = picked);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                    child: const Icon(Icons.add, size: 20),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: CircleAvatar(backgroundColor: _color, radius: 14),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Save changes (mock)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account changes saved!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive Account'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Archive Account'),
                    content: const Text('Are you sure you want to archive this account?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account archived!')),
                          );
                        },
                        child: const Text('Archive'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Correct Total Balance'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    double newBalance = 0.0;
                    return AlertDialog(
                      title: const Text('Correct Total Balance'),
                      content: TextField(
                        decoration: const InputDecoration(labelText: 'New Balance'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => newBalance = double.tryParse(v) ?? 0.0,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Balance corrected to $newBalance!')),
                            );
                          },
                          child: const Text('Correct'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: const Text('Transfer Balance'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    String toAccount = '';
                    double amount = 0.0;
                    return AlertDialog(
                      title: const Text('Transfer Balance'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            decoration: const InputDecoration(labelText: 'To Account'),
                            onChanged: (v) => toAccount = v,
                          ),
                          TextField(
                            decoration: const InputDecoration(labelText: 'Amount'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => amount = double.tryParse(v) ?? 0.0,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Transferred $amount to $toAccount!')),
                            );
                          },
                          child: const Text('Transfer'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.merge_type),
              title: const Text('Merge Account'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    String toAccount = '';
                    return AlertDialog(
                      title: const Text('Merge Account'),
                      content: TextField(
                        decoration: const InputDecoration(labelText: 'Account to merge into'),
                        onChanged: (v) => toAccount = v,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Merged into $toAccount!')),
                            );
                          },
                          child: const Text('Merge'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CorrectBalanceDialog extends StatelessWidget {
  const CorrectBalanceDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Correct Balance'),
      content: const Text('Add/subtract money UI goes here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('Save'),
        ),
      ],
    );
  }
} 