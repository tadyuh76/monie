import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monie/features/account/domain/entities/account.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

class ItemTransactionCard extends StatelessWidget {
  final Transaction transaction;
  final Account account;

  const ItemTransactionCard({
    super.key,
    required this.transaction,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
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
                      transaction.title,
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
                  Text(
                    formatDate(transaction.date),
                    maxLines: 1,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[300], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${transaction.amount}${account.currency}',
                    maxLines: 1,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy hh:mm').format(date);
}
