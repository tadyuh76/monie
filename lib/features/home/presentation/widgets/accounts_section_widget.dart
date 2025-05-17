import 'package:flutter/material.dart';
import 'package:monie/features/home/domain/entities/account.dart';
import 'package:monie/features/home/presentation/widgets/account_card_widget.dart';

class AccountsSectionWidget extends StatelessWidget {
  final List<Account> accounts;
  final VoidCallback? onAddAccount;

  const AccountsSectionWidget({super.key, required this.accounts, this.onAddAccount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length + 1, // +1 for Add Account card
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index < accounts.length) {
            final account = accounts[index];
            return SizedBox(
              width: 180,
              child: AccountCardWidget(account: account),
            );
          } else {
            // Add Account card
            return SizedBox(
              width: 180,
              child: GestureDetector(
                onTap: onAddAccount,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: Center(
                    child: Icon(Icons.add, size: 36, color: Colors.white70),
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
