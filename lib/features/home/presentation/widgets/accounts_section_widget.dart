import 'package:flutter/material.dart';
import 'package:monie/features/home/domain/entities/account.dart';
import 'package:monie/features/home/presentation/widgets/account_card_widget.dart';
import 'package:monie/features/account/presentation/pages/edit_accounts_page.dart';

class AccountsSectionWidget extends StatefulWidget {
  final List<Account> accounts;

  const AccountsSectionWidget({super.key, required this.accounts});

  @override
  State<AccountsSectionWidget> createState() => _AccountsSectionWidgetState();
}

class _AccountsSectionWidgetState extends State<AccountsSectionWidget> {
  // Mock state for pin/unpin (id, name, pinned)
  List<Map<String, dynamic>> mockAccounts = [
    {'id': '1', 'name': 'Bank', 'pinned': true},
    {'id': '2', 'name': 'Cash', 'pinned': true},
    {'id': '3', 'name': 'Investment', 'pinned': false},
  ];

  void _togglePin(int index) {
    setState(() {
      mockAccounts[index]['pinned'] = !(mockAccounts[index]['pinned'] as bool);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ lấy các account được pin để hiển thị trên Home
    final pinnedAccounts = mockAccounts.where((acc) => acc['pinned'] as bool).toList();
    return SizedBox(
      height: 132,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: pinnedAccounts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index < pinnedAccounts.length) {
            final acc = pinnedAccounts[index];
            return SizedBox(
              width: 180,
              child: Card(
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text(acc['name'] as String)),
              ),
            );
          } else {
          return SizedBox(
            width: 180,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Select Accounts',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const EditAccountsPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...mockAccounts.asMap().entries.map((entry) {
                              final i = entry.key;
                              final acc = entry.value;
                              return Dismissible(
                                key: ValueKey(acc['id']),
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) {
                                  setState(() {
                                    mockAccounts.removeAt(i);
                                  });
                                },
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: acc['color'] ?? Theme.of(context).colorScheme.primary,
                                    child: Icon(
                                      (acc['pinned'] as bool) ? Icons.push_pin : Icons.account_balance_wallet,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(acc['name'] as String? ?? ''),
                                  subtitle: Text('${acc['type'] ?? 'Account'} • ${acc['balance'] ?? 0} ${acc['currency'] ?? ''}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          (acc['pinned'] as bool) ? Icons.push_pin : Icons.push_pin_outlined,
                                          color: (acc['pinned'] as bool) ? Theme.of(context).colorScheme.primary : Colors.grey,
                                        ),
                                        onPressed: () => _togglePin(i),
                                      ),
                                    ],
                                  ),
                                  onTap: () {},
                                ),
                              );
                            }),
                            const Divider(),
                            ListTile(
                              leading: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                              title: const Text('Add Account'),
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).pushNamed('/add_account');
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
