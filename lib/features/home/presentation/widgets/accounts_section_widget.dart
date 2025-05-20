import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/features/account/presentation/bloc/account_bloc.dart';
import 'package:monie/features/account/presentation/pages/add_account_page.dart';
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
  void _togglePin(Account account) {
    if (account.accountId != null) {
      context.read<AccountBloc>().add(
        UpdateAccountEvent(account: account.copyWith(pinned: !account.pinned)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show pinned accounts on Home
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
                    .where((tran) => tran.accountId == acc.accountId)
                    .toList();
            return SizedBox(
              width: 180,
              child: GestureDetector(
                onTap: () => _togglePin(acc),
                child: HomeAccountCard(
                  account: acc,
                  transactions: transactionsOfAcc,
                ),
              ),
            );
          } else {
            // Add account button
            return SizedBox(
              width: 180,
              child: Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddAccountPage(),
                      ),
                    );
                  },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, size: 48),
                      SizedBox(height: 8),
                      Text('Add Account'),
                    ],
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
