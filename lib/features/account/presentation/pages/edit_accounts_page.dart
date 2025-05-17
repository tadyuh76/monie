import 'package:flutter/material.dart';
// TODO: import your bloc and AddAccountPage, EditAccountPage when available

class EditAccountsPage extends StatefulWidget {
  const EditAccountsPage({Key? key}) : super(key: key);

  @override
  State<EditAccountsPage> createState() => _EditAccountsPageState();
}

class _EditAccountsPageState extends State<EditAccountsPage> {
  String _search = '';

  // TODO: Replace with BlocBuilder for real accounts
  List<Map<String, dynamic>> accounts = [
    {'id': '1', 'name': 'Ngân hàng', 'balance': -38.0, 'currency': 'VND', 'transactions': 6, 'primary': true},
    {'id': '2', 'name': 'Dubject', 'balance': 36.0, 'currency': 'VND', 'transactions': 1, 'primary': false},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredAccounts = accounts.where((a) => a['name'].toLowerCase().contains(_search.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to AddAccountPage
              // Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddAccountPage()));
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
            child: ListView.builder(
              itemCount: filteredAccounts.length,
              itemBuilder: (context, index) {
                final account = filteredAccounts[index];
                return Dismissible(
                  key: ValueKey(account['id']),
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
                        content: Text('Are you sure you want to delete ${account['name']}?'),
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
                    setState(() {
                      accounts.removeWhere((a) => a['id'] == account['id']);
                    });
                    // TODO: Remove from persistent storage
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${account['name']} deleted successfully!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // TODO: Navigate to EditAccountPage
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditAccountPage(accountId: account['id'])));
                      },
                      child: ListTile(
                        title: Text(account['name']),
                        subtitle: Text('${account['balance']} ${account['currency']}\n${account['transactions']} transactions'),
                        trailing: account['primary'] ? const Chip(label: Text('Primary')) : null,
                      ),
                    ),
                  ),
                );
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
  // TODO: Load account data from Bloc/Cubit
  String _name = 'Dora';
  String _type = 'bank';
  Color _color = Colors.green;

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
              items: [
                'bank', 'cash', 'credit', 'debit', 'savings', 'investment'
              ].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (v) => setState(() => _type = v!),
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
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Save changes via Bloc/Cubit
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account changes saved!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                // Do not pop the page
              },
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive Account'),
              onTap: () {
                // TODO: Show ArchiveAccountDialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Correct Total Balance'),
              onTap: () {
                // TODO: Show CorrectBalanceDialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: const Text('Transfer Balance'),
              onTap: () {
                // TODO: Show TransferBalanceDialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.merge_type),
              title: const Text('Merge Account'),
              onTap: () {
                // TODO: Show MergeAccountDialog
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