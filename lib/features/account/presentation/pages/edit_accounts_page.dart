import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'add_account_page.dart';

class EditAccountsPage extends StatefulWidget {
  const EditAccountsPage({super.key});

  @override
  State<EditAccountsPage> createState() => _EditAccountsPageState();
}

class _EditAccountsPageState extends State<EditAccountsPage> {
  List<Map<String, dynamic>> accounts = [
    {
      'id': '1',
      'name': 'Bank',
      'type': 'bank',
      'balance': 3200,
      'currency': 'USD',
      'archived': false,
      'color': Colors.blue,
    },
    {
      'id': '2',
      'name': 'Cash',
      'type': 'cash',
      'balance': 140,
      'currency': 'USD',
      'archived': false,
      'color': Colors.green,
    },
    {
      'id': '3',
      'name': 'Savings',
      'type': 'savings',
      'balance': 5000,
      'currency': 'USD',
      'archived': true,
      'color': Colors.orange,
    },
    {
      'id': '4',
      'name': 'Credit Card',
      'type': 'credit',
      'balance': 1200,
      'currency': 'USD',
      'archived': false,
      'color': Colors.red,
    },
  ];

  String? filterType;
  bool showArchived = false;

  Future<bool> _deleteAccount(int index) async {
    final name = accounts[index]['name'];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
        title: Text('Delete Account', style: TextStyle(color: AppColors.expense, fontSize: 26, fontWeight: FontWeight.bold)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text('Are you sure you want to delete "$name"?', style: const TextStyle(color: Colors.white, fontSize: 20)),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold, fontSize: 20)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        accounts.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account deleted successfully!'), backgroundColor: AppColors.primary),
      );
      return true;
    }
    return false;
  }

  void _archiveAccount(int index) async {
    final name = accounts[index]['name'];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Archive Account', style: TextStyle(color: Colors.orange)),
        content: Text('Archive "$name"?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        accounts[index]['archived'] = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account archived successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  void _unarchiveAccount(int index) {
    setState(() {
      accounts[index]['archived'] = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account unarchived successfully!'), backgroundColor: Colors.green),
    );
  }

  void _reconcileAccount(int index) async {
    final acc = accounts[index];
    final otherAccounts = accounts.where((a) => a['id'] != acc['id'] && a['archived'] != true).toList();
    String? selectedId;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        String? tempSelectedId = selectedId;
        return StatefulBuilder(
          builder: (context, setModalState) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text('Reconcile Account', style: TextStyle(color: Colors.blue)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select account to transfer balance:', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.black,
                  value: tempSelectedId,
                  items: otherAccounts.map<DropdownMenuItem<String>>((a) => DropdownMenuItem<String>(
                    value: a['id'] as String,
                    child: Text(a['name'], style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  onChanged: (v) {
                    setModalState(() {
                      tempSelectedId = v;
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(tempSelectedId),
                child: const Text('Reconcile', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        );
      },
    );
    if (confirm != null && confirm is String) {
      final destIndex = accounts.indexWhere((a) => a['id'] == confirm);
      setState(() {
        accounts[destIndex]['balance'] += acc['balance'];
        acc['balance'] = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reconciled successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  void _editAccount(int index) async {
    final acc = accounts[index];
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddAccountPage(
          account: acc,
          isEdit: true,
        ),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        accounts[index] = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account updated successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = accounts.removeAt(oldIndex);
      accounts.insert(newIndex, item);
    });
  }

  List<Map<String, dynamic>> get filteredAccounts {
    return accounts.where((acc) {
      if (!showArchived && acc['archived'] == true) return false;
      if (filterType != null && acc['type'] != filterType) return false;
      return true;
    }).toList();
  }

  void _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        String? tempType = filterType;
        bool tempShowArchived = showArchived;
        return StatefulBuilder(
          builder: (context, setModalState) => AlertDialog(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Colors.white, width: 2),
            ),
            title: Text('Filter Accounts', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  value: tempShowArchived,
                  onChanged: (v) {
                    setModalState(() => tempShowArchived = v ?? false);
                  },
                  title: Text('Show Archived', style: TextStyle(color: AppColors.primary)),
                  activeColor: AppColors.primary,
                  checkColor: Colors.white,
                ),
                DropdownButtonFormField<String>(
                  value: tempType,
                  dropdownColor: Colors.black,
                  decoration: InputDecoration(
                    labelText: 'Account Type',
                    labelStyle: TextStyle(color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Types', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'cash', child: Text('Cash', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'bank', child: Text('Bank', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'savings', child: Text('Savings', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'credit', child: Text('Credit', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'debit', child: Text('Debit', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'investment', child: Text('Investment', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (v) {
                    setModalState(() => tempType = v);
                  },
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    filterType = tempType;
                    showArchived = tempShowArchived;
                  });
                  Navigator.of(context).pop();
                },
                child: Text('Apply', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Edit Accounts', style: TextStyle(color: AppColors.primary)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: AppColors.primary),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: ReorderableListView.builder(
        itemCount: filteredAccounts.length,
        onReorder: _reorder,
        itemBuilder: (context, index) {
          final acc = filteredAccounts[index];
          return Dismissible(
            key: ValueKey(acc['id']),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _deleteAccount(index),
            child: Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white, width: 1.5),
              ),
              child: ListTile(
                leading: Icon(Icons.drag_handle, color: AppColors.primary),
                title: Text(acc['name'], style: const TextStyle(color: Colors.white)),
                subtitle: Text('${acc['type']} • ${acc['balance']} ${acc['currency']} • ${acc['transactionCount'] ?? 0} transactions', style: const TextStyle(color: Colors.white70)),
                trailing: PopupMenuButton<String>(
                  color: Colors.grey[900],
                  icon: Icon(Icons.more_vert, color: AppColors.primary),
                  onSelected: (value) {
                    if (value == 'edit') _editAccount(index);
                    if (value == 'archive') _archiveAccount(index);
                    if (value == 'unarchive') _unarchiveAccount(index);
                    if (value == 'reconcile') _reconcileAccount(index);
                    if (value == 'delete') _deleteAccount(index);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                    if (!acc['archived'])
                      const PopupMenuItem(value: 'archive', child: Text('Archive', style: TextStyle(color: Colors.white))),
                    if (acc['archived'])
                      const PopupMenuItem(value: 'unarchive', child: Text('Unarchive', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'reconcile', child: Text('Reconcile', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.white))),
                  ],
                ),
                onTap: () => _editAccount(index),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddAccountPage(),
            ),
          );
          if (result != null && result is Map<String, dynamic>) {
            setState(() {
              accounts.add(result);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account added successfully!'), backgroundColor: Colors.green),
            );
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
} 