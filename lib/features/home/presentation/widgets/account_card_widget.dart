import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/home/domain/entities/account.dart';

class AccountCardWidget extends StatelessWidget {
  final Account account;

  const AccountCardWidget({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determine card color based on account type
    Color accountColor = AppColors.bank;
    if (account.type == 'cash') {
      accountColor = AppColors.cash;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: !isDarkMode ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                account.name,
                style: textTheme.titleLarge?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87
                ),
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
            '\$${account.balance.abs().toStringAsFixed(0)}',
            style: textTheme.headlineMedium?.copyWith(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${account.transactionCount} ${account.transactionCount == 1 ? 'transaction' : 'transactions'}',
            style: textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? AppColors.textSecondary : Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
