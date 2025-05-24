import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';

class SmartBudgetWidget extends StatelessWidget {
  const SmartBudgetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isDarkMode
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDarkMode
                  ? [const Color(0xFF1F3B4D), const Color(0xFF102A3A)]
                  : [const Color(0xFFE6F7EC), const Color(0xFFD1F2E1)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? const Color(0xFF2C4E63)
                          : const Color(0xFFB3E5C9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.lightbulb,
                  color: isDarkMode ? Colors.greenAccent : Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Smart Budget Recommendations',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildOptimizationCard(
            context,
            title: 'Optimize Your Budget',
            description:
                'Our AI has analyzed your spending patterns and suggests these budget adjustments:',
          ),
          const SizedBox(height: 16),
          _buildRecommendationList(context),
          const SizedBox(height: 20),
          _buildSavingsImpact(context),
          const SizedBox(height: 20),
          _buildApplyButton(context),
        ],
      ),
    );
  }

  Widget _buildOptimizationCard(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationList(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    // Hardcoded budget recommendations
    final recommendations = [
      {
        'category': 'Food & Dining',
        'currentBudget': '\$500',
        'suggestedBudget': '\$450',
        'change': '-\$50',
        'isDecrease': true,
      },
      {
        'category': 'Entertainment',
        'currentBudget': '\$200',
        'suggestedBudget': '\$150',
        'change': '-\$50',
        'isDecrease': true,
      },
      {
        'category': 'Savings',
        'currentBudget': '\$300',
        'suggestedBudget': '\$400',
        'change': '+\$100',
        'isDecrease': false,
      },
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Category',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Current',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Suggested',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Change',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        ...recommendations.map((rec) => _buildRecommendationItem(context, rec)),
      ],
    );
  }

  Widget _buildRecommendationItem(
    BuildContext context,
    Map<String, dynamic> recommendation,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final isDecrease = recommendation['isDecrease'] as bool;
    final color =
        isDecrease
            ? (isDarkMode ? Colors.redAccent : Colors.red)
            : (isDarkMode ? Colors.greenAccent : Colors.green);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              recommendation['category'],
              style: textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              recommendation['currentBudget'],
              style: textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              recommendation['suggestedBudget'],
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              recommendation['change'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsImpact(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? const Color(0xFF2C4E63).withValues(alpha: 0.5)
                : const Color(0xFFB3E5C9).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? Colors.greenAccent.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.trending_up,
              color: isDarkMode ? Colors.greenAccent : Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Projected Impact',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Following these recommendations could increase your savings by \$1,200 annually.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? const Color(0xFF2C4E63) : Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 18,
              color: isDarkMode ? Colors.greenAccent : Colors.white,
            ),
            const SizedBox(width: 8),
            const Text('Apply Recommendations'),
          ],
        ),
      ),
    );
  }
}
