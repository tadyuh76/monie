import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/home/domain/entities/account.dart';

class AccountCardWidget extends StatelessWidget {
  final Account account;

  const AccountCardWidget({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Determine card color based on account type
    Color accountColor = AppColors.bank;
    if (account.type == 'cash') {
      accountColor = AppColors.cash;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                account.name ?? '',
                softWrap: true,
                style: textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: accountColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$${(account.balance ?? 0.0).abs().toStringAsFixed(0)}',
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${account.transactionCount} ${account.transactionCount == 1 ? 'transaction' : 'transactions'}',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
