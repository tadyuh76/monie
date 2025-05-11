import 'package:flutter/material.dart';
import 'package:monie/features/home/domain/entities/account.dart';
import 'package:monie/features/home/presentation/widgets/account_card_widget.dart';

class AccountsSectionWidget extends StatelessWidget {
  final List<Account> accounts;

  const AccountsSectionWidget({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final account = accounts[index];
          return SizedBox(
            width: 180,
            child: AccountCardWidget(account: account),
          );
        },
      ),
    );
  }
}
