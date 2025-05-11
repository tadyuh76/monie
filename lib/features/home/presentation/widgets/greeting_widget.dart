import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';

class GreetingWidget extends StatelessWidget {
  final String name;

  const GreetingWidget({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi there',
          style: textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          name,
          style: textTheme.headlineLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
