import 'package:flutter/material.dart';
import 'package:monie/features/account/presentation/pages/detail_accounts_page.dart';
import 'package:monie/features/home/domain/entities/account.dart';

import '../../../transactions/domain/entities/transaction.dart';

class HomeAccountCard extends StatelessWidget {
  Account account;
  List<Transaction> transactions;

  HomeAccountCard({
    super.key,
    required this.account,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => DetailAccountsPage(
                  account: account,
                  transactions: transactions,
                ),
          ),
        );
      },
      child: Ink(
        child: Container(
          padding: EdgeInsets.only(left: 10, top: 10, bottom: 10, right: 5),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 40),
                    child: Text(
                      account.name ?? '',
                      maxLines: 1,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (account.type != null)
                    Text(
                      account.type ?? '',
                      maxLines: 1,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '${account.balance}${account.currency}',
                    maxLines: 1,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    account.transactionCount.toString(),
                    maxLines: 1,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                top: 5,
                child: Row(
                  children: [
                    Container(
                      width: 15,
                      height: 15,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: account.getColor().withAlpha(99),
                        shape: BoxShape.circle,
                      ),
                    ),

                    Transform.translate(
                      offset: const Offset(-10, -4),
                      child: Container(
                        width: 13,
                        height: 13,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: account.getColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
