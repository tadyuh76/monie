import 'package:flutter/material.dart';
import 'package:monie/features/account/presentation/pages/add_account_page.dart';
import 'package:monie/features/account/presentation/pages/edit_accounts_page.dart';
import 'package:monie/features/home/domain/entities/account.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

import 'home_account_card.dart';

class AccountsSectionWidget extends StatefulWidget {
  final List<Account> accounts;
  final List<Transaction> transactions;

  const AccountsSectionWidget({
    super.key,
    required this.accounts,
    required this.transactions,
  });

  @override
  State<AccountsSectionWidget> createState() => _AccountsSectionWidgetState();
}

class _AccountsSectionWidgetState extends State<AccountsSectionWidget> {
  void _togglePin(int index) {
    setState(() {
      widget.accounts[index].pinned = !(widget.accounts[index].pinned);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Chỉ lấy các account được pin để hiển thị trên Home
    List<Account> pinnedAccounts =
        widget.accounts.where((acc) => acc.pinned == true).toList();
    return SizedBox(
      height: 150,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: pinnedAccounts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index < pinnedAccounts.length) {
            final acc = pinnedAccounts[index];
            final transactionsOfAcc =
                widget.transactions
                    .where((tran) => tran.accountId == acc.id)
                    .toList();
            return SizedBox(
              width: 180,
              child: HomeAccountCard(
                account: acc,
                transactions: transactionsOfAcc,
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, modalSetState) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Select Accounts',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (context) => EditAccountsPage(
                                                  accounts: widget.accounts,
                                                  transactions:
                                                      widget.transactions,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...widget.accounts.asMap().entries.map((entry) {
                                  int i = entry.key;
                                  Account acc = entry.value;
                                  return Dismissible(
                                    key: ValueKey(acc.id),
                                    background: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 24),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (_) {
                                      setState(() {
                                        widget.accounts.removeAt(i);
                                      });
                                    },
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: acc.getColor(),
                                        child: Icon(
                                          (acc.pinned)
                                              ? Icons.push_pin
                                              : Icons.account_balance_wallet,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(acc.name ?? ''),
                                      subtitle: Text(
                                        '${acc.type ?? 'Account'} • ${acc.balance ?? 0} ${acc.currency ?? ''}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              (acc.pinned)
                                                  ? Icons.push_pin
                                                  : Icons.push_pin_outlined,
                                              color:
                                                  (acc.pinned)
                                                      ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                      : Colors.grey,
                                            ),
                                            onPressed: () {
                                              _togglePin(i);
                                              modalSetState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                      onTap: () {},
                                    ),
                                  );
                                }),
                                const Divider(),
                                ListTile(
                                  leading: Icon(
                                    Icons.add,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  title: const Text('Add Account'),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                AddAccountPage(account: null),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
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
