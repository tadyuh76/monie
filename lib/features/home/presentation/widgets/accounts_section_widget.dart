import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/features/account/presentation/pages/account_form_modal.dart';
import 'package:monie/features/home/domain/entities/account.dart'
    as home_account;
import 'package:monie/features/transactions/domain/entities/account.dart'
    as transaction_account;
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/features/transactions/presentation/bloc/account_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/account_event.dart';

import 'account_card_widget.dart';

class AccountsSectionWidget extends StatefulWidget {
  final List<home_account.Account> accounts;
  final List<Transaction> transactions;
  final Function(home_account.Account)? onAccountPinToggle;

  const AccountsSectionWidget({
    super.key,
    required this.accounts,
    required this.transactions,
    this.onAccountPinToggle,
  });

  @override
  State<AccountsSectionWidget> createState() => _AccountsSectionWidgetState();
}

class _AccountsSectionWidgetState extends State<AccountsSectionWidget> {
  void _togglePin(home_account.Account account) {
    if (widget.onAccountPinToggle != null) {
      widget.onAccountPinToggle!(account);
      return;
    }

    if (!mounted) return;

    try {
      final accountBloc = context.read<AccountBloc>();

      // If we're toggling the pin state of an account
      if (!account.pinned) {
        // First, unpin any currently pinned accounts
        for (final acc in widget.accounts) {
          if (acc.pinned) {
            // Convert home account to transaction account
            final transactionAccount = transaction_account.Account(
              accountId: acc.accountId!,
              userId: acc.userId,
              name: acc.name,
              type: acc.type,
              balance: acc.balance,
              currency: acc.currency,
              color: acc.color,
              pinned: false, // unpin
              archived: acc.archived,
            );

            accountBloc.add(UpdateAccountEvent(transactionAccount));
          }
        }

        // Then pin the selected account
        final transactionAccount = transaction_account.Account(
          accountId: account.accountId!,
          userId: account.userId,
          name: account.name,
          type: account.type,
          balance: account.balance,
          currency: account.currency,
          color: account.color,
          pinned: true, // pin this account
          archived: account.archived,
        );

        accountBloc.add(UpdateAccountEvent(transactionAccount));
      }
      // If account is already pinned, we don't unpin it since we need one account pinned
    } catch (e) {
      // Bloc might be closed, ignore the error
      // Consider showing a snackbar or toast message if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort accounts alphabetically by name
    final sortedAccounts = List<home_account.Account>.from(widget.accounts);
    sortedAccounts.sort((a, b) => a.name.compareTo(b.name));

    return SizedBox(
      height: 150,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: sortedAccounts.length + 1, // +1 for add account button
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index < sortedAccounts.length) {
            final acc = sortedAccounts[index];
            final transactionsOfAcc =
                widget.transactions
                    .where((tran) => tran.accountId == acc.accountId)
                    .toList();

            return SizedBox(
              width: 160,
              child: AccountCardWidget(
                account: acc,
                transactions: transactionsOfAcc,
                onPinToggle: () => _togglePin(acc),
              ),
            );
          } else {
            // Add account button
            return SizedBox(
              width: 160,
              child: Card(
                child: InkWell(
                  onTap: () {
                    AccountFormModal.show(context);
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
