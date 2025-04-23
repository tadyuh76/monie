import 'package:flutter/material.dart';
import 'package:monie/core/theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({super.key, this.size = 80, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isDarkMode
                    ? AppTheme.primarySwatch.shade800
                    : AppTheme.primarySwatch.shade50,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primarySwatch.withAlpha(40),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.account_balance_wallet,
              size: size * 0.6,
              color: AppTheme.primarySwatch.shade500,
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          Text(
            'Monie',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primarySwatch.shade500,
            ),
          ),
          Text(
            'Manage your finances with ease',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
