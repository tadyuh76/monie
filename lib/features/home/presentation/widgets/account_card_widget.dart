import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/formatters.dart';
import 'package:monie/features/account/domain/entities/account.dart';
import 'package:monie/features/account/presentation/pages/detail_accounts_page.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

class AccountCardWidget extends StatefulWidget {
  final Account account;
  final List<Transaction> transactions;
  final VoidCallback? onPinToggle;
  final VoidCallback? onEdit;

  const AccountCardWidget({
    super.key,
    required this.account,
    required this.transactions,
    this.onPinToggle,
    this.onEdit,
  });

  @override
  State<AccountCardWidget> createState() => _AccountCardWidgetState();
}

class _AccountCardWidgetState extends State<AccountCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const double _pinnedBorderWidth = 2.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    if (widget.account.pinned) {
      _controller.value = 1.0; // Start fully pinned if initially pinned
    }
  }

  @override
  void didUpdateWidget(AccountCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.account.pinned != oldWidget.account.pinned) {
      if (widget.account.pinned) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Color borderColor = _getAccountColorFromString(widget.account.color);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return InkWell(
          onTap: () {
            if (widget.account.pinned) {
              // If the account is already pinned, navigate to details
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => DetailAccountsPage(
                        account: widget.account,
                        transactions: widget.transactions,
                      ),
                ),
              );
            } else if (widget.onPinToggle != null) {
              // If the account isn't pinned, toggle pin state
              widget.onPinToggle!();
            }
          },
          onLongPress: widget.onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 220,
            // Outer container for consistent size due to border
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                // Always have a border, make it transparent when not pinned
                color:
                    widget.account.pinned
                        ? borderColor.withValues(alpha: _controller.value)
                        : Colors.transparent,
                width: _pinnedBorderWidth, // Always use the pinned border width
              ),
              boxShadow:
                  !isDarkMode
                      ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ]
                      : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              // Inner container for content and visible border
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: child,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    // Added Expanded to prevent overflow
                    child: Text(
                      widget.account.name,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis, // Prevent overflow
                      style: textTheme.titleLarge?.copyWith(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), // Add some space
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getAccountColorFromString(widget.account.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                Formatters.formatCurrency(widget.account.balance),
                style: textTheme.headlineMedium?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.account.transactionCount} ${widget.account.transactionCount == 1 ? 'transaction' : 'transactions'}',
                style: textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppColors.textSecondary : Colors.black54,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper function to convert color string to Color object
Color _getAccountColorFromString(String? colorName) {
  switch (colorName?.toLowerCase()) {
    case 'red':
      return Colors.red;
    case 'pink':
      return Colors.pink;
    case 'purple':
      return Colors.purple;
    case 'deepPurple':
      return Colors.deepPurple;
    case 'indigo':
      return Colors.indigo;
    case 'blue':
      return Colors.blue;
    case 'lightBlue':
      return Colors.lightBlue;
    case 'cyan':
      return Colors.cyan;
    case 'teal':
      return Colors.teal;
    case 'green':
      return Colors.green;
    case 'lightGreen':
      return Colors.lightGreen;
    case 'lime':
      return Colors.lime;
    case 'yellow':
      return Colors.yellow;
    case 'amber':
      return Colors.amber;
    case 'orange':
      return Colors.orange;
    case 'deepOrange':
      return Colors.deepOrange;
    case 'brown':
      return Colors.brown;
    case 'grey':
      return Colors.grey;
    case 'blueGrey':
      return Colors.blueGrey;
    default:
      return AppColors.primary; // Default color if string doesn't match
  }
}
